class ChangeTextsColumns < ActiveRecord::Migration
  def change
    remove_column :put_texts, :text_id
    remove_column :put_texts, :body
    add_column :put_texts, :body, :text
  end
end
