class CreateImageDirs < ActiveRecord::Migration
  def change
    create_table :image_dirs do |t|

      t.timestamps
    end
  end
end
