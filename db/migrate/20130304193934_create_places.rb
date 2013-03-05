class CreatePlaces < ActiveRecord::Migration
  def change
    create_table :places do |t|
      t.string :chapman_code
      t.string :place_name
      t.string :church_name
      t.string :genuki_url

      t.timestamps
    end
  end
end
