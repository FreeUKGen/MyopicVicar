class PasswordSalt < ActiveRecord::Migration[4.2]
  def up
    add_column :refinery_users, :password_salt, :string
  end

  def down
  end
end
