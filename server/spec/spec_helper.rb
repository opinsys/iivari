# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'

# http://www.ruby.code-experiments.com/blog/2011/02/rspec-rails-3-and-authlogic.html
require 'authlogic/test_case'
include Authlogic::TestCase

require 'factory_girl'
Factory.define :valid_user, :class => User do |u| 
  u.login "Test User"
  u.persistence_token lambda{(0...8).map{65.+(rand(25)).chr}.join} # random string
  u.puavo_id 1
  u.role_symbols [:organisation_owner]
end

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

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

    # authlogic will raise an error if factory girl attempts to create
    # same user more than once, prevent that.
    user = User.find_by_login("Test User")
    user.destroy if user

    # authorize user
    activate_authlogic
    @user = Factory.create(:valid_user)
    #UserSession.create(@user)
    Authorization.stub!(:current_user).and_return(@user)
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
  

