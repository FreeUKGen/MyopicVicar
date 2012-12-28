class CreateToponyms < ActiveRecord::Migration
  def change
    create_table :toponyms do |t|
      t.string :chapman_code
      t.string :parish
      t.string :geonames_response
      t.string :gbhgis_response
      t.boolean :resolved

      t.timestamps
    end
  end
end
