class AddIndexToUsers < ActiveRecord::Migration
  def change
    add_index :users, :board_id
  end
end
