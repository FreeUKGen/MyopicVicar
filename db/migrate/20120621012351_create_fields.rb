class CreateFields < ActiveRecord::Migration
  def change
    create_table :fields do |t|

      t.timestamps
    end
  end
end
