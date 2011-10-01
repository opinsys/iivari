class AddLastSeenAtToDisplays < ActiveRecord::Migration
  def self.up
    # timestamp of client update request, issue #4
    add_column :displays, :last_seen_at, :datetime
  end

  def self.down
    remove_column :displays, :last_seen_at
  end
end
