# encoding: utf-8
require 'spec_helper'

describe SlidesController do
  render_views

  before :each do
    activate_authlogic
    @user = Factory.create(:valid_user)
    _session = UserSession.create(@user)
    UserSession.stub!(:find).and_return(_session)
    Authorization.stub!(:current_user).and_return(@user)

#    session[:owners] = [@user.puavo_id]
#    session[:organisation] = @organisation

    @channel = Channel.create(:name => 'test channel 1', :slide_delay => 2)
    assert @channel.reload

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

    it "should create new slide" do
      slide_params = {"title"=>"hello world", "body"=>"<p>regards</p>", "template"=>"only_text"}
      post :create, {"slide" => slide_params, :school_id => @school_id, :channel_id => @channel.id}

      assigns(:channel).should eq @channel
      slide = assigns(:slide)
      response.should redirect_to(
        channel_slide_path(
          :id => slide.id,
          :school_id => @school_id,
          :channel_id => @channel.id))
      slide.should eq Slide.find_by_title("hello world")
    end
  end

  describe "when user is not organisation owner" do
    before :each do
      session[:owners] = []
      session[:user_groups] = []
    end

    it "should not create new slide" do
      post :create, {"slide" => {}, :school_id => @school_id, :channel_id => @channel.id}
      response.should redirect_to(new_user_session_path)
    end
  end



end
