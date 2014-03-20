class AddUseridDetailToUser < ActiveRecord::Migration
  def change
    add_column :refinery_users, :userid_detail_id, :string
  end
end
