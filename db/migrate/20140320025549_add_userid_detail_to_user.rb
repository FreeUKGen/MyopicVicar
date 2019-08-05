class AddUseridDetailToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :refinery_users, :userid_detail_id, :string
  end
end
