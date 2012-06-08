class CreateImageUploadLogs < ActiveRecord::Migration
  def change
    create_table :image_upload_logs do |t|

      t.timestamps
    end
  end
end
