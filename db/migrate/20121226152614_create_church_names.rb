class CreateChurchNames < ActiveRecord::Migration
  def change
    create_table :church_names do |t|
      t.string :chapman_code
      t.string :parish
      t.string :church
      t.string :toponym
      t.boolean :resolved

      t.timestamps
    end
  end
end
