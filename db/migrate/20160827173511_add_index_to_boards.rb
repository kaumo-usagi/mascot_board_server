class AddIndexToBoards < ActiveRecord::Migration
  def change
    add_index :boards, :name
  end
end
