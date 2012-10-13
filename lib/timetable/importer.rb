require 'timetable/models'

module Timetable

  class Importer

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
      annotations = %w[arr dep]

      stations.each_with_index do |station_name, position|
        # Create the station if necessary
        station_parts = station_name.split
        annotation = station_parts.pop if annotations.include?(station_parts.last)
        station = Station.find_or_create(:name => station_parts.join(' '))

        # Create the TimetableStation
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
        enum = service_data.each
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
      position = 0

      while true
        begin
          # Find the timetable station for this position
          timetable_station = TimetableStation.find(
            :timetable => timetable,
            :position  => position
          )

          stop_time = stops.next
          if !stop_time.nil?
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
          end

          position += 1
        rescue StopIteration
          return
        end
      end
    end

  end

end
