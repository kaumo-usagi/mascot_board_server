class AddIndexToPutTexts < ActiveRecord::Migration
  def change
    add_index :put_texts, :board_id
    add_index :put_texts, :text_id
  end
end
