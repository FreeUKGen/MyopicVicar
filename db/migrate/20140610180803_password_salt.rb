class PasswordSalt < ActiveRecord::Migration
  def up
    add_column :refinery_users, :password_salt, :string
  end

  def down
  end
end
