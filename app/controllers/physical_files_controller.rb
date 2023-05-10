# Copyright 2012 Trustees of FreeBMD
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
#
class PhysicalFilesController < ApplicationController
  def all_files
    get_user_info_from_userid
    @selection = 'all'
    @sorted_by = 'All files by userid then batch name'
    session[:sorted_by] = @sorted_by
    session[:who] = @selection
    session[:by_userid] = false
    @batches = PhysicalFile.all.order_by(userid: 1,batch_name: 1)
    @number =  @batches.length
    @number =  @batches.length
    @has_access = ((@user.person_role == 'data_manager') || (@user.person_role == 'system_administrator'))
    @paginate = true
    render 'index'
  end

  def create
    case
    when params[:commit] == 'Select Userid'
      # This is not the creation of a physical file but simply the selection of who and how to display the files
      if params[:physical_file][:type].present?
        session[:sorted_by] = params[:physical_file][:type]
        session[:who] = params[:physical_file][:userid]
        session[:by_userid] = true
        redirect_to action: 'index'
      else
        flash[:notice] = 'You must select a type'
        redirect_to action: 'files_for_specific_userid'
      end
    end
  end

  def destroy
    load(params[:id])
    redirect_back(fallback_location: { action: 'select_action' }) && return if @batch.blank?

    @batch.file_and_entries_delete if appname_downcase == 'freereg'
    @batch.freecen_csv_file_and_entries_delete(session[:userid]) if appname_downcase == 'freecen'
    @batch.delete
    flash[:notice] = 'The destruction of the physical files and all its entries and search records was successful'
    redirect_back(fallback_location: { action: 'select_action' }) && return
  end

  def download
    file = PhysicalFile.find(params[:id])
    redirect_back(fallback_location: { action: 'select_action' }, notice: 'No such file') && return if file.blank?

    my_file = File.join(Rails.application.config.datafiles, file.userid, file.file_name) if params[:loc] == 'FR2'
    my_file = File.join(Rails.application.config.datafiles_changeset, file.userid, file.file_name) if params[:loc] == 'FR1'
    redirect_back(fallback_location: { action: 'select_action' }, notice: 'There is a problem with the file you are attempting to download') && return unless File.file?(my_file)


    send_file(my_file, filename: file.file_name, x_sendfile: true) && return

    redirect_back(fallback_location: { action: 'select_action' }, notice: 'Downloaded')

  end

  def files_for_specific_userid
    get_user_info_from_userid
    @batch = PhysicalFile.new
    @users = UseridDetail.get_userids_for_selection('all')
    @options = ['All files', 'Not processed', 'Processed but no file', 'Waiting to be processed']
  end

  def file_not_processed
    @batches = PhysicalFile.uploaded_into_base.not_processed.all.order_by(base_uploaded_date: -1, userid: 1)
    @selection = 'all'
    @sorted_by = 'Not processed'
    session[:sorted_by] = @sorted_by
    @number = @batches.length
    @paginate = false
    @user = get_user
    session[:by_userid] = false
    session[:who] = @user.userid
    @has_access = ((@user.person_role == 'data_manager') || (@user.person_role == 'system_administrator'))
    render 'index'
  end

  def index
    session[:physical_index_page] = params[:page] if params[:page]
    session[:sorted_by].blank? ? @sorted_by = 'All files by userid then batch name' : @sorted_by = session[:sorted_by]
    get_user_info_from_userid
    @has_access = ((@user.person_role == 'data_manager') || (@user.person_role == 'system_administrator'))
    case
    when @sorted_by ==  'All files by userid then batch name' && @has_access && !session[:by_userid]
      @batches = PhysicalFile.all.order_by(userid: 1, file_name: 1)
      @number =  @batches.length
      @selection = 'all'
      @paginate = true
    when @sorted_by ==  'Not processed' && @has_access && !session[:by_userid]
      @batches = PhysicalFile.uploaded_into_base.not_processed.all.order_by(base_uploaded_date: -1, userid: 1)
      @number =  @batches.length
      @selection = 'all'
      @paginate = false
    when @sorted_by == 'All files' && @has_access && !session[:by_userid]
      @batches = PhysicalFile.all.order_by(userid: 1, base_uploaded_date: 1)
      @number =  @batches.length
      @selection = 'all'
      @paginate = true
    when @sorted_by == 'Processed but no file' && @has_access && !session[:by_userid]
      @batches = PhysicalFile.processed.not_uploaded_into_base.all.order_by(userid: 1, file_processed_date: 1)
      @number =  @batches.length
      @selection = 'all'
      @paginate = false
    when @sorted_by == 'Waiting to be processed' && @has_access && !session[:by_userid]
      @batches = PhysicalFile.waiting.all.order_by(waiting_date: -1)
      @number =  @batches.length
      @selection = 'all'
      @paginate = false
    when @sorted_by == 'Not processed' && session[:who].present?
      @batches = PhysicalFile.userid(session[:who]).uploaded_into_base.not_processed.all.order_by(base_uploaded_date: -1, userid: 1)
      @number =  @batches.length
      @selection = session[:who]
      @paginate = false
    when @sorted_by == 'All files' && session[:who].present?
      @batches = PhysicalFile.userid(session[:who]).all.order_by(userid: 1,base_uploaded_date: 1)
      @number =  @batches.length
      @selection = session[:who]
      @paginate = true
    when @sorted_by == 'Processed but no file' && session[:who].present?
      @batches = PhysicalFile.userid(session[:who]).processed.not_uploaded_into_base.all.order_by(userid: 1, file_processed_date: 1)
      @number =  @batches.length
      @selection = session[:who]
      @paginate = false
    when @sorted_by == 'Waiting to be processed' && session[:who].present?
      @batches = PhysicalFile.userid(session[:who]).waiting.all.order_by(waiting_date: -1)
      @number =  @batches.length
      @selection = session[:who]
      @paginate = false
    end
    @nature = 'all'
    respond_to do |format|
      format.html
      format.csv { send_data PhysicalFile.as_csv(@batches, @sorted_by, session[:who], session[:county]), filename: 'physical_file.csv' }
    end
  end

  def load(batch)
    @batch = PhysicalFile.find(batch)
  end

  def processed_but_no_file
    @sorted_by = 'Processed but no file'
    @selection = 'all'
    session[:by_userid] = false
    session[:sorted_by] = @sorted_by
    @batches = PhysicalFile.processed.not_uploaded_into_base.order_by(userid: 1, file_processed_date: 1).all
    @number =  @batches.length
    @paginate = false
    render 'index'
  end

  def remove
    load(params[:id])
    redirect_back(fallback_location: { action: 'select_action' }, notice: 'No such file') && return if @batch.blank?

    @batch.file_delete
    @batch.delete
    flash[:notice] = 'The physical files entry was removed'
    redirect_back(fallback_location: { action: 'select_action' }) && return
  end

  def reprocess
    @appname = appname_downcase
    case @appname
    when 'freereg'
      file = Freereg1CsvFile.find(params[:id])
    when 'freecen'
      file = FreecenCsvFile.find(params[:id])
    end
    redirect_back(fallback_location: { action: 'select_action' }, notice: 'No such file') && return if file.blank?

    redirect_back(fallback_location: { action: 'select_action' }, notice: 'File is currently awaiting processing and should not be edited') && return unless file.can_we_edit?

    #we write a new copy of the file from current on-line contents
    proceed, message = file.check_file

    redirect_back(fallback_location: { action: 'select_action' }, notice: "There is a problem with the file you are attempting to reprocess #{message}. Contact a system administrator if you are concerned.") && return unless proceed

    file.backup_file
    @batch = PhysicalFile.where(file_name: file.file_name, userid: file.userid).first
    redirect_back(fallback_location: { action: 'select_action' }, notice: "There is a problem with the file you are attempting to reprocess #{message}. Contact a system administrator if you are concerned.") && return if @batch.blank?

    #add to processing queue and place in change
    file.update_attributes(was_locked: true) if @appname == 'freecen' && file.locked_by_transcriber
    proceed, message = @batch.add_file('reprocessing')
    redirect_back(fallback_location: { action: 'select_action' }, notice: "There was a problem with the reprocessing: #{message} ") && return unless proceed

    @batch.save
    redirect_back(fallback_location: { action: 'select_action' }, notice: "The file #{@batch.file_name} for #{@batch.userid} has been submitted for processing") && return
  end

  def select_action
    clean_session
    clean_session_for_county
    clean_session_for_syndicate
    get_user_info_from_userid
    @batches = PhysicalFile.new
    @options = UseridRole::PHYSICAL_FILES_OPTIONS
    @prompt = 'Select Action?'
  end

  def show
    load(params[:id])
    redirect_back(fallback_location: { action: 'select_action' }, notice: 'No such file') && return if @batch.blank?

    get_user_info_from_userid
  end

  def sorted_by_base_uploaded_date(batches)
    batches = batches.sort { |a, b|
      cmp = a[:userid].downcase <=> b[:userid].downcase
      if cmp.zero? #same userid, sort by upload date
        if a[:base_uploaded_date].blank?
          if b[:base_uploaded_date].blank?
            0
          else
            -1
          end
        elsif b[:base_uploaded_date].blank?
          1
        else
          a[:base_uploaded_date] <=> b[:base_uploaded_date]
        end
      else
        cmp
      end
    }

    @paginate = false
    batches
  end

  def submit_for_processing
    load(params[:id])
    redirect_back(fallback_location: { action: 'select_action' }, notice: 'No such file') && return if @batch.blank?

    success = @batch.add_file(params[:loc])
    flash[:notice] = success[1]
    redirect_to physical_files_path(anchor: "#{@batch.id}", page: "#{session[:physical_index_page]}")
  end

  def waiting_to_be_processed
    @sorted_by = 'Waiting to be processed'
    session[:sorted_by] = @sorted_by
    @selection = 'all'
    session[:by_userid] = false
    session[:who] = @selection
    @batches = PhysicalFile.waiting.all.order_by(waiting_date: -1, userid: 1)
    @number =  @batches.length
    @paginate = false
    @user = get_user
    @has_access = ((@user.person_role == 'data_manager') || (@user.person_role == 'system_administrator'))
    render 'index'
  end
end
