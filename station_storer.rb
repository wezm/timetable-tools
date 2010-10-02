require 'sqlite3'

class StationStorer
  
  def initialize(db_path)
    @db = SQLite3::Database.new(db_path)
    @services = {}

    create_and_clear_tables
  end
  attr_reader :db

  def add_service(index, service)
    puts "add service: #{index} => #{service}"
    @services[index] = service
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
    @insert_stop ||= db.prepare "INSERT OR REPLACE INTO stops VALUES (?, ?, ?)"
    @insert_stop.execute(station_id, @services[details[:service]], details[:time])
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

  def create_and_clear_tables
    db.execute_batch <<-SQL
      CREATE TABLE IF NOT EXISTS stations (
        id integer NOT NULL PRIMARY KEY,
        name varchar(255) UNIQUE NOT NULL
      );
    
      CREATE TABLE IF NOT EXISTS stops (
        station_id integer NOT NULL,
        service integer NOT NULL,
        time character(5),
        PRIMARY KEY(station_id, service)
      );
      
      DELETE FROM stations;
      DELETE FROM stops;
    SQL
  end

end