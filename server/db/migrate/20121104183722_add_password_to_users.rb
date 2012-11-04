class AddPasswordToUsers < ActiveRecord::Migration
  def change
    add_column :users, :crypted_password, :string
    add_column :users, :password_salt, :string
  end
end
