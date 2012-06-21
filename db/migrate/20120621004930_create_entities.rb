class CreateEntities < ActiveRecord::Migration
  def change
    create_table :entities do |t|

      t.timestamps
    end
  end
end
