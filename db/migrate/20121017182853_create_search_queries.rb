class CreateSearchQueries < ActiveRecord::Migration
  def change
    create_table :search_queries do |t|

      t.timestamps
    end
  end
end
