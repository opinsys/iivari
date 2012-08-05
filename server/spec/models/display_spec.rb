require 'spec_helper'

describe Display do

  before :each do
    without_access_control do
      @display = Display.create({:hostname => 'infotv-01'})
      @channel_1 = Channel.create(:name => 'test channel 1', :slide_delay => 2)
      @channel_2 = Channel.create(:name => 'test channel 2', :slide_delay => 4)
      @channel_3 = Channel.create(:name => 'test channel 3', :slide_delay => 6)
    end
  end

  after :each do
    without_access_control do
      Display.all.each &:destroy
      Channel.all.each &:destroy
    end
  end

  it "should belong to proper organisation" do
    @display.organisation.should == @organisation.organisation_key
  end

  it "should have a channel" do
    @display.channel = @channel_1
    @display.save
    @channel_1.reload
    @display.channel.should == @channel_1
    @channel_1.displays.size.should == 1
    assert @channel_1.displays.include?(@display)
  end

end
