class CreateEmendors < ActiveRecord::Migration
  def change
    create_table :emendors do |t|

      t.timestamps
    end
  end
end
