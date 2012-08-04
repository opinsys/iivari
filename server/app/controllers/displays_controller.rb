class DisplaysController < ApplicationController
  filter_access_to( :all,
                    :attribute_check => true,
                    :load_method => lambda { @school } )

  # GET /displays
  # GET /displays.xml
  def index
    @displays = Display.find_all_by_school_id(@school.puavo_id, puavo_api)
    respond_with(@displays)
  end

  # GET /displays/1
  # GET /displays/1.xml
  def show
    @display = Display.find(params[:id])
    respond_with(@display)
  end

  # GET /displays/new
  # GET /displays/new.xml
  def new
    @display = Display.new
    respond_with(@display)
  end

  # GET /displays/1/edit
  def edit
    @display = Display.find(params[:id])
    # available channels to select
    @channels = [[t("displays.edit.no_channel"), 0]]
    Channel.all(:order => :name).map{
      |ch| @channels << [ch.name, ch.id]}
  end

  # POST /displays
  # POST /displays.xml
  def create
    @display = Display.new(params[:display])
    @display.save
    respond_with(@display)
  end

  # PUT /displays/1
  # PUT /displays/1.xml
  def update
    @display = Display.find(params[:id])
    @display.update_attributes(params[:display])
    if params[:channels]
      # update channels, position by input order.
      # update_attributes does not seem to work with
      # acts_as_list join table
      channels = params[:channels].collect { |id|
        Channel.find(id) unless id.to_i == 0}.compact
      # assign channels, it is important to clear the
      # association first!!
      @display.channels = []
      @display.channels = channels
    end
    respond_with(@display) do |format|
      format.html { redirect_to display_path(@school.puavo_id, @display) }
    end
  end

  # DELETE /displays/1
  # DELETE /displays/1.xml
  def destroy
    @display = Display.find(params[:id])
    @display.destroy
    respond_with(@display)
  end
end
