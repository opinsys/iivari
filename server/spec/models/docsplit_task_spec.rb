# encoding: utf-8
require 'spec_helper'
require "logger"
# $logger = Logger.new STDOUT
$logger = Rails.logger

describe DocsplitTask do

  def cleanup
    FileUtils.rmtree("tmp/.spec")
    DocsplitTask.all.each &:destroy
    Image.all.each &:destroy
  end

  before :each do
    cleanup
  end

  after :all do
    cleanup
  end


  it "should split document" do
    without_access_control do
      channel = Channel.create(:name => 'test channel 1', :slide_delay => 2)
      @task = DocsplitTask.create(
          :channel_id => channel.id,
          :document_file_path => 'spec/fixtures/files/colours.pdf')
      @target_dir = File.join("tmp/.spec/docsplit/#{channel.id}-colours")
      File.exists?(@target_dir).should_not be_true
      @task.tmp_dir = @target_dir
    end

    @task.send :split

    Dir.glob(@target_dir+"/*").count.should == 7

    (1..7).each do |page|
      imgfile = File.join @target_dir, "colours_#{page}.png"
      File.exists?(imgfile).should be_true
      # Check content type
      `file -ib #{imgfile}`[/(.*);/,1].should == "image/png"
      # Check resolution
      `file -b #{imgfile}`[/(\d+ x \d+)/,1].should == "1132 x 800"
    end
  end


  it "should split document and create slide Images" do
    without_access_control do
      channel = Channel.create(:name => 'test channel 1', :slide_delay => 2)
      task = DocsplitTask.create(
          :channel_id => channel.id,
          :document_file_path => 'spec/fixtures/files/colours.pdf')
      target_dir = File.join("tmp/.spec/docsplit/#{channel.id}-colours")
      File.exists?(target_dir).should_not be_true
      task.tmp_dir = target_dir
      channel.slides.size.should == 0

      task.send :process

      channel.reload
      channel.slides.size.should == 7

      (0...7).each do |page|
        slide = channel.slides[page]
        img = "slide_images/#{slide.image}"
        File.exists?(img).should be_true
        slide.image_type.should == "image/png"
        # remove tmp image
        File.delete(img)
      end

      task.pages.should == 7
      task.reload
      task.progress.should == 100
    end
  end

end
