class CreateBoards < ActiveRecord::Migration
  def change
    create_table :boards do |t|
      t.integer  :user_id
      t.integer  :stamp_id
      t.string   :name
      t.string   :screen_name
      t.timestamps null: false
    end
  end
end
