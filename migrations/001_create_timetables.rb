Sequel.migration do
  up do
    create_table(:timetables) do
      primary_key :id
      String :name, :null => false
      Boolean :inbound, :null => false
    end
  end

  down do
    drop_table :timetables
  end
end
