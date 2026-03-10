class TransregCsvfilesController < ApplicationController

  protect_from_forgery :except => [:upload, :replace, :delete]

  # Should re-authenticate the userid/password provided with the request
  # No guarantee that the userid is the same as that used when the logon happened
  before_action :authenticate_user

  def upload
    if params[:csvfile].blank? || params[:csvfile][:csvfile].blank?
      render(:text => {"result" => "fail", "message" => "You must select a file"}.to_xml({:dasherize => false, :root => 'upload'}))
      return
    end
    p 'valid user'
    @csvfile  = Csvfile.new(csvfile_params)
    @csvfile.userid = params[:transcriberid]
    @csvfile.file_name = @csvfile.csvfile.identifier
    uploaded_file = params[:csvfile][:csvfile].tempfile.path

    #lets check for existing file, save if required
    processing_time = @csvfile.estimate_time
    proceed = @csvfile.check_for_existing_file_and_save
    logger.warn("#{appname_upcase}:UPLOAD: About to save file #{proceed}")
    @csvfile.save if proceed

    if @csvfile.errors.any? || !proceed
      @result = "failure"
      @message = "The upload with file name #{@csvfile.file_name} was unsuccessful because #{@csvfile.errors.messages}"
      logger.warn("#{appname_upcase}:UPLOAD: The upload with file name #{@csvfile.file_name} was unsuccessful because #{@csvfile.errors.messages}")
    else
      batch = @csvfile.create_batch_unless_exists
      batch_processing = PhysicalFile.where(:userid => @csvfile.userid, :file_name => @csvfile.file_name,:waiting_to_be_processed => true).first
      if batch_processing.present?
        @result = "failure"
        @message = "Your file is currently waiting to be processed. It cannot be processed this way now"
        logger.warn("#{appname_upcase}:CSV_FAILURE: Attempt to double process #{@csvfile.userid} #{@csvfile.file_name}")
        @csvfile.delete
      else
        range = File.join(@csvfile.userid,@csvfile.file_name)
        logger.warn("#{appname_upcase}:UPLOAD: About to process the file #{processing_time}")
        case
        when session[:role] == "trainee"
          @result = "success"

          Rails.logger.info "[transreg_csvfiles_controller] trainee: spawn rake build:freereg_new_update"
          pid1 = Kernel.spawn("rake build:freereg_new_update[\"no_search_records\",\"individual\",\"no\",#{range}]")
          @message =  "The csv file #{ @csvfile.file_name} is being checked. You will receive an email when it has been completed."
        when processing_time < 600
          batch.update_attributes(:waiting_to_be_processed => true, :waiting_date => Time.now)
          #check to see if rake task running
          rake_lock_file = File.join(Rails.root,"tmp","processing_rake_lock_file.txt")
          processor_initiation_lock_file = File.join(Rails.root,"tmp","processor_initiation_lock_file.txt")
          pid1 = Kernel.spawn("rake build:freereg_new_update[\"create_search_records\",\"waiting\",\"no\",\"a-9\"]")
          @message =  "The csv file #{ @csvfile.file_name} has been sent for processing . You will receive an email when it has been completed."
          #f = File.open(rake_lock_file, File::CREAT)
          #if f.flock(File::LOCK_SH) || File.exist?(processor_initiation_lock_file)
            #logger.warn("#{appname_upcase}:CSV_PROCESSING: rake lock file #{rake_lock_file} or processor_initiation_lock_file #{processor_initiation_lock_file} already exists")
            #@result = "success"
            #@message =  "The csv file #{ @csvfile.file_name} has been sent for processing . You will receive an email when it has been completed."
          #else
            #@result = "success"
            #logger.warn("#{appname_upcase}:CSV_PROCESSING: Initiating rake task for #{@csvfile.userid} #{@csvfile.file_name}")
            #initiation_locking_file = File.new(processor_initiation_lock_file, "w")
            #logger.warn("#{appname_upcase}:CSV_PROCESSING: Created processor_initiation_lock_file #{processor_initiation_lock_file}")
            #pid1 = Kernel.spawn("rake build:freereg_new_update[\"create_search_records\",\"waiting\",\"no\",\"a-9\"]")
            #@message =  "The csv file #{ @csvfile.file_name} is being processed . You will receive an email when it has been completed."
          #end
        when processing_time >= 600
          @result = "failure"
          batch.destroy
          #batch.update_attributes(:base => true,:base_uploaded_date => Time.now,:file_processed => false)
          @message =  "The file has been queued it is too large to be processed normally. The data manager has been informed and will discuss with you how it may be scheduled for processing. "
          UserMailer.report_to_data_manger_of_large_file( @csvfile.file_name,@csvfile.userid).deliver_now
        end
      end
    end #errors

    render(:text => {"result" => @result, "message" => @message}.to_xml({:dasherize => false, :root => 'upload'}))
  end

  def replace
    p 'valid user'

    @csvfile  = Csvfile.new(csvfile_params)
    @csvfile.userid = params[:transcriberid]
    @csvfile.file_name = @csvfile.csvfile.identifier
    uploaded_file = params[:csvfile][:csvfile].tempfile.path
    dest_file = File.join(Rails.application.config.datafiles, params[:transcriberid], params[:csvfile][:csvfile].original_filename)
    p @csvfile

    #    name_ok = @csvfile.check_name(session[:file_name])
    #    if !name_ok
    #      p session[:file_name]
    #      p session

    #      @result = 'failure'
    #      @message = 'The file you are replacing must have the same name'
    #      render(:text => {"result" => @result, "message" => @message}.to_xml({:dasherize => false, :root => 'replace'}))
    #      session.delete(:file_name)
    #      return
    #    end

    setup = @csvfile.setup_batch_on_replace
    if !setup[0]
      @result = 'failure'
      @message = setup[1]
      render(:text => {"result" => @result, "message" => @message}.to_xml({:dasherize => false, :root => 'replace'}))
      session.delete(:file_name)
      return
    end

    batch = setup[1]

    #lets check for existing file, save if required
    proceed = @csvfile.check_for_existing_file_and_save
    logger.warn("FREEREG:REPLACE: About to save file #{proceed}")

    @csvfile.save if proceed
    if @csvfile.errors.any? || !proceed
      @result = "failure"
      @message = "The upload with file name #{@csvfile.file_name} was unsuccessful because #{@csvfile.errors.messages}"
      logger.warn("FREEREG:UPLOAD: The upload with file name #{@csvfile.file_name} was unsuccessful because #{@csvfile.errors.messages}")
    else
      batch = @csvfile.create_batch_unless_exists
      batch_processing = PhysicalFile.where(:userid => @csvfile.userid, :file_name => @csvfile.file_name,:waiting_to_be_processed => true).first
      if batch_processing.present?
        @result = "failure"
        @message = "Your file is currently waiting to be processed. It cannot be processed this way now"
        logger.warn("FREEREG:CSV_FAILURE: Attempt to double process #{@csvfile.userid} #{@csvfile.file_name}")
        @csvfile.delete
      else
        processing_time = @csvfile.estimate_time
        range = File.join(@csvfile.userid,@csvfile.file_name)
        logger.warn("FREEREG:UPLOAD: About to process the file #{processing_time}")
        case
        when session[:role] == "trainee"
          @result = "success"

          Rails.logger.info "[transreg_csvfiles_controller] trainee: spawn rake build:freereg_new_update"
          pid1 = Kernel.spawn("rake build:freereg_new_update[\"no_search_records\",\"individual\",\"no\",#{range}]")
          @message =  "The csv file #{ @csvfile.file_name} is being checked. You will receive an email when it has been completed."
        when processing_time < 600
          batch.update_attributes(:waiting_to_be_processed => true, :waiting_date => Time.now)
          #check to see if rake task running
          rake_lock_file = File.join(Rails.root,"tmp","processing_rake_lock_file.txt")
          if File.exist?(rake_lock_file)
            @result = "success"
            logger.warn("FREEREG:CSV_PROCESSING: rake lock file #{rake_lock_file} already exists")
            @message =  "The csv file #{ @csvfile.file_name} has been sent for processing . You will receive an email when it has been completed."
          else
            @result = "success"
            logger.warn("FREEREG:CSV_PROCESSING: Starting rake task for #{@csvfile.userid} #{@csvfile.file_name}")
            pid1 = Kernel.spawn("rake build:freereg_new_update[\"create_search_records\",\"waiting\",\"no\",\"a-9\"]")
            @message =  "The csv file #{ @csvfile.file_name} is being processed . You will receive an email when it has been completed."
          end
        when processing_time >= 600
          @result = "failure"
          batch.update_attributes(:base => true,:base_uploaded_date => Time.now,:file_processed => false)
          @message =  "The file has been queued it is too large to be processed normally. The data manager has been informed and will discuss with you how it may be scheduled for processing. "
          UserMailer.report_to_data_manger_of_large_file( @csvfile.file_name,@csvfile.userid).deliver_now
        end
      end
    end #error
    render(:text => {"result" => @result, "message" => @message}.to_xml({:dasherize => false, :root => 'replace'}))
  end

  def delete
    p 'valid user'

    #this just removes a batch of records
    @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
    if @freereg1_csv_file.present?

      p @freereg1_csv_file.locked_by_transcriber
      p @freereg1_csv_file.locked_by_coordinator

      ok_to_proceed = @freereg1_csv_file.check_file
      if !ok_to_proceed[0]
        render(:text => { "result" => "failure", "message" => "There is a problem with the file you are attempting to download. Contact a system administrator if you are concerned."}.to_xml({:root => 'delete'}))
      else
        set_controls(@freereg1_csv_file)

        if @freereg1_csv_file.locked_by_transcriber  ||  @freereg1_csv_file.locked_by_coordinator
          @message = "The removal of the batch #{@freereg1_csv_file.file_name} was unsuccessful; the batch is locked."
          render(:text => { "result" => "failure", "message" => @message}.to_xml({:root => 'delete'}))
          return
        end
        @freereg1_csv_file.add_to_rake_delete_list
        @physical_file.update_attributes(:file_processed =>false, :file_processed_date => nil) if Freereg1CsvFile.where(:file_name => @freereg1_csv_file.file_name, :userid => @freereg1_csv_file.userid).count >= 1
        @freereg1_csv_file.save_to_attic
        @freereg1_csv_file.delete
        @message = "File #{@freereg1_csv_file.file_name} removed"
        render(:text => {"result" => "success", "message" => @message}.to_xml({:dasherize => false, :root => 'delete'}))
      end
    else
      @message = "The file #{@freereg1_csv_file.file_name} that you want to delete does not exist"
      render(:text => { "result" => "failure", "message" => @message}.to_xml({:root => 'delete'}))
    end
  end

  private

  def authenticate_user
    @transcriber_id = params[:transcriberid]
    @transcriber_password = params[:transcriberpassword]
    @user = UseridDetail.where(:userid => @transcriber_id).first

    if @user.nil? then
      render(:text => { "result" => "unknown_user" }.to_xml({:root => 'authentication'}))
      return
    else
      password = Devise::Encryptable::Encryptors::Freereg.digest(@transcriber_password,nil,nil,nil)
      if password != @user.password then
        render(:text => { "result" => "no_match" }.to_xml({:root => 'authentication'}))
        return
      end
    end
  end

  def set_controls(file)
    display_info
    @physical_file = PhysicalFile.userid(file.userid).file_name(file.file_name).first
    @role = session[:role]
    @freereg1_csv_file_name = file.file_name
    session[:freereg1_csv_file_id] =  file._id
    @return_location  = file.register.id
  end

  def display_info
    @freereg1_csv_file_id =   @freereg1_csv_file._id
    @freereg1_csv_file_name = @freereg1_csv_file.file_name
    @register = @freereg1_csv_file.register
    if @register.blank?
      go_back("register",@freereg1_csv_file)
    end
    @file_owner = @freereg1_csv_file.userid
    @register_name = RegisterType.display_name(@register.register_type)
    @church = @register.church
    if @church.blank?
      go_back("church",@register)
    end
    @church_name = @church.church_name
    @place = @church.place
    if @place.blank?
      go_back("place", @church)
    end
    @county =  @place.county
    @place_name = @place.place_name
  end
  def go_back(type,record)
    flash[:notice] = "The #{type} document you are trying to access does not exist."
    logger.info "#{appname_upcase}:ACCESS ISSUE: The #{type} document #{record} being accessed does not exist."
    redirect_to main_app.new_manage_resource_path
    return
  end

  private
  def csvfile_params
    params.require(:csvfile).permit!
  end

end
