class AddNewVolumesDistrict < ActiveRecord::Migration[5.1]
  def change
    rename_column :District, :Volume1974toEnd, :Volume1974to1993_4
    add_column :District, :Volume1993_4toEnd, :string
  end
end
