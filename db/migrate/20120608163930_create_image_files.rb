class CreateImageFiles < ActiveRecord::Migration
  def change
    create_table :image_files do |t|

      t.timestamps
    end
  end
end
