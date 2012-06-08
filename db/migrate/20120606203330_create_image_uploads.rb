class CreateImageUploads < ActiveRecord::Migration
  def change
    create_table :image_uploads do |t|

      t.timestamps
    end
  end
end
