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
        timetable.add_service(
          :days => encode_days(enum.next),
          :number => enum.next,
          :vehicle => enum.next,
          :has_first_class => enum.next == 'Y',
          :has_catering => enum.next == 'Y',
          :requires_reservation => enum.next == 'Y',
          :peak => enum.next == 'Y'
        )

        # Import the stops on the service
        create_stops! enum
      end
    end

    def encode_days(days_string)
      0
    end

    def create_stops!(stops)
      position = 0

    end

  end

end
