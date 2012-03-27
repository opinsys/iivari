# encoding: utf-8
require 'spec_helper'

describe ScreenController do
  render_views

  # displayauth is for stock browsers -- insecure
  describe "#displayauth" do
    it "should unauthorize" do
      get :displayauth
      assert_response :unauthorized
      assert_nil session[:display_authentication]
    end

    it "should authorize with hostname" do
      hostname = 'infotv-01'
      get :displayauth, :hostname => hostname
      assert_response :redirect
      assert_redirected_to conductor_screen_path
      assert session[:display_authentication]
      assert_equal hostname, session[:hostname]
      assert_equal 'default', session[:organisation].organisation_key # not test @organisation ?!
      @response.request.env['rack.session.options'][:expire_after].should == 20.years
    end

    it "should authorize with hostname and resolution" do
      hostname = 'infotv-01'
      resolution = '800x600'
      get :displayauth, :hostname => hostname, :resolution => resolution
      assert_response :redirect
      assert_redirected_to conductor_screen_path(:resolution => resolution)
      assert session[:display_authentication]
      assert_equal hostname, session[:hostname]
    end
  end


  # more secure authentication method
  # - more thorough testing is carried out in authkey_controller_spec
  describe "#displayauth_verify filter" do
    before :each do
      @hostname = 'infotv-01'
      @verifier = "XYZ"
      @display = create_display :hostname => @hostname, :active => true, :verifier => @verifier
    end

    it "should unauthorize unknown display" do
      get :conductor, {:hostname => "unknown"}
      assert_response :unauthorized
    end

    it "should unauthorize with missing X-Iivari-Auth header" do
      get :conductor, {:hostname => @hostname}
      assert_response :unauthorized
    end

    it "should unauthorize with incorrect verifier" do
      request.env['X-Iivari-Auth'] = "#{@hostname}:XXX"
      get :conductor, {:hostname => @hostname}
      assert_response :unauthorized
    end

    it "should authorize" do
      request.env['X-Iivari-Auth'] = "#{@hostname}:#{@verifier}"
      get :conductor, {:hostname => @hostname}
      assert_response :success
    end
  end


  describe "#conductor" do
    before :each do
      @hostname = 'infotv-01'
      @resolution = '800x600'
      @verifier = "XYZ"
      request.env['X-Iivari-Auth'] = "#{@hostname}:#{@verifier}"
    end

    it "should render with inactive display" do
      display = create_display :hostname => @hostname, :active => false, :verifier => @verifier
      get :conductor, {:hostname => @hostname, :resolution => @resolution}
      response.should be_success
      assigns(:display).should == display
      assigns(:json_url).should == 'slides.json?resolution=800x600' 
      response.should render_template("conductor")
    end

    it "should render with active display without channel" do
      display = create_display :hostname => @hostname, :active => true, :verifier => @verifier
      get :conductor, {:hostname => @hostname, :resolution => @resolution}
      response.should be_success
      assigns(:display).should == display
      assigns(:json_url).should == 'slides.json?resolution=800x600' 
      response.should render_template("conductor")
    end

    it "should render with active display and channel" do
      display = create_display :hostname => @hostname, :active => true, :verifier => @verifier
      channel = Channel.create(:name => 'test channel 1', :slide_delay => 2)
      display.channel = channel
      display.save
      get :conductor, {:hostname => @hostname, :resolution => @resolution}
      response.should be_success
      assigns(:display).should == display
      assigns(:channel).should == channel
      assigns(:json_url).should == 'slides.json?resolution=800x600' 
      response.should render_template("conductor")
      display.reload
      display.last_seen_at.should be_within(1).of(Time.now)
    end
  end

  describe "#slides.json" do
    before :each do
      @hostname = 'infotv-01'
      @resolution = '800x600'
      @verifier = "XYZ"
      request.env['X-Iivari-Auth'] = "#{@hostname}:#{@verifier}"
    end

    it "should unauthorize without display" do
      get :slides, {:hostname => @hostname, :resolution => @resolution, :format => :json}
      assert_response :unauthorized
    end

    it "should render notice with inactive display" do
      display = create_display :hostname => @hostname, :active => false, :verifier => @verifier
      get :slides, {:hostname => @hostname, :resolution => @resolution, :format => :json}
      response.should be_success
      assigns(:display).should == display
      data = JSON.parse response.body
      data.length.should == 1
      data.first["slide_html"].should =~ /Aktivoi näyttö/
    end

    it "should render notice with active display without channel" do
      display = create_display :hostname => @hostname, :active => true, :verifier => @verifier
      get :slides, {:hostname => @hostname, :resolution => @resolution, :format => :json}
      response.should be_success
      assigns(:display).should == display
      data = JSON.parse response.body
      data.length.should == 1
      data.first["slide_html"].should =~ /Aktivoi näyttö/
    end

    it "should render json" do
      display = create_display :hostname => @hostname, :active => true, :verifier => @verifier
      channel = Channel.create(:name => 'test channel 1', :slide_delay => 2)
      display.channel = channel
      display.save
      slide = Slide.create(
        :channel => channel, 
        :position => 1, 
        :title => 'test title 1', 
        :body => 'test body', 
        :template => 'only_text')
      assert slide.reload

      get :slides, {:hostname => @hostname, :resolution => @resolution, :format => :json}
      response.should be_success
      assigns(:display).should == display
      assigns(:channel).should == channel

      slides = JSON.parse response.body
      assert_equal 1, slides.size
      assert_equal true, slides[0]["status"]
      assert_equal 2, slides[0]["slide_delay"]
      slides[0]["slide_html"].should =~ /test title 1/
      slides[0]["slide_html"].should =~ /test body/
    end
  end


  context "#ajax actions with slide data" do
    before :each do
      @hostname_1 = 'infotv-01'
      @hostname_2 = 'infotv-02'
      @resolution = '800x600'
      @verifier_1 = "XYZa"
      @verifier_2 = "XYZb"

      @channel_1 = Channel.create(:name => 'test channel 1', :slide_delay => 2)
      assert @channel_1.reload
      @channel_2 = Channel.create(:name => 'test channel 2', :slide_delay => 8)
      assert @channel_2.reload

      @slide_11 = Slide.create(
        :channel => @channel_1, 
        :position => 1, 
        :title => 'test title 11', :body => 'test body 11', :template => 'only_text')
      @slide_12 = Slide.create(
        :channel => @channel_1, 
        :position => 2, 
        :title => 'test title 12', :body => 'test body 12', :template => 'only_text')
      @slide_21 = Slide.create(
        :channel => @channel_2, 
        :position => 1, 
        :title => 'test title 21', :body => 'test body 21', :template => 'only_text')
      @slide_22 = Slide.create(
        :channel => @channel_2, 
        :position => 2, 
        :title => 'test title 22', :body => 'test body 22', :template => 'only_text')
      @slide_23 = Slide.create(
        :channel => @channel_2, 
        :position => 3, 
        :title => 'test title 23', :body => 'test body 23', :template => 'only_text')
      
      # enable channel, activate displays
      @display_1 = create_display(
        :hostname => @hostname_1, 
        :channel => @channel_1, 
        :active => true, 
        :verifier => @verifier_1)
      assert @display_1.reload
      @display_2 = create_display(
        :hostname => @hostname_2, 
        :channel => @channel_2, 
        :active => true, 
        :verifier => @verifier_2)
      assert @display_2.reload
    end

    it "should render slides html with one channel" do
      request.env['X-Iivari-Auth'] = "#{@hostname_1}:#{@verifier_1}"
      get :slides, {:resolution => @resolution, :format => :json}
      response.should be_success
      assigns(:display).should == @display_1
      assigns(:channel).should == @channel_1
      slides = JSON.parse response.body
      slides.size.should == 2
      slides[0]["status"].should be_true
      slides[0]["slide_delay"].should == 2
      slides[0]["slide_html"].should =~ /test title 11/
      slides[0]["slide_html"].should =~ /test body 11/
      slides[1]["slide_html"].should =~ /test title 12/
      slides[1]["slide_html"].should =~ /test body 12/
    end

    it "should render slides html with two channels" do
      request.env['X-Iivari-Auth'] = "#{@hostname_2}:#{@verifier_2}"
      get :slides, {:resolution => @resolution, :format => :json}
      response.should be_success
      assigns(:display).should == @display_2
      assigns(:channel).should == @channel_2
      slides = JSON.parse response.body
      slides.size.should == 3
      slides[0]["status"].should be_true
      slides[0]["slide_delay"].should == 8
      slides[0]["slide_html"].should =~ /test title 21/
      slides[0]["slide_html"].should =~ /test body 21/
      slides[1]["slide_html"].should =~ /test title 22/
      slides[1]["slide_html"].should =~ /test body 22/
      slides[2]["slide_html"].should =~ /test title 23/
      slides[2]["slide_html"].should =~ /test body 23/
    end

    it "should get display" do
      request.env['X-Iivari-Auth'] = "#{@hostname_2}:#{@verifier_2}"
      get :display_ctrl, {:format => :json}
      assert_response :success
      assigns(:display).should == @display_2
    end

    it "should get timer json" do
      poweroff_timer = {
        :type => "poweroff",
        :start_date => "2011/01/01",
        :end_date => "2011/12/31",
        :start_at => "00:00",
        :end_at => "00:00",
        'weekdays' => '*'
      }
      refresh_timer = {
        :type => "refresh",
        :start_date => "2011/02/01",
        :end_date => "2011/11/31",
        :start_at => "07:00",
        'weekdays' => [0,2,4,6]
      }

      # FIXME: timers are loaded from config file, these have no effect!
      @organisation.control_timers = [poweroff_timer, refresh_timer]

      request.env['X-Iivari-Auth'] = "#{@hostname_1}:#{@verifier_1}"
      get :display_ctrl, {:resolution => @resolution, :format => :json}
      assert_response :success
      assigns(:display).should == @display_1

      ctrl = JSON.parse response.body
      self.assert ctrl
      assert_equal @hostname_1, ctrl["hostname"]
      assert_equal 7, ctrl["timers"].size

      poweroff_timers = ctrl["timers"].collect{ |day|
        day.select{|t| t["type"] == "poweroff"} }.flatten.compact
      # poweroff timers have weekdays "*", one for each day of the week
      assert_equal 7, poweroff_timers.size
      poweroff_timers.each{|t| assert_equal({
        "type"=>"poweroff",
        "start_date"=>"2011/01/01",
        "end_date"=>"2011/12/31",
        "end_at"=>"00:00",
        "start_at"=>"00:00"
        }, t)}

      refresh_timers = [
        ctrl["timers"][0].select{|t| t["type"] == "refresh"},
        ctrl["timers"][2].select{|t| t["type"] == "refresh"},
        ctrl["timers"][4].select{|t| t["type"] == "refresh"},
        ctrl["timers"][6].select{|t| t["type"] == "refresh"}
        ].flatten
      assert_equal 4, refresh_timers.size
      refresh_timers.each{|t| assert_equal({
        "type"=>"refresh",
        "start_date"=>"2011/02/01",
        "end_date"=>"2011/11/31",
        "start_at"=>"07:00"
        }, t)}
    end
  end

end