class CreatePutTexts < ActiveRecord::Migration
  def change
    create_table :put_texts do |t|
      t.integer :board_id
      t.integer :stamp_id
      t.string :x
      t.string :y
    end
  end
end
