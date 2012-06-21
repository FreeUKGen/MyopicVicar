class CreateAssetCollections < ActiveRecord::Migration
  def change
    create_table :asset_collections do |t|

      t.timestamps
    end
  end
end
