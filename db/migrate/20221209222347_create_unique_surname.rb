class CreateUniqueSurname < ActiveRecord::Migration[5.1]
  def change
    create_table :unique_surnames do |t|
      t.string "Name", limit: 100
      t.integer "count"
    end
  end
end
