class AddIndexToPutStamps < ActiveRecord::Migration
  def change
    add_index :put_stamps, :board_id
    add_index :put_stamps, :stamp_id
  end
end
