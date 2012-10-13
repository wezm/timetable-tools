Sequel.migration do
  up do
    create_table(:stops) do
      primary_key :id
      foreign_key :service_id, :services, :null => false
      foreign_key :timetable_station_id, :timetable_stations, :null => false
      Time :time, :null => false
      column :flag, :char
    end
  end

  down do
    drop_table :stops
  end
end
