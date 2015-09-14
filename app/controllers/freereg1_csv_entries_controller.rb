class Freereg1CsvEntriesController < ApplicationController
  require 'chapman_code'
  require 'freereg_validations'
  skip_before_filter :require_login, only: [:show]
  def index
    if params[:page]
      session[:entry_index_page] = params[:page]
    end
    display_info
    #@freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
    @freereg1_csv_entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => @freereg1_csv_file_id ).all.order_by(file_line_number: 1).page(params[:page])
  end

  def show
    load(params[:id])
    @forenames = Array.new
    @surnames = Array.new

  end
  def error
    session[:error_id] = params[:id]
    display_info
    @error_file = @freereg1_csv_file.batch_errors.find(params[:id])
    @error_file.data_line[:record_type] = @error_file.record_type
    @freereg1_csv_entry = Freereg1CsvEntry.new(@error_file.data_line)
    @error_line = @error_file.record_number
    @error_message = @error_file.error_message
    @place_names = Array.new
    Place.where(:chapman_code => session[:chapman_code], :disabled.ne => "true").all.each do |place|
      @place_names << place.place_name
    end
  end
  def create
    @user = UseridDetail.where(:userid => session[:userid]).first
    @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
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

    if @freereg1_csv_entry.errors.any?
      flash[:notice] = 'The creation of the record was unsuccessful'
      display_info
      render :action => 'error'
    else
      @freereg1_csv_entry.transform_search_record
      @freereg1_csv_file.backup_file
      #update file with date and lock and delete error
      @freereg1_csv_file.locked_by_transcriber = "true" if session[:my_own]
      @freereg1_csv_file.locked_by_coordinator = "true" unless session[:my_own]
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
    load(params[:id])
    @freereg1_csv_entry.multiple_witnesses.build
  end

  def update
    load(params[:id])
    params[:freereg1_csv_entry][:record_type] =  @freereg1_csv_file.record_type
    #see if we need to recalculate search record
    recreate_search_record = Freereg1CsvEntry.detect_change(params[:freereg1_csv_entry],@freereg1_csv_entry.attributes)
    #remove empty parameters
    params[:freereg1_csv_entry] = Freereg1CsvEntry.update_parameters(params[:freereg1_csv_entry],@freereg1_csv_entry)

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
      @freereg1_csv_file.locked_by_transcriber = "true" if session[:my_own]
      @freereg1_csv_file.locked_by_coordinator = "true" unless session[:my_own]
      @freereg1_csv_file.modification_date = Time.now.strftime("%d %b %Y")
      @freereg1_csv_file.save
      flash[:notice] = 'The change in entry contents was successful, the file is now locked against an upload'
      render :action => 'show'
    end
  end

  def select_page
    display_info
    @max = @freereg1_csv_file.records
  end
  def selected_page
    display_info
    @number = params[:number].to_i
    @number = @freereg1_csv_file.records.to_i if @number > @freereg1_csv_file.records.to_i
    @page_number = (@number/50).to_i
    @page_number =  (@page_number + 1)
    params[:page] = @page_number
    @freereg1_csv_entries = Freereg1CsvEntry.where(:freereg1_csv_file_id => @freereg1_csv_file_id ).order_by(file_line_number: 1).page(params[:page])
    render "index"
  end

  def load(entry_id)
    @freereg1_csv_entry = Freereg1CsvEntry.find(entry_id)
    session[:freereg1_csv_entry_id] = @freereg1_csv_entry._id
    display_info
  end
  def destroy
    load(params[:id])
    return_location = @freereg1_csv_entry.freereg1_csv_file
    @freereg1_csv_entry.destroy
    flash[:notice] = 'The deletion of the record was successful'
    redirect_to freereg1_csv_file_path(return_location)

  end

  def display_info
    if @freereg1_csv_entry.nil?
      @freereg1_csv_file = Freereg1CsvFile.find(session[:freereg1_csv_file_id])
    else
      @freereg1_csv_file = @freereg1_csv_entry.freereg1_csv_file
    end
    @freereg1_csv_file_id =  @freereg1_csv_file._id
    @freereg1_csv_file_name =  @freereg1_csv_file.file_name
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

end
