require 'spec_helper'

describe Channel do

  before :each do
    without_access_control do
      @channel = Channel.create(:name => 'test channel 1', :slide_delay => 2)
      assert @channel.reload
    end
  end

  it "should have three displays" do
    without_access_control do
      display_1 = Display.create({:hostname => 'infotv-01'})
      display_2 = Display.create({:hostname => 'infotv-02'})
      display_3 = Display.create({:hostname => 'infotv-03'})

      @channel.displays = [display_1, display_2]
      @channel.displays << display_3
      @channel.save

      assert @channel.reload

      @channel.displays.size.should == 3
      assert @channel.displays.include?(display_1)
      assert @channel.displays.include?(display_2)
      assert @channel.displays.include?(display_3)
      display_1.channel.should == @channel
      display_2.channel.should == @channel
      display_3.channel.should == @channel
    end
  end

  it "should have three slides" do
    without_access_control do
      slide_1 = Slide.create(:channel => @channel)
      slide_2 = Slide.create(:channel => @channel)
      slide_3 = Slide.create(:channel => @channel)

      slide_1.channel.should == @channel
      slide_2.channel.should == @channel
      slide_3.channel.should == @channel

      assert @channel.reload

      @channel.slides.size.should == 3
      assert @channel.slides.include?(slide_1)
      assert @channel.slides.include?(slide_2)
      assert @channel.slides.include?(slide_3)
    end
  end

end
