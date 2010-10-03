require 'sqlite3'
require 'timetable/partitioner'

class StationStorer

  def initialize(db_path)
    @db = SQLite3::Database.new(db_path)
  end
  attr_reader :db
  attr_accessor :direction

  def reset!
    @services = {}
    @days = []
    @day_partitioner = Timetable::Partitioner.new
    # this deliberately doesn't reset the direction
  end

  def add_service(index, service)
    puts "add service: #{index} => #{service} (#{direction})"

    @insert_service ||= db.prepare "INSERT INTO services (number, inbound) VALUES (?,?)"
    @insert_service.execute(service, direction == 'in' ? 1 : 0)
    service_id = db.last_insert_row_id

    @insert_service_day ||= db.prepare "INSERT INTO service_days (service_id, day) VALUES (?,?)"
    @days[@day_partitioner.place(index) - 1].each do |day|
      @insert_service_day.execute(service_id, day)
    end

    @services[index] = service_id
  end

  def service_indexes
    @services.keys
  end

  def add_stop(station, details)
    station_id = id_of_station(station)
    if station_id.nil?
      station_id = add_station(station)
    end

    puts "add stop: #{station_id}, #{@services[details[:service]]}, #{details[:time]}"
    # The OR REPLACE clause handles the multiple entries for differing arrival and departure
    @insert_stop ||= db.prepare "INSERT OR REPLACE INTO stops (station_id, service_id, time) VALUES (?, ?, ?)"
    @insert_stop.execute(station_id, @services[details[:service]], details[:time])
  end

  def add_days(index, days)
    puts "add days: #{index} => #{days.inspect}"
    @days << days
    @day_partitioner.boundaries << index - 1
  end

  def create_or_clear_tables!
    db.execute_batch <<-SQL
      CREATE TABLE IF NOT EXISTS stations (
        id integer NOT NULL PRIMARY KEY,
        name varchar(255) UNIQUE NOT NULL
      );

      CREATE TABLE IF NOT EXISTS services (
        id integer NOT NULL PRIMARY KEY,
        number integer NOT NULL,
        inbound boolean NOT NULL
      );

      CREATE TABLE IF NOT EXISTS service_days (
        service_id integer NOT NULL,
        day integer NOT NULL,
        PRIMARY KEY(service_id, day)
      );

      CREATE TABLE IF NOT EXISTS stops (
        station_id integer NOT NULL,
        service_id integer NOT NULL,
        time character(5),
        PRIMARY KEY(station_id, service_id)
      );

      DELETE FROM stations;
      DELETE FROM services;
      DELETE FROM service_days;
      DELETE FROM stops;
    SQL
  end

protected

  def id_of_station(station)
    db.get_first_value("SELECT id FROM stations WHERE name = ?", station)
  end

  

  def add_station(station)
    puts "add station: #{station}"
    @insert_station ||= db.prepare "INSERT INTO stations (name) VALUES (?)"
    @insert_station.execute(station)
    id_of_station(station)
  end

end