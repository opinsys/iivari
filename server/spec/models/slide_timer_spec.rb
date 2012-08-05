require 'spec_helper'

# NOTE: start_time and end_time are datetimes in the database,
# although the date is never used, only the time.
describe SlideTimer do

  before :each do
    without_access_control do
      @channel = Channel.create(:name => 'test channel 1', :slide_delay => 2)
      assert @channel.reload
      @slide = Slide.create(:channel => @channel)
      assert @slide.reload
      @slide.channel.should == @channel
    end
  end

  it "should parse to json" do
    without_access_control do
      # active between 9.15 -> 19.30 @ 1.8.2011 14.00 - 31.8.2011 14.00
      timer = SlideTimer.create(
        :start_datetime => DateTime.new(2011,8,1,14,0),
        :end_datetime => DateTime.new(2011,8,31,14,0),
        :start_time => DateTime.new(1970,1,1,9,15),
        :end_time => DateTime.new(1970,1,1,19,30),
        :weekday_0 => true,
        :weekday_1 => false,
        :weekday_2 => false,
        :weekday_3 => false,
        :weekday_4 => false,
        :weekday_5 => false,
        :weekday_6 => false,
        :slide => @slide
        )
      json = timer.to_json
      json['start_datetime'].should == "2011/08/01 14:00 GMT+0000"
      json['end_datetime'].should == "2011/08/31 14:00 GMT+0000"
      json['start_time'].should == "1970/01/01 09:15 GMT+0000"
      json['end_time'].should == "1970/01/01 19:30 GMT+0000"
      json['weekday_0'].should == true
      json['weekday_1'].should == false
      json['weekday_2'].should == false
      json['weekday_3'].should == false
      json['weekday_4'].should == false
      json['weekday_5'].should == false
      json['weekday_6'].should == false
    end
  end

  it "should parse with undefined dates" do
    without_access_control do
      timer = SlideTimer.create(:slide => @slide)
      assert timer.reload
      json = timer.to_json
      json['start_datetime'].should == ""
      json['end_datetime'].should == ""
      json['start_time'].should == ""
      json['end_time'].should == ""
      json['weekday_0'].should == true
      json['weekday_1'].should == true
      json['weekday_2'].should == true
      json['weekday_3'].should == true
      json['weekday_4'].should == true
      json['weekday_5'].should == true
      json['weekday_6'].should == true
    end
  end

  it "should update slide and channel with new timer" do
    without_access_control do
      timer = SlideTimer.create(:slide => @slide)
      assert timer.reload
      timer.slide.should == @slide
      @slide.timers.size.should == 1
      assert_in_delta Time.now, @channel.updated_at, 1
    end
  end

end
