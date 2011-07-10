class DisplaysChannels < ActiveRecord::Migration
  # insert default organisation data to update records
  organisation = Organisation.new
  organisation.organisation_key = 'default'
  Organisation.current= organisation

  def self.up
    # playlist keeps track of channel position for each display
   create_table :displays_channels do |t|
      t.integer :display_id
      t.integer :channel_id
      t.integer :position
    end
    
    # update existing records
    puts "Updating existing records . . ."
    Display.all.each do |display|
      begin
        channel = Channel.find(display.channel_id)
        puts "Display #{display.id}: channel #{channel.id}"
        display.channels << channel
        display.save
        display = Display.find(display.id)
        unless display.channels == [channel]
          puts "oops"
        end
      rescue ActiveRecord::RecordNotFound
        puts "Display #{display.id}: no channel"
        if display.channel_id
          puts "WARNING: channel #{display.channel_id} does not exist"
        end
      end
    end

    remove_column :displays, :channel_id
  end

  def self.down
    add_column :displays, :channel_id, :integer

    # revoke first channel of all displays to channel_id
    Display.all.each do |display|
      begin
        next unless display.channels.any?
        channel = display.channels.first
        channel.reload
        puts "Display #{display.id}: channel #{channel.id}"
        display.channel_id = channel.id
        display.save
      rescue ActiveRecord::RecordNotFound
        if display.channel_id
          puts "WARNING: display #{display.id} (#{display.hostname}) channels could not be reverted"
        end
      end
    end

    drop_table :displays_channels
  end
end
