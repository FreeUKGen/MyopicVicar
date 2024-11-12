class CreateUniqueForename < ActiveRecord::Migration[5.1]
  def change
    create_table :unique_forenames do |t|
      t.string "Name", limit: 100
      t.integer "count"
    end
  end
end
