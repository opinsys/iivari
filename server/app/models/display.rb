class Display < OrganisationData
  # Display can have many channels in specific order.
  # Channel position is stored in table "displays_channels".
  has_many :displays_channels
  has_many :channels, 
    :through => :displays_channels,
    :order => :position

  validates_presence_of :hostname

  def self.find_all_by_school_id(school_id, puavo_api)
    # FIXME: get devices by type
    puavo_devices = puavo_api.devices.find_by_school_id(school_id)
    all.select do |display|
      puavo_devices.map{ |d| d.puavoHostname.to_s }.include?(display.hostname)
    end
  end
end

