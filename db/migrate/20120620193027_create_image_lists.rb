class CreateImageLists < ActiveRecord::Migration
  def change
    create_table :image_lists do |t|

      t.timestamps
    end
  end
end
