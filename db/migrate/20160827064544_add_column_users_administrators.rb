class AddColumnUsersAdministrators < ActiveRecord::Migration
  def change
    add_column :users, :administrator, :boolean, null: false, default: false
    add_column :users, :mail, :string
    add_column :users, :password_digest, :string
    add_column :users, :token, :string
  end
end
