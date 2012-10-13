Sequel.migration do
  up do
    create_table(:timetable_stations) do
      primary_key :id
      foreign_key :timetable_id, :timetables, :null => false
      foreign_key :station_id, :stations, :null => false
      Integer :position, :null => false
      String :annotation
    end
  end

  down do
    drop_table :timetable_stations
  end
end
