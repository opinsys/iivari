class UserSession < Authlogic::Session::Base
  include ActiveModel::Conversion

  if Iivari::Application.config.standalone_mode
    find_by_login_method :standalone_login
  else
    find_by_login_method :find_or_create_from_ldap
    verify_password_method :valid_ldap_credentials?
  end

  def persisted?
    false
  end
end 
