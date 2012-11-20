class CreateEmendationRules < ActiveRecord::Migration
  def change
    create_table :emendation_rules do |t|
      t.string :source
      t.string :target

      t.timestamps
    end
  end
end
