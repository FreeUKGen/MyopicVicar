class CreateSearchRecords < ActiveRecord::Migration
  def change
    create_table :search_records do |t|

      t.timestamps
    end
  end
end
