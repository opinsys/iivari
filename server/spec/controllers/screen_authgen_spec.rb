# encoding: utf-8
require 'spec_helper'

class ScreenController < ApplicationController
  skip_before_filter :auth_require, :only => [:generate_credentials, :displayauth2]

  def displayauth2
    if verify_credentials
      render :text => "OK"
    else
      render :text => "", :status => :unauthorized
    end
  end
end

describe ScreenController do
  describe "#generate_credentials" do

    xit "should unauthorize" do
      post :generate_credentials
      assert_response :redirect
    end

    it "should not accept get" do
      hostname = 'infotv-01'
      get :generate_credentials, :hostname => hostname
      response.status.should == 400
      response.body.should == "GET not accepted"
    end

    it "should not generate credentials without hostname" do
      post :generate_credentials
      response.status.should == 400
      response.body.should == "No hostname given"
    end

    it "should generate credentials for non-existing Display" do
      hostname = 'infotv-01'
      post :generate_credentials, :hostname => hostname
      response.should be_success
      password = JSON.parse(response.body)["password"]
      password.length.should == 10
      display = Display.find_by_hostname(hostname)
      display.verifier.should == Digest::SHA1.hexdigest("#{hostname}:#{password}")
    end

    it "should update credentials for existing Display" do
      hostname = 'infotv-02'
      display = Display.create({:hostname => hostname, :verifier => "XYZ"})
      post :generate_credentials, :hostname => hostname
      response.should be_success
      password = JSON.parse(response.body)["password"]
      password.length.should == 10
      display = Display.find_by_hostname(hostname)
      display.verifier.should_not == "XYZ"
      display.verifier.should == Digest::SHA1.hexdigest("#{hostname}:#{password}")
    end
  end


  describe "#displayauth2" do

    it "should not verify credentials with empty auth header" do
      hostname = 'infotv-01'
      display = Display.create({:hostname => hostname, :verifier => "XYZ"})
      get :displayauth2, nil, {"X-IIVARI-AUTH" => ""}
      response.status.should == 401
    end

    it "should not verify credentials without verifier" do
      hostname = 'infotv-01'
      display = Display.create({:hostname => hostname, :verifier => "XYZ"})
      get :displayauth2, nil, {"X-IIVARI-AUTH" => "#{hostname}:"}
      response.status.should == 401
    end

    it "should not verify incorrect credentials" do
      hostname = 'infotv-01'
      display = Display.create({:hostname => hostname, :verifier => "XYZ"})
      get :displayauth2, nil, {"X-IIVARI-AUTH" => "#{hostname}:wrong"}
      response.status.should == 401
    end

    it "should not verify credentials for unexisting display" do
      hostname = 'infotv-01'
      get :displayauth2, nil, {"X-Iivari-Auth" => "#{hostname}:XYZ"}
      response.status.should == 401
    end

    it "should verify credentials" do
      hostname = 'infotv-01'
      display = Display.create({:hostname => hostname, :verifier => "XYZ"})
      get :displayauth2, nil, {"X-IIVARI-AUTH" => "#{hostname}:XYZ"}
      response.should be_success
    end
  end
end