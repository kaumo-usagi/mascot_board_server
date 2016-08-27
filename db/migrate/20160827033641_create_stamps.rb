class CreateStamps < ActiveRecord::Migration
  def change
    create_table :stamps do |t|
      t.string :string
      t.text   :data
      t.string :url
      t.timestamps null: false
    end
  end
end
