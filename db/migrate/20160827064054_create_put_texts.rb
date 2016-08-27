class CreatePutTexts < ActiveRecord::Migration
  def change
    create_table :put_texts do |t|
      t.integer :board_id
      t.integer :text_id
      t.integer :body
      t.string :x
      t.string :y
    end
  end
end
