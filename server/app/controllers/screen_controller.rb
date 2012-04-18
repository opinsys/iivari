class ScreenController < ApplicationController
  skip_before_filter :require_user, :find_school
  respond_to :html, :json
  layout "screen"
  before_filter :auth_require, :except => :displayauth
  before_filter :log_last_seen_at, :except => :image
  after_filter :persist_session
  
  # GET /slides.json?resolution=800x600
  def slides
    if (@display && @display.active && @channel) || preview?
      if params[:slide_id]
        # FIXME, slid_id security check?!
        @slides = Array(Slide.find(params[:slide_id]))
      else
        @slides = @channel.slides
      end
    else
      @slides = Array.new
      slide = Slide.new
      slide.body = t('display_non_active_body')
      slide.template = "only_text"
      @slides.push slide
    end

    @slides.each do |slide|
      slide.slide_html = slide_to_screen_html(params[:resolution], slide)
    end

    respond_with(@slides) do |format|
      format.json do 
        render :json => @slides.to_json( :only => [:id, :status],
                                         :methods => [:slide_html, :timers, :slide_delay])
      end
    end
  end
  
  # JSON display control data.
  #
  # Sets poweroff and refresh timers. The timers are ordered in an array by weekday.
  #
  # Timers are configured in organisations.yml.
  # A change in the config requires server restart to become effective,
  # since Organisation model caches the configuration data.
  #
  # GET /display_ctrl.json?resolution=600x800
  def display_ctrl
    unless @display
      logger.warn "No display"
      render :nothing => true, :status => 400
      return
    end
    
    # Order timers_json by weekday.
    # This makes the result array a bit bigger to store in memory, but easier
    # for the JavaScript to parse on the client.
    timers = Organisation.current.value_by_key('control_timers')
    timers_json = [[],[],[],[],[],[],[]]
    unless timers
      logger.info "No control timers set in organisations.yml"
    else
      timers.each do |_t|
        # remove weekdays from the hash, and push the rest of the timer data
        # into the corresponding days in the timers_json,
        # a day can be either an integer (0-6) or "*".
        # when it is *, push this timer for each day of the week.
        timer = _t.dup # operate on a copy
        weekdays = timer.delete('weekdays')
        weekdays = (0..6) if weekdays=='*'
        weekdays.each{|day| timers_json[day].push(timer)}
      end
    end
    ctrl_json = {
      :hostname => session[:hostname],
      :timers => timers_json
      }
    #logger.debug ctrl_json.inspect
    render :json => ctrl_json.to_json
  end

  # GET /conductor?resolution=800x600&hostname=examplehost
  # GET /conductor?cache=false&slide_id=40
  # Main page for Iivari client
  def conductor
    @cache = true
    url_params = []

    # preview mode is activated when slide_id is given
    preview = params[:slide_id] ? true : false
    if params[:slide_id]
      url_params.push "slide_id=#{params[:slide_id]}"
    end
    if params[:resolution]
      url_params.push "resolution=#{params[:resolution]}"
    end
    if params[:cache] && params[:cache] == "false"
      @cache = false
    end
    if params[:channel_id]
      url_params.push "channel_id=#{params[:channel_id]}"
    end

    json_url = conductor_slides_url
    unless url_params.empty?
      json_url += "?" + url_params.join("&")
    end
    
    # Get data_update_interval from organisations.yml config file.
    # Config sets it in seconds, JavaScript needs it in msec.
    # Default is 24 hours.
    data_update_interval =
      ( Organisation.current.value_by_key('data_update_interval') || 60 * 60 * 24 ) * 1000
    
    # The interval to fetch the display control JSON data
    ctrl_update_interval =
      ( Organisation.current.value_by_key('control_update_interval') || 60 * 60 * 24 ) * 1000

    # Locale for screen footer timestamp
    locale = Organisation.current.value_by_key('locale')

    # Backbone session - published to client javascript
    @session_json = {
      :json_url => json_url,
      :ctrl_url => conductor_display_ctrl_url,
      :data_update_interval => data_update_interval,
      :ctrl_update_interval => ctrl_update_interval,
      :cache => @cache,
      :preview => preview,
      :locale => locale
    }.to_json

    @manifest_url = manifest_screen_path(:resolution => params[:resolution])

    # Footer theme - default "gold"
    @theme = @channel.theme if @channel
    @theme ||= "gold"

    respond_to do |format|
      format.html
    end
  end

  # Manifest
  #
  # Compiles a dynamic HTML5 manifest file for the client.
  # This enables the client to work without a network connection
  # once it has cached all assets onto its local hard drive.
  #
  # Clients get the manifest url when they request conductor.
  # Without a session cookie, the conductor response will be 
  # redirect 302, and iivari-client does not cache the page.
  # Therefore the conductor path is explicitly added to the manifest.
  # The order of parameters has to match exactly the same
  # as on the client, so conductor_screen_path helper cannot be used.
  #
  # The client updates the local cache only when the manifest
  # contents have changed.
  # In production, the assets should be precompiled using the built-in
  # rake task "assets:precompile" that calculates a digest checksum
  # for each asset file. When the file contents change, the digest will
  # be different. The task writes a manifest.yml file that contains
  # the current digest of each file.
  # In development, only slide images will be cached.
  #
  # NOTE: if even a single file in the manifest is not found,
  # ALL FILES IN THE MANIFEST ARE DISCARDED!
  #
  # GET /screen.manifest?resolution=800x600
  def manifest
    body = ["CACHE MANIFEST"]
    body << "CACHE:"
    # Production mode offline caching
    if Rails.env == "production"
      # Cache client JS and CSS with digest checksum.
      begin
        digests = YAML.load((
          Iivari::Application.config.assets.manifest || Rails.root.join("public/assets")
        ).join("manifest.yml").read)
        # The dependencies (jQuery, underscore, etc) are bundled into client.js.
        %w{
          client.js
          client.css
        }.each do |asset|
          body << root_path+"assets/#{digests[asset]}"
        end
      rescue
        logger.error $!
        logger.warn "Client is unable to use offline cache!"
      end
    # Development mode offline caching
    elsif Iivari::Application.config.assets.debug == false
      %w{
        client.js
        client.css
      }.each do |asset|
        body << root_path+"assets/#{asset}"
      end
    else
      logger.info "Offline caching is disabled - enable it in development mode by setting config.assets.debug = false"
    end

    # Cache conductor.
    body << root_path + "conductor?resolution=#{params[:resolution]}&hostname=#{session[:hostname]}"

    # Cache offline icon.
    body << root_path+"assets/offline.png"

    # Cache slide images.
    Slide.image_urls(@channel, params[:resolution]).each do |url|
      body << root_path + url
    end

    # Use network for any other request.
    body << ""
    body << "NETWORK:"
    body << "/"
    body << ""

    render :text => body.join("\n"), :content_type => "text/cache-manifest"
  end

  # The ping action is for clients to check for network / server
  # status to display "connectivity error" unless a response is received.
  #
  # HEAD /ping
  def ping
    render :text => ''
  end

  # GET /image/only_image/e59e7f6a488088e675b3736681abf2ef55ce69d28360903cb56fa8cfb69c9155?resolution=800x600
  def image
    expires_in 15.minutes, :public => true
    begin
      if image = Image.find_by_key(params[:image])
        # show original gif images, so gif animations
        # can be shown on the client
        if image.content_type == 'image/gif'
          data_string = image.original_data
        else
          data_string = image.data_by_resolution(params[:template], params[:resolution])
        end
        # FIXME image name?
        send_data data_string, :filename => image.key, :type => image.content_type, :disposition => 'inline'
        return
      end
    rescue
      # Error 404 would cause cache manifest to fail,
      # all exceptions should be caught.
      logger.warn $!.message
    end
    render :nothing => true
  end

  # GET /displayauth?resolution=1366x768&hostname=infotv-01
  def displayauth
    respond_to do |format|
      if params[:hostname]
        session[:display_authentication] = true 
        session[:hostname] = params[:hostname] if params[:hostname]
        format.html { redirect_to conductor_screen_path( :resolution => params[:resolution] ) }
      else
        format.html { render :inline => "Unauthorized", :status => :unauthorized }
      end
    end
  end

  private

  def slide_to_screen_html(resolution, slide)
    @resolution = resolution
    @slide = slide
    # Slide may be the "display_non_active_body" when
    # display is inactive or no channel is set.
    # Use default theme "gold".
    theme = 
      (@slide.channel and @slide.channel.theme?) ? 
        @slide.channel.theme : "gold"
    render_to_string("client_#{slide.template}.html.erb",
      :layout => "slide",
      :locals => {:theme => theme})
  end

  def auth_require
    if preview?
      require_user
      @channel = Channel.find(params[:channel_id]) if params[:channel_id]
      @channel = Slide.find(params[:slide_id]).channel if params[:slide_id]
    else
      if session[:display_authentication]
        logger.info "Display #{session["hostname"]}, session_id #{session["session_id"]}"
        @display = Display.find_or_create_by_hostname(session[:hostname])
        @channel = @display.active ? @display.channel : nil
      else
        respond_to do |format|
          format.html { redirect_to display_authentication_path( :resolution => params[:resolution],
                                                                 :hostname => params[:hostname] ) }
          format.json { render :json => "Unauthorized", :status => :unauthorized }
        end
      end
    end
  end

  def preview?
    session.has_key?(:user_credentials) ? true : false
  end

  def persist_session
    request.env["rack.session.options"][:expire_after] = 20.years if session[:display_authentication]
  end

  # timestamp of client update request, issue #4
  def log_last_seen_at
    return unless @display
    @display.last_seen_at = Time.now
    @display.save
  end
end
