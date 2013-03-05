class CreateChurches < ActiveRecord::Migration
  def change
    create_table :churches do |t|
      t.string :church_name

      t.timestamps
    end
  end
end
