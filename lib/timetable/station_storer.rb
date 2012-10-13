require 'sqlite3'
require 'json'
require 'cgi'
require 'net/http'

require 'timetable/partitioner'

class StationStorer

  def initialize(db_path, line)
    @db = SQLite3::Database.new(db_path)
    @line = line
  end
  attr_reader :db, :line
  attr_accessor :direction

  def reset!
    @services = {}
    @days = []
    @day_partitioner = Timetable::Partitioner.new
    # this deliberately doesn't reset the direction
  end

  def add_service(index, service)
    puts "add service: #{index} => #{service} (#{direction})"

    @insert_service ||= db.prepare "INSERT INTO services (line_id, number, inbound) VALUES (?,?,?)"
    @insert_service.execute(id_of_line, service, direction == 'in' ? 1 : 0)
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
    station_id = find_or_create_station(station)

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

protected

  def find_or_create_station(station)
    station_id = id_of_station(station)

    if station_id.nil?
      # Create the station
      station_id = add_station(station)
    end

    # Ensure the station is associated with the line
    ensure_station_is_associated_with_line(station_id)

    station_id
  end

  def id_of_station(station)
    db.get_first_value("SELECT id FROM stations WHERE name = ?", station)
  end

  def id_of_line
    @id_of_line ||= db.get_first_value("SELECT id FROM lines WHERE name = ?", @line)
    if @id_of_line.nil?
      puts "add line: #{@line}"
      insert_line = db.prepare "INSERT INTO lines (name) VALUES (?)"
      insert_line.execute @line
      @id_of_line = db.last_insert_row_id
      # insert_line.finish
    end
    @id_of_line
  end

  def station_is_associated_with_line?(station_id)
    line_station_id = db.get_first_value(
      "SELECT line_id FROM line_stations WHERE line_id = ? AND station_id = ?", id_of_line, station_id
    )
    !line_station_id.nil?
  end

  def ensure_station_is_associated_with_line(station_id)
    unless station_is_associated_with_line?(station_id)
      insert_line_station = db.prepare "INSERT INTO line_stations (line_id, station_id) VALUES (?,?)"
      insert_line_station.execute id_of_line, station_id
    end
  end

  def geocode_station(station)
    address = "#{station} Station, VIC, Australia"
    response = Net::HTTP.get_response(
      URI.parse("http://maps.googleapis.com/maps/api/geocode/json?address=#{CGI.escape(address)}&sensor=false&region=au")
    )
    data = JSON.parse(response.body)

    lat, lng, address = nil
    if data["status"] == "OK"
      result = data["results"].first
      lat = result["geometry"]["location"]["lat"]
      lng = result["geometry"]["location"]["lng"]
      address = result["formatted_address"]
    end

    return [lat, lng, address]
  end

  def add_station(station)
    puts "add station: #{station}"
    @insert_station ||= db.prepare "INSERT INTO stations (name) VALUES (?)"
    @insert_station.execute(station)
    db.last_insert_row_id # Return the id of the inserted station
  end

public

  def create_or_clear_tables!
    db.execute_batch <<-SQL
      CREATE TABLE IF NOT EXISTS lines (
        id integer NOT NULL PRIMARY KEY,
        name varchar(255) UNIQUE NOT NULL
      );

      CREATE TABLE IF NOT EXISTS stations (
        id integer NOT NULL PRIMARY KEY,
        name varchar(255) UNIQUE NOT NULL,
        latitude double,
        longitude double,
        address varchar(255),
        city varchar(255),
        postcode varchar(255),
        phone varchar(12)
      );

      CREATE TABLE IF NOT EXISTS line_stations (
        line_id integer NOT NULL,
        station_id integer NOT NULL,
        PRIMARY KEY(line_id, station_id)
      );

      CREATE TABLE IF NOT EXISTS services (
        id integer NOT NULL PRIMARY KEY,
        line_id integer NOT NULL,
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

      DELETE FROM service_days;
      DELETE FROM stops;
      DELETE FROM services;
      DELETE FROM line_stations;
      DELETE FROM stations;
      DELETE FROM lines;

      CREATE INDEX IF NOT EXISTS idx_line_name ON lines (name);
      CREATE INDEX IF NOT EXISTS idx_station_name on stations (name);
      CREATE INDEX IF NOT EXISTS idx_service_line_id on services (line_id);
    SQL
  end

end
