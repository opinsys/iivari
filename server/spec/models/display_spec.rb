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
    @display.channels << @channel_1
    @display.save
    @channel_1.reload
    @display.channels.should == [@channel_1]
    @channel_1.displays.should == [@display]
  end

  it "should have three channels" do
    @display.channels = [@channel_3, @channel_1]
    @display.channels << @channel_2

    assert @channel_1.reload
    assert @channel_2.reload
    assert @channel_3.reload
    assert @display.reload

    @display.channels.size.should == 3
    # assert initial order
    @display.channels.should == [@channel_3, @channel_1, @channel_2]
    @display.channels.each do |channel|
      channel.displays.should == [@display]
    end

    # update positions
    @display.displays_channels[0].position = 3
    @display.displays_channels[1].position = 1
    @display.displays_channels[2].position = 2
    assert @display.displays_channels[0].save
    assert @display.displays_channels[1].save
    assert @display.displays_channels[2].save
    @display.displays_channels.reload

    @display.reload
    @display.channels.should == [@channel_1, @channel_2, @channel_3]

    # update by reassignment
    @display.channels = [] # IMPORTANT TO CLEAR FIRST!
    @display.channels = [@channel_2, @channel_3, @channel_1]
    @display.reload
    @display.channels.should == [@channel_2, @channel_3, @channel_1]
  end

end
