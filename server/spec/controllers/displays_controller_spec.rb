# encoding: utf-8
require 'spec_helper'

describe DisplaysController do
  render_views

  before :each do
    activate_authlogic
    @user = Factory.create(:valid_user)
    _session = UserSession.create(@user)
    UserSession.stub!(:find).and_return(_session)
    Authorization.stub!(:current_user).and_return(@user)

    @channel_1 = Channel.create(:name => 'test channel 1', :slide_delay => 2)
    assert @channel_1.reload
    @channel_2 = Channel.create(:name => 'test channel 2', :slide_delay => 8)
    assert @channel_2.reload

    @school_id = 2
    @school = Puavo::Client::School.new(
      @puavo_api, {"puavo_id" => @school_id, "name" => "example"})
  end


  it "should get index" do
    get :index, :school_id => @school_id
    response.should be_success
    assigns(:displays).should_not be_nil
    JSON.parse(assigns(:school).to_json)["data"].should == {"name"=>"example", "puavo_id"=>@school_id}
  end

  it "should update channels" do
    display = create_display(
      :hostname => 'kiosk1',
      :active => false)
    assert Display.find display.id

    post :update, {
      :school_id => @school_id,
      :id => display.id,
      :display => {:hostname => 'kiosk10', :active => 1},
      :channels => [@channel_2.id, @channel_1.id, "0"]}
    response.should redirect_to(display_path)
    assigns(:display).should == display

    display.reload
    display.active.should be_true
    display.hostname.should == "kiosk10"
    display.channels.should == [@channel_2, @channel_1]

    # reorder
    post :update, {
      :school_id => @school_id,
      :id => display.id,
      :channels => [@channel_1.id, @channel_2.id]}
    display.reload
    display.channels.should == [@channel_1, @channel_2]
  end


end
