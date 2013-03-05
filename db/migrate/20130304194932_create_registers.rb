class CreateRegisters < ActiveRecord::Migration
  def change
    create_table :registers do |t|
      t.string :start_year
      t.string :end_year
      t.string :register_type
      t.string :status
 
      t.timestamps
    end
  end
end
