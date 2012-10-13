Sequel.migration do
  up do
    create_table(:services) do
      primary_key :id
      foreign_key :timetable_id, :timetables, :null => false
      String :number, :null => false
      String :vehicle, :null => false
      Boolean :has_first_class, :null => false
      Boolean :has_catering, :null => false
      Boolean :requires_reservation, :null => false
      Boolean :peak, :null => false
      Integer :days, :null => false
    end
  end

  down do
    drop_table :services
  end
end
