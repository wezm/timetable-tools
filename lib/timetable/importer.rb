require 'timetable/models'
require 'set'

module Timetable

  class Importer

    class RowReader

      attr_reader :row

      def initialize(enum)
        @enum = enum
        reset_row!
      end

      def next
        @row += 1
        @enum.next
      end

      def peek
        @enum.peek
      end

      def reset_row!
        @row = -1
      end

    end

    NEW_SERVICE_MARKER='-'

    attr_reader :timetable

    def import(data)
      @timetable = create_timetable! data[1] # data[0] is the source URL
      create_stations! data[9..-1].map(&:first)

      service_data = data[2..-1].map do |row|
        row[1..-1]
      end.transpose
      create_services! service_data
    end

  protected

    def create_timetable!(row)
      name = "#{row[0]} to #{row[1]}"
      inbound = row[1] == 'Melbourne'
      Timetable.create :name => name, :inbound => inbound
    end

    def create_stations!(stations)
      annotations = %w[arr dep].to_set
      skip_rows = [NEW_SERVICE_MARKER, 'Service No.', 'Train/Coach'].to_set

      stations.each_with_index do |station_name, position|
        next if skip_rows.include?(station_name)

        # Create the station if necessary
        station_parts = station_name.split
        annotation = station_parts.pop if annotations.include?(station_parts.last)
        station = Station.find_or_create(:name => station_parts.join(' '))

        # Create the TimetableStation
        # puts "Add TimetableStation with position #{position}"
        timetable.add_timetable_station(
          :station_id => station.id,
          :position => position,
          :annotation => annotation
        )

      end
    end

    def create_services!(services)
      services.each do |service_data|
        # Create the service
        enum = RowReader.new(service_data.each)
        service = timetable.add_service(
          :days => encode_days(enum.next),
          :number => enum.next,
          :vehicle => enum.next,
          :has_first_class => enum.next == 'Y',
          :has_catering => enum.next == 'Y',
          :requires_reservation => enum.next == 'Y',
          :peak => enum.next == 'Y'
        )

        puts "Importing service #{service.number}"

        # Import the stops on the service
        enum.reset_row!
        create_stops_on_service! service, enum
      end
    end

    # The days value is a bitmask with Mon = bit 0, Tue bit 1, etc.
    def encode_days(days_string)
      days = %w[MON TUE WED THU FRI SAT SUN]
      if days_string.include?('-') # Day range
        start_day, end_day = days_string.upcase.split('-')
        days.index(start_day)..days.index(end_day)
      elsif days_string.include?(',') # Day set
        days_string.upcase.split(',').map do |day|
          days.index day
        end
      else
        [days.index(days_string.upcase)] # Single day
      end.inject(0) do |memo, day|
        memo | (1 << day)
      end
    end

    def create_stops_on_service!(service, stops)
      while true
        begin
          stop_time = stops.next
          next if stop_time.nil?

          if stop_time == NEW_SERVICE_MARKER
            if should_start_new_service?(stops.peek)
              create_subordinate_service!(service, stops)
              return
            else
              # Skip the next two cells
              stop_time.next
              stop_time.next
              next
            end
          end


          # Find the timetable station for this position
          timetable_station = TimetableStation.find(
            :timetable => timetable,
            :position  => stops.row
          )
          raise "Unable to find station at position #{stops.row}" if timetable_station.nil?

          if stop_time =~ /^(..:..)([^0-9])?$/
            time = $1
            flag = $2
          else
            puts "Warning: #{stop_time} doesn't match expected time format"
          end

          service.add_stop(
            :timetable_station => timetable_station,
            :time => time,
            :flag => flag
          )

        rescue StopIteration
          return
        end
      end
    end

    def should_start_new_service?(value)
      !value.nil?
    end

    def create_subordinate_service!(parent_service, stops)
      # Create the new service, with properties from the parent
      service = Service.create(
        :number               => stops.next,
        :vehicle              => stops.next,
        :timetable            => parent_service.timetable,
        :days                 => parent_service.days,
        :has_first_class      => parent_service.has_first_class,
        :has_catering         => parent_service.has_catering,
        :requires_reservation => parent_service.requires_reservation,
        :peak                 => parent_service.peak,
        :parent_service       => parent_service
      )

      puts "Importing subordinate service #{service.number}"

      # Import the stops on the service
      create_stops_on_service! service, stops
    end

  end
end
