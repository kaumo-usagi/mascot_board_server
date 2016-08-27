class AddIndexToBoards < ActiveRecord::Migration
  def change
    add_index :boards, :user_id
    add_index :boards, :stamp_id
  end
end
