class AddNewVolumesDistrict < ActiveRecord::Migration[5.1]
  connects_to database: { writing: FREEBMD_DB }
  def change
    rename_column :Districts, :Volume1974toEnd, :Volume1974to1993_4
    add_column :Districts, :Volume1993_4toEnd, :string
  end
end
