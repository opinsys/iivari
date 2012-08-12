# encoding: utf-8
class DocsplitTask < ActiveRecord::Base
  belongs_to :channel
  attr_accessible :channel_id, :document_file_path, :original_file_name, :pending, :progress, :rejected, :resolved, :error
  attr_reader :pages
  attr_writer :tmp_dir

  def self.find_pending
    all :conditions => {:pending => true}
  end

  # Create "slides" in the specified dir using Docsplit.
  # Called from tasks/docplit.rake
  def process
    logger.info "Processing task #{self.id} on channel #{channel_id}"

    unless File.exist?(document_file_path)
      logger.warn "File not found: #{document_file_path}"
      exit 1
    end
    original_file_name ||= File.basename(document_file_path)

    @content_type = content_type(document_file_path)
    unless @content_type[/pdf/]
      logger.warn "File #{document_file_path} has invalid content-type #{@content_type}"
      exit 1
    end
    @pages = Docsplit.extract_length(document_file_path)
    logger.info "File #{document_file_path} is #{@content_type}, #{@pages} pages"

    @tmp_dir ||= File.join Rails.root, 'tmp', 'docsplit', "#{channel_id}-#{original_file_name}"

    split and create_slides
  end

  protected

  def split
    Docsplit.extract_images(
      document_file_path,
      :size => 'x800',
      :format => :png,
      :output => @tmp_dir
      )
  end

  Struct.new("ImageStream", :read, :content_type)

  def create_slides
    # append slides to the end of channel
    position = channel.slides.length
    count = 0
    # update progress to 50%
    self.progress = 50
    self.save
    # create Image from each file in docsplit output directory
    Dir.glob(File.join(@tmp_dir, "*")) do |file|
      position += 1
      # construct an object for Image model API
      image = Image.find_or_create(
        Struct::ImageStream.new(File.read(file), "image/png"))
      slide = Slide.create(
        :template => "only_image",
        :channel_id => channel_id,
        :title => "",
        :image => image.key,
        :position => position)
      count += 1
      logger.debug "Created slide at position #{slide.position} (id #{slide.id})"
    end
    logger.info "Created #{count} slides on channel \"#{channel.name}\""
    self.progress = 100
    self.save
  end

  private

  def content_type file
    `file -ib "#{file}"`[/(.*);/,1]
  end

  # use docsplit rake task logger
  def self.logger; $logger rescue Rails.logger end
  def logger; $logger rescue Rails.logger end

end
