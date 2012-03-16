# encoding: utf-8
require 'spec_helper'

describe AuthkeyController do
  before :each do
    # @user is created in spec_helper
    # FIXME: password check from LDAP!
    @user_session = {:username => @user.login, :password => "pwd"}
  end

  describe "#generate" do

    it "should unauthorize" do
      post :generate
      assert_response :unauthorized
      response.body.should == "You did not provide any details for authentication."
    end

    it "should authorize" do
      post :generate, @user_session 
      response.status.should_not == :unauthorized
      assigns(:user_session).should_not be_nil
      assigns(:user_session).login.should == "Test User"
    end

    it "should not accept get" do
      hostname = 'infotv-01'
      get :generate, { :hostname => hostname }.merge(@user_session)
      response.status.should == 400
      response.body.should == "GET not accepted"
    end

    it "should not generate credentials without hostname" do
      post :generate, @user_session
      response.status.should == 400
      response.body.should == "No hostname given"
    end

    it "should generate credentials for non-existing Display" do
      hostname = 'infotv-01'
      post :generate, { :hostname => hostname }.merge(@user_session)
      response.should be_success
      key = response.body
      key.length.should == 10
      display = Display.find_by_hostname(hostname)
      display.verifier.should == Digest::SHA1.hexdigest("#{hostname}:#{key}")
    end

    it "should update credentials for existing Display" do
      hostname = 'infotv-02'
      display = Display.create({:hostname => hostname, :verifier => "XYZ"})
      post :generate, { :hostname => hostname }.merge(@user_session)
      response.should be_success
      key = response.body
      key.length.should == 10
      display = Display.find_by_hostname(hostname)
      display.verifier.should_not == "XYZ"
      display.verifier.should == Digest::SHA1.hexdigest("#{hostname}:#{key}")
    end
  end


  describe "#verify" do

    it "should verify credentials" do
      hostname = 'infotv-01'
      display = Display.create({:hostname => hostname, :verifier => "XYZ"})
      request.env['X-Iivari-Auth'] = "#{hostname}:XYZ"
      post :verify, @user_session
      response.should be_success
    end

    it "should not verify credentials for unauthorized user" do
      hostname = 'infotv-01'
      display = Display.create({:hostname => hostname, :verifier => "XYZ"})
      request.env['X-Iivari-Auth'] = "#{hostname}:XYZ"
      post :verify
      assert_response :unauthorized
      response.body.should == "You did not provide any details for authentication."
    end

    it "should not verify credentials with empty auth header" do
      hostname = 'infotv-01'
      display = Display.create({:hostname => hostname, :verifier => "XYZ"})
      request.env['X-Iivari-Auth'] = ""
      post :verify, @user_session
      response.status.should == 401
    end

    it "should not verify credentials without verifier" do
      hostname = 'infotv-01'
      display = Display.create({:hostname => hostname, :verifier => "XYZ"})
      request.env['X-Iivari-Auth'] = "#{hostname}:"
      post :verify, @user_session
      response.status.should == 401
    end

    it "should not verify incorrect credentials" do
      hostname = 'infotv-01'
      display = Display.create({:hostname => hostname, :verifier => "XYZ"})
      request.env['X-Iivari-Auth'] = "#{hostname}:wrong"
      post :verify, @user_session
      response.status.should == 401
    end

    it "should not verify credentials for unexisting display" do
      hostname = 'infotv-01'
      request.env['X-Iivari-Auth'] = "#{hostname}:XYZ"
      post :verify, @user_session
      response.status.should == 401
    end

  end
end