# encoding: utf-8
require 'spec_helper'

describe UserSessionsController do
  describe "#new" do
    it "should render login page" do
      get :new
      response.should be_success
      assigns[:user_session].should_not be_nil
    end
  end

  describe "#create" do
    it "should not authorize with wrong credentials" do
      post :create, {:login => "X", :password => "wrong"}
      response.should be_success # but ..
      response.should render_template("new")
    end

    it "should authorize" do
      activate_authlogic
      @user = Factory.create(:valid_user)
      _session = UserSession.create(@user)
      UserSession.stub!(:new).and_return(_session)
      Authorization.stub!(:current_user).and_return(@user)
      post :create, {:login => @user.login, :password => ""}
      response.should redirect_to(welcome_url)
    end

  end
end
