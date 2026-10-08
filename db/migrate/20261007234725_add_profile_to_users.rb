class AddProfileToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :preferred_name, :string
    add_column :users, :date_of_birth, :date
    add_column :users, :crisis_contact_name, :string
    add_column :users, :crisis_contact_phone, :string
  end
end
