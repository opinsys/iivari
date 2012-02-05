require 'spec_helper'

describe Display do

  before :each do
    @display = Display.create({:hostname => 'infotv-01'})
    assert @display.reload
  end

  it "should belong to proper organisation" do
    @display.organisation.should == @organisation.organisation_key
  end 

  it "should associate to a channel" do
    channel = Channel.create(:name => 'test channel 1', :slide_delay => 2)
    assert channel.reload
    @display.channel = channel
    @display.save
    channel.reload
    @display.channel.should == channel
    channel.displays.size.should == 1
    assert channel.displays.include?(@display)
  end

end
