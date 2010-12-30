class Slide < OrganisationData
  belongs_to :channel
  has_many :slide_timers
  
  acts_as_list :scope => :channel

  before_save :fix_http_url

  after_update :set_channel_updated_at
  after_create :set_channel_updated_at

  after_destroy :remove_image

  attr_accessor :slide_html

  def image_url(resolution)
    unless self.image.nil?
      "image/#{self.template}/#{self.image}?resolution=#{resolution}"
    end
  end

  def self.image_urls(channel, resolution)
    channel.slides.inject([]) do |result, s|
      s.image.nil? ? result : ( result.push s.image_url(resolution) )
    end
  end

  def updated_at
    self.channel.updated_at unless self.channel.nil?
  end

  def timers
    return self.slide_timers.map do |timer|
      { "start_datetime" => (timer.start_datetime.getutc rescue ""),
        "end_datetime" => (timer.end_datetime.getutc rescue ""),
        "start_time" => (timer.start_time.getutc rescue ""),
        "end_time" => (timer.end_time.getutc rescue ""),
        "weekday_0" => timer.weekday_0,
        "weekday_1" => timer.weekday_1,
        "weekday_2" => timer.weekday_2,
        "weekday_3" => timer.weekday_3,
        "weekday_4" => timer.weekday_4,
        "weekday_5" => timer.weekday_5,
        "weekday_6" => timer.weekday_6 }
    end
  end

  def slide_delay
    self.channel && self.channel.slide_delay ? self.channel.slide_delay : 15
  end

  protected

  def set_channel_updated_at
    self.channel.updated_at = Time.now
    self.channel.save
  end

  private

  def fix_http_url
    if self.template == "web_page"
      if self.body.match(/http[s]{0,1}:\/\//).nil?
        self.body = "http://#{self.body}"
      end
    end
  end

  def remove_image
    if Slide.where(:image => self.image).empty?
      unless self.image.nil?
        image = Image.find_by_key(self.image)
        unless image.nil?
          image.destroy
        end
      end
    end
  end
end
