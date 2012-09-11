class ChannelsController < ApplicationController
  filter_access_to :welcome, :attribute_check => false
  filter_access_to( :index, :new, :create,
                    :attribute_check => true,
                    :load_method => lambda { Channel.new(:school_id => @school.puavo_id) } )
  filter_access_to( :update, :edit, :destroy, :show,
                    :attribute_check => true )
  filter_access_to( :doc_upload, :doc_upload_progress,
                    :attribute_check => false )


  def welcome
    if current_user.role_symbols.include?(:organisation_owner)
      path = channels_path(@schools.first.puavo_id)
    else
      path = channels_path(current_user.admin_of_schools.first)
    end

    respond_to do |format|
      format.html { redirect_to path }
    end
  end

  # GET /channels
  # GET /channels.xml
  def index
    @channels = Channel.with_permissions_to(:show).find_all_by_school_id(@school.puavo_id)
    respond_with(@channels)
  end

  # GET /channels/1
  # GET /channels/1.xml
  def show
    @channel = Channel.with_permissions_to(:show).find(params[:id])
    respond_with(@channel)
  end

  # GET /channels/new
  # GET /channels/new.xml
  def new
    @channel = Channel.new
    @channel.slide_delay = 15

    respond_with(@channel)
  end

  # GET /channels/1/edit
  def edit
    @channel = Channel.with_permissions_to(:edit).find(params[:id])
  end

  # POST /channels
  # POST /channels.xml
  def create
    @channel = Channel.new(params[:channel])
    @channel.theme = "gold"
    @channel.school_id = @school.puavo_id
    @channel.save
    respond_with(@channel) do |format|
      format.html{ redirect_to( channel_path(@school.puavo_id, @channel) ) }
    end
  end

  # PUT /channels/1
  # PUT /channels/1.xml
  def update
    @channel = Channel.with_permissions_to(:update).find(params[:id])
    @channel.update_attributes(params[:channel])

    respond_with(@channel) do |format|
      format.html{ redirect_to( channel_path(@school.puavo_id, @channel) ) }
    end
  end

  # DELETE /channels/1
  # DELETE /channels/1.xml
  def destroy
    @channel = Channel.with_permissions_to(:destroy).find(params[:id])
    @channel.destroy
    respond_with(@channel)
  end


  # Receives document upload to create slides from its pages.
  #
  # The document is stored onto local disk, and a background
  # rake task "iivari:docsplit" is called to do the
  # long-running job with docsplit.
  # DocsplitTask is sql-backed job queue.
  # Action #doc_upload_progress responds with the job status
  # to ajax requests. The channel_slides page updates itself
  # when the task is finished.
  #
  # GET /channels/1/doc_upload
  # POST /channels/1/doc_upload?channel[document]=<UploadedFile>
  def doc_upload
    @channel = Channel.with_permissions_to(:update).find(params[:channel_id])
    if request.post?
      begin
        document = params[:channel][:document]
        # input file validations
        raise "No uploaded document" unless document
        data = document.read
        raise "File is empty" unless data

        # copy tempfile, as the uploaded temp file will be removed
        # automatically after a response is sent
        document_dir = File.join(
          "slide_documents",
          "channel_#{@channel.id}")
        FileUtils.mkdir_p(document_dir)
        tempfile = File.join(document_dir, document.original_filename)
        File.open( tempfile, "wb") { |f| f.write(data) }

        # add task to database
        @task = DocsplitTask.create(
          :channel_id => @channel.id,
          :document_file_path => tempfile,
          :original_file_name => document.original_filename
          )

        # run task
        system "rake iivari:docsplit RAILS_ENV=#{Rails.env} --trace 2>&1 >> #{Rails.root}/log/rake.log &"

        respond_with(@channel) do |format|
          format.html do
            redirect_to( channel_slides_path(@school.puavo_id, @channel) )
          end
          format.json do
            {:task_id => @task.id}.to_json
          end
        end

      rescue
        logger.error $!
        render :json => {:error => $!.message}, :status => 409
      end
      return
    end
  end

  # The status of current docsplit task on the channel.
  #
  # Returns status "resolved" when no tasks are found.
  # Returns "pending" when there is, along with estimated
  # progress percentage.
  # Responses are in JSON format.
  #
  # GET /:school_id/channels/1/slides/doc_upload_progress
  def doc_upload_progress
    unless request.xhr?
      render :text => "", :status => 409
      return
    end

    @channel = Channel.with_permissions_to(:read).find(params[:channel_id])
    begin
      task = DocsplitTask.first :conditions => {
        :channel_id => @channel.id,
        :pending => true
      }
      response = task ?
        {:status => "pending", :progress => task.progress} :
        {:status => "resolved"}
      render :json => response.to_json

    rescue
      logger.error $!
      render :json => {:error => $!.message}, :status => 409
    end
  end
end
