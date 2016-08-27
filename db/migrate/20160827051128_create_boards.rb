class CreateBoards < ActiveRecord::Migration
  def change
    create_table :boards do |t|
      t.string   :name
      t.string   :screen_name
      t.timestamps null: false
    end
  end
end
