Sequel.migration do
  up do
    create_table(:stations) do
      primary_key :id
      String :name, :null => false
      Float :latitude
      Float :longitude
      String :address
      String :city
      String :postcode
      String :phone
    end
  end

  down do
    drop_table :stations
  end
end
