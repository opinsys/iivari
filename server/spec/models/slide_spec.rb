require 'spec_helper'

describe Slide do

  before :each do
  end

  it "should associate to channel" do
    without_access_control do
      @channel = Channel.create(:name => 'test channel 1', :slide_delay => 2)
      assert @channel.reload
      slide = Slide.create(
        :channel => @channel,
        :position => 1,
        :title => 'test title 1',
        :body => 'test body',
        :template => 'only_text')
      assert slide.reload
      slide.channel.should == @channel
      @channel.reload
      @channel.slides.size.should == 1
      assert @channel.slides.include?(slide)
    end
  end

end
