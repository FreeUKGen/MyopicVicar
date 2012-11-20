class CreateEmendationTypes < ActiveRecord::Migration
  def change
    create_table :emendation_types do |t|
      t.string :target_field
      t.string :name

      t.timestamps
    end
  end
end
