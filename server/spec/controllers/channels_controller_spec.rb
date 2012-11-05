# encoding: utf-8
require 'spec_helper'

describe ChannelsController do
  render_views

  before :each do
    activate_authlogic
    @user = Factory.create(:valid_user)
    _session = UserSession.create(@user)
    UserSession.stub!(:find).and_return(_session)
    Authorization.stub!(:current_user).and_return(@user)

    @channel_1 = Channel.create(:name => 'test channel 1', :slide_delay => 2)
    @channel_1.reload
    @channel_2 = Channel.create(:name => 'test channel 2', :slide_delay => 8)
    @channel_2.reload

    @school_id = 2
    @school = Puavo::Client::School.new(
      @puavo_api, {"puavo_id" => @school_id, "name" => "example"})

    session[:schools] = [@school]
  end


  describe "when user is organisation owner" do
    before :each do
      session[:owners] = [@user.puavo_id]
      session[:user_groups] = []
    end

    it "should get welcome" do
      get :welcome, :school_id => @school_id
      response.should redirect_to(channels_path(@school_id))
    end
  end

  describe "when user is not organisation owner" do
    before :each do
      session[:owners] = []
      session[:user_groups] = []
    end

    it "should not get welcome" do
      get :welcome, :school_id => @school_id
      response.should redirect_to(new_user_session_path)
    end
  end

end
