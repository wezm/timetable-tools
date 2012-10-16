Sequel.migration do
  up do
    add_column :services, :parent_service_id, :integer
  end

  down do
    drop_column :services, :parent_service_id
  end
end
