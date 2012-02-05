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
end