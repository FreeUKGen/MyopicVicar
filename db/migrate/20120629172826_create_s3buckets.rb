class CreateS3buckets < ActiveRecord::Migration
  def change
    create_table :s3buckets do |t|
      t.string :name

      t.timestamps
    end
  end
end
