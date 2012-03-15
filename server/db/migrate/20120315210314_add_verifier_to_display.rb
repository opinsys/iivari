class AddVerifierToDisplay < ActiveRecord::Migration
  def self.up
    # authentication verifier
    add_column :displays, :verifier, :string
  end

  def self.down
    remove_column :displays, :verifier
  end
end
