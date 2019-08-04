# This migration comes from refinery_authentication_devise (originally 20130805143059)
class AddFullNameToRefineryUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :refinery_users, :full_name, :string
  end
end
