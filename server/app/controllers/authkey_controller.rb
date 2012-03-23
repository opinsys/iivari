class AuthkeyController < ApplicationController
  before_filter :authorize_user
  skip_before_filter :require_user, :find_school, :set_locale

  # REST API for creating Display password.
  # Password verifier is stored to the database.
  # POST /authkey/generate, data: {username, password, hostname}
  def generate
    unless request.post?
      render :text => "GET not accepted", :status => 400
      return
    end
    hostname = params[:hostname]
    unless hostname
      render :text => "No hostname given", :status => 400
      return
    end
    # find or create new Display by hostname
    display = Display.find_or_create_by_hostname(hostname)
    # generate new password and save verifier
    key = random_string
    # use hostname as salt for simplicity
    verifier = Digest::SHA1.hexdigest "#{hostname}:#{key}"
    logger.debug "key: #{key} verifier: #{verifier}"
    display.verifier = verifier
    display.save
    render :text => key
  end

  # Verifies the X-Iivari-Auth request header.
  # Responds with "ok" or "unauthorized".
  # POST /authkey/verify, data: {username, password}
  def verify
    status = verify_credentials ? :ok : :unauthorized
    render :text => status.to_s, :status => status
  end

  private

  # Authorize user.
  def authorize_user
    @user_session = UserSession.new({
      :login => params[:username], :password => params[:password]})
    @user_session.save
    if @user_session.errors.any?
      logger.warn "Authlogic errors: %s" % @user_session.errors.inspect
      message = @user_session.errors.messages.first[1][0]
      render :text => message, :status => :unauthorized
    end
  end

  def random_string(length=10)
    [ ('0'..'9').to_a,
      ('A'..'Z').to_a,
      ('a'..'z').to_a,
      %w(, ! ? @ & :)
    ].flatten.
      sort_by { Kernel.rand }.join[0...length]
  end

  # Display authentication token is passed in X-IIVARI-AUTH header.
  # The token contains <hostname>:<verifier>
  def verify_credentials
    token = request.headers["X-Iivari-Auth"]
    unless token
      logger.warn "X-Iivari-Auth header is undefined"
      return false
    end

    (hostname, key) = token.split(":")
    return false unless key

    display = Display.find_by_hostname(hostname)
    return false unless display
    return false unless display.verifier

    # does the key match?
    if display.verifier == key
      logger.info "#{hostname} is authenticated"
      return true
    else
      logger.warn "#{hostname} is not authenticated"
      return false
    end
  end
end
