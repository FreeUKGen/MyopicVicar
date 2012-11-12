class CreateSearchNames < ActiveRecord::Migration
  def change
    create_table :search_names do |t|
      t.string :first_name
      t.string :last_name
      t.string :role
      t.string :origin

      t.timestamps
    end
  end
end
