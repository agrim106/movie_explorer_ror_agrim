ActiveAdmin.register User do
  permit_params :first_name, :last_name, :email, :password, :mobile_number, :role

  index do
    selectable_column
    id_column
    column :first_name
    column :last_name
    column :email
    column :mobile_number
    column :role
    column :created_at
    actions
  end

  filter :email
  filter :mobile_number
  filter :role
  filter :created_at

  form do |f|
    f.inputs do
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :password
      f.input :mobile_number
      f.input :role, as: :select, collection: User.roles.keys - ['admin'] # Exclude 'admin' from dropdown
    end
    f.actions
  end
end