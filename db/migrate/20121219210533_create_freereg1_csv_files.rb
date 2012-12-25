class CreateFreereg1CsvFiles < ActiveRecord::Migration
  def change
    create_table :freereg1_csv_files do |t|
      t.string :dir_name
      t.string :file_name
      t.string :transcriber_email
      t.string :transcriber_name
      t.string :transcriber_syndicate
      t.string :transcription_date
      t.string :record_type
      t.string :credit_name
      t.string :credit_email
      t.string :first_comment
      t.string :second_comment

      t.timestamps
    end
  end
end
