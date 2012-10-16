module Timetable

  class Timetable < Sequel::Model
    one_to_many :timetable_stations
    one_to_many :services
  end

  class Station < Sequel::Model
    one_to_many :timetable_stations
  end

  class TimetableStation < Sequel::Model
    many_to_one :timetable
    many_to_one :station
    one_to_many :stops
  end

  class Stop < Sequel::Model
    many_to_one :service
    many_to_one :timetable_station
  end

  class Service < Sequel::Model
    many_to_one :timetable
    one_to_many :stops
    many_to_one :parent_service, :class => self
    one_to_one :subordinate_service, :key => :parent_service_id, :class => self
  end

end
