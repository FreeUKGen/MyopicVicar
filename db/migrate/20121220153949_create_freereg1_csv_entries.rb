class CreateFreereg1CsvEntries < ActiveRecord::Migration
  def change
    create_table :freereg1_csv_entries do |t|
      t.string :abode
      t.string :age
      t.string :baptdate
      t.string :birthdate
      t.string :bride_abode
      t.string :bride_age
      t.string :bride_condition
      t.string :bride_fath_firstname
      t.string :bride_fath_occupation
      t.string :bride_fath_surname
      t.string :bride_firstname
      t.string :bride_occupation
      t.string :bride_parish
      t.string :bride_surname
      t.string :burdate
      t.string :church
      t.string :county
      t.string :father
      t.string :fath_occupation
      t.string :fath_surname
      t.string :firstname
      t.string :groom_abode
      t.string :groom_age
      t.string :groom_condition
      t.string :groom_fath_firstname
      t.string :groom_fath_occupation
      t.string :groom_fath_surname
      t.string :groom_firstname
      t.string :groom_occupation
      t.string :groom_parish
      t.string :groom_surname
      t.string :marrdate
      t.string :mother
      t.string :moth_surname
      t.string :no
      t.string :notes
      t.string :place
      t.string :rel1_male_first
      t.string :rel1_surname
      t.string :rel2_female_first
      t.string :relationship
      t.string :sex
      t.string :surname
      t.string :witness1_firstname
      t.string :witness1_surname
      t.string :witness2_firstname
      t.string :witness2_surname

      t.timestamps
    end
  end
end
