# encoding: utf-8
require 'spec_helper'

describe ChannelsController do
  render_views

  # stub Kernel::system to capture docsplit rake task
  before :all do
    module Kernel
      alias real_system system
      def system *args
        $captured_system_args = args
        true
      end
    end
  end

  after :all do
    module Kernel
      alias system real_system
    end
  end

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

    $captured_system_args = []
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

    it "should upload pdf document and create docsplit task" do
      file = fixture_file_upload "/files/colours.pdf", "application/pdf"
      post :doc_upload, {
        :channel => {:document => file},
        :school_id => @school_id,
        :channel_id => @channel_1.id
      }
      response.should redirect_to(channel_slides_path(@school_id, @channel_1.id))

      # see that attachment was saved
      task = assigns(:task)
      task.should_not be_nil
      task.original_file_name.should eq "colours.pdf"
      tempfile = task.document_file_path
      File.exists?(tempfile).should be_true
      # file should be identical
      FileUtils.cmp(
        tempfile,
        "spec/fixtures/files/colours.pdf"
        ).should be_true

      # system rake command should be run
      cmd = $captured_system_args.join(" ")
      cmd.should =~ /rake iivari:docsplit/
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

    it "should not upload pdf document" do
      file = fixture_file_upload "/files/colours.pdf", "application/pdf"
      post :doc_upload, {
        :channel => {:document => file},
        :school_id => @school_id,
        :channel_id => @channel_1.id
      }
      response.should redirect_to(new_user_session_path)
      assigns(:task).should be_nil
    end

  end

end
