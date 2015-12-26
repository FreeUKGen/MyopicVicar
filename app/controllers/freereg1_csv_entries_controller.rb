class Freereg1CsvEntriesController < ApplicationController
  require 'chapman_code'
  require 'freereg_validations'

  skip_before_filter :require_login, only: [:show]
  def index
    display_info
    @freereg1_csv_entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => @freereg1_csv_file_id ).all.order_by(file_line_number: 1)

  end

  def show
    @freereg1_csv_entry = Freereg1CsvEntry.id(params[:id]).first
    if @freereg1_csv_entry.present?
      get_user_info_from_userid
      session[:freereg1_csv_entry_id] = @freereg1_csv_entry._id
      display_info
      @forenames = Array.new
      @surnames = Array.new
    else
      go_back("entry",params[:id])
    end
  end

  def error
    @error_file = BatchError.id(params[:id]).first
    if @error_file.present?
      get_user_info_from_userid
      session[:error_id] = params[:id]
      set_up_error_display
      if @freereg1_csv_file.nil?
        flash[:notice] = "The error appears to have become disconnected from it file. Contact system administration"
        redirect_to :action => 'show'
        return
      end
    else
      go_back("error",params[:id])
    end
  end

  def create
    get_user_info_from_userid
    @user = UseridDetail.where(:userid => session[:userid]).first
    @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
    params[:freereg1_csv_entry][:record_type] =  @freereg1_csv_file.record_type
    params[:freereg1_csv_entry][:year] = get_year(params[:freereg1_csv_entry])
    @freereg1_csv_entry = Freereg1CsvEntry.new(params[:freereg1_csv_entry])
    unless session[:error_id].nil?
      error_file = @freereg1_csv_file.batch_errors.find( session[:error_id])
      file_line_number = error_file.record_number
      line_id = error_file.data_line[:line_id]
    else
      file_line_number = @freereg1_csv_file.records.to_i + 1
      line_id = @freereg1_csv_file.userid + "." + @freereg1_csv_file.file_name.upcase + "." +  file_line_number.to_s
      @freereg1_csv_file.update_attributes(:record => file_line_number)
    end
    @freereg1_csv_entry.update_attributes(:line_id => line_id,:record_type  => @freereg1_csv_file.record_type, :file_line_number => file_line_number)
    #need to deal with change in place
    unless @freereg1_csv_file.register.church.place.place_name == params[:freereg1_csv_entry][:place]
      #need to think about how to do this
    end
    church =  @freereg1_csv_file.register.church
    place = church.place
    @freereg1_csv_entry.church_name = church.church_name
    @freereg1_csv_entry.place = place.place_name
    @freereg1_csv_entry.county = place.county
    @freereg1_csv_file.freereg1_csv_entries << @freereg1_csv_entry
    @freereg1_csv_entry.save
    @freereg1_csv_file.calculate_distribution

    if @freereg1_csv_entry.errors.any?
      flash[:notice] = 'The creation of the record was unsuccessful'
      display_info
      render :action => 'error'
      return
    else
      @freereg1_csv_entry.transform_search_record
      @freereg1_csv_file.backup_file
      #update file with date and lock and delete error
      @freereg1_csv_file.lock_all(session[:my_own])
      @freereg1_csv_file.modification_date = Time.now.strftime("%d %b %Y")

      if session[:error_id].nil?
        @freereg1_csv_file.records = @freereg1_csv_file.records.to_i + 1
        @freereg1_csv_file.calculate_date(params)
      else
        @freereg1_csv_file.error =  @freereg1_csv_file.error - 1
        @freereg1_csv_file.batch_errors.delete( @freereg1_csv_file.batch_errors.find(session[:error_id]))
      end
      display_info
      @freereg1_csv_file.save
      if  @freereg1_csv_file.errors.any?
        flash[:notice] = 'The update in entry data distribution contents was unsuccessful'
        redirect_to :action => 'error'
        return
      else
        session[:error_id] = nil
        flash[:notice] = 'The creation/update in entry contents was successful, backup of file made and locked'
        render :action => 'show'
        return
      end
    end
  end

  def new
    session[:error_id] = nil
    display_info
    file_line_number = @freereg1_csv_file.records.to_i + 1
    line_id = @freereg1_csv_file.userid + "." + @freereg1_csv_file.file_name.upcase + "." +  file_line_number.to_s
    @freereg1_csv_entry = Freereg1CsvEntry.new(:record_type  => @freereg1_csv_file.record_type, :line_id => line_id, :file_line_number => file_line_number )
    @freereg1_csv_entry.multiple_witnesses.build
  end

  def edit
    @freereg1_csv_entry = Freereg1CsvEntry.id(params[:id]).first
    if @freereg1_csv_entry.present?
      session[:freereg1_csv_entry_id] = @freereg1_csv_entry._id
      display_info
      @freereg1_csv_entry.multiple_witnesses.build
    else
      go_back("entry",params[:id])
    end
  end

  def update
    @freereg1_csv_entry = Freereg1CsvEntry.id(params[:id]).first
    if @freereg1_csv_entry.present?
      @freereg1_csv_file = @freereg1_csv_entry.freereg1_csv_file
      params[:freereg1_csv_entry][:record_type] =  @freereg1_csv_file.record_type
      params[:freereg1_csv_entry][:year] = get_year(params[:freereg1_csv_entry])
      #see if we need to recalculate search record
      recreate_search_record = Freereg1CsvEntry.detect_change(params[:freereg1_csv_entry],@freereg1_csv_entry.attributes)
      #update entry
      @freereg1_csv_entry.update_attributes(params[:freereg1_csv_entry])
      if @freereg1_csv_entry.errors.any?
        flash[:notice] = 'The update of the record was unsuccessful'
        render :action => 'edit'
        return
      else
        #update search record if there is a change
        @freereg1_csv_entry.update_search_record if recreate_search_record
        # lock file and note modification date
        @freereg1_csv_file.locked_by_transcriber = true if session[:my_own]
        @freereg1_csv_file.locked_by_coordinator = true unless session[:my_own]
        @freereg1_csv_file.modification_date = Time.now.strftime("%d %b %Y")
        @freereg1_csv_file.save
        @freereg1_csv_file.calculate_distribution
        flash[:notice] = 'The change in entry contents was successful, the file is now locked against replacement until it has been downloaded.'
        redirect_to freereg1_csv_entry_path(@freereg1_csv_entry) 
      end
    else
      go_back("entry",params[:id])
    end


  end

  def destroy
    @freereg1_csv_entry = Freereg1CsvEntry.id(params[:id]).first
    if @freereg1_csv_entry.present?
      freereg1_csv_file = @freereg1_csv_entry.freereg1_csv_file
      freereg1_csv_file.freereg1_csv_entries.delete(@freereg1_csv_entry)
      freereg1_csv_file.calculate_distribution
      freereg1_csv_file.recalculate_last_amended
      freereg1_csv_file.update_number_of_files
      flash[:notice] = 'The deletion of the record was successful'
      redirect_to freereg1_csv_file_path(freereg1_csv_file)
      return
    else
      go_back("entry",params[:id])
    end
  end

  def set_up_error_display
    @freereg1_csv_file = @error_file.freereg1_csv_file

    @error_file.data_line[:record_type] = @error_file.record_type
    @freereg1_csv_entry = Freereg1CsvEntry.new(@error_file.data_line)
    @error_line = @error_file.record_number
    @error_message = @error_file.error_message
    @place_names = Array.new
    Place.where(:chapman_code => session[:chapman_code], :disabled.ne => "true").all.each do |place|
      @place_names << place.place_name
    end
     @freereg1_csv_file_name =  @freereg1_csv_file.file_name
    @file_owner = @freereg1_csv_file.userid
    @register = @freereg1_csv_file.register
    @register_name = RegisterType.display_name(@register.register_type)
    @church = @register.church #id?
    @church_name = @church.church_name
    @place = @church.place #id?
    @county =  @place.county
    @place_name = @place.place_name
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first unless session[:userid].nil?
  end

  def display_info
    if @freereg1_csv_entry.nil?
      @freereg1_csv_file = Freereg1CsvFile.id(session[:freereg1_csv_file_id]).first
    else
      @freereg1_csv_file = @freereg1_csv_entry.freereg1_csv_file
    end

    @freereg1_csv_file_id =  @freereg1_csv_file.id
    @freereg1_csv_file_name =  @freereg1_csv_file.file_name
    @file_owner = @freereg1_csv_file.userid
    @register = @freereg1_csv_file.register
    #@register_name = @register.register_name
    #@register_name = @register.alternate_register_name if @register_name.nil?
    @register_name = RegisterType.display_name(@register.register_type)
    @church = @register.church #id?
    @church_name = @church.church_name
    @place = @church.place #id?
    @county =  @place.county
    @place_name = @place.place_name
    @first_name = session[:first_name]
    @user = UseridDetail.where(:userid => session[:userid]).first unless session[:userid].nil?
  end

  def get_year(param)
    case param[:record_type]
    when "ba"
      year = FreeregValidations.year_extract(param[:baptism_date]) if  param[:baptism_date].present?
      year = FreeregValidations.year_extract(param[:birth_date]) if param[:birth_date].present? && year.blank?
    when "bu"
      year = FreeregValidations.year_extract(param[:burial_date]) if  param[:burial_date].present?
    when "ma"
      year = FreeregValidations.year_extract(param[:marriage_date]) if  param[:marriage_date].present?
    end
    year
  end

end
