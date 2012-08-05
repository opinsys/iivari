# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

# http://www.ruby.code-experiments.com/blog/2011/02/rspec-rails-3-and-authlogic.html
require 'authlogic/test_case'
include Authlogic::TestCase

require 'declarative_authorization/maintenance'
include Authorization::TestHelper

require 'factory_girl'
Factory.define :valid_user, :class => User do |u|
  u.login "Test User #{Digest::MD5.hexdigest(Time.now.to_s)}"
  u.persistence_token lambda{(0...8).map{65.+(rand(25)).chr}.join} # random string
  u.puavo_id 1
  u.role_symbols [:organisation_owner]
  u.organisation "default"
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

# Sinatra patches ActiveRecord classes with the method "template"
# and this clashes with Slide#template.
# Undefine this method, as Sinatra is used only with Cucumber.
module Sinatra::Delegator
  remove_method :template
end

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  config.before(:each) do
    @organisation = MockOrganisation.new
    @organisation.organisation_key = 'default'
    @organisation.host = '*'
    Organisation.current= @organisation

    server = "test_puavo_api_server"
    username = "test_puavo_api_username"
    password = "test_puavo_api_password"
    ssl = true
    @puavo_api = Puavo::Client::Base.new( server, username, password, ssl )
  end

  config.after(:each) do
    @user.destroy if @user
  end
end


class MockOrganisation
  attr_accessor :organisation_key, :host
  alias :key :organisation_key
  
  attr_writer :control_timers
  
  def name
    'test organisation'
  end
  
  def value_by_key key
    case key
    when 'control_timers'
      @control_timers
    else 'test_'+key
    end
  end
end

def create_display *args
  count = Display.count
  display = Display.create(args).first
  assert_equal @organisation.organisation_key, display.organisation
  assert_equal count+1, Display.count
  return display
end
  

