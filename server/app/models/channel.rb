class Channel < OrganisationData
  has_many :slides, :order => "position"
  has_many :displays
  has_many :docsplit_tasks

  validates_presence_of :name
  validates_inclusion_of :slide_delay, :in => 2..600

  using_access_control

  def self.themes
    %w{gold cyan green}
  end

  def theme?
    (self.theme.nil? || self.theme.empty?) ? false : true
  end
end
