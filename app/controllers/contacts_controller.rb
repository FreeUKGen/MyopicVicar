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
class ContactsController < ApplicationController

  require 'freereg_options_constants'
  require 'freebmd_contact_field_report'

  skip_before_action :require_login, only: [:new, :report_error, :create, :show, :question_answer_finder]

  def archive
    @contact = Contact.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: contacts_path, notice: 'The contact was not found') && return if @contact.blank?

    @contact.archive
    flash.notice = 'Contact archived'
    return_after_archive(params[:source], params[:id])
  end

  def contact_reply_messages
    @contact = Contact.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: contacts_path, notice: 'The contact was not found') && return if @contact.blank?

    get_user_info_from_userid
    @messages = Message.where(source_contact_id: params[:id]).all
    @links = false
    render 'messages/index'
  end

  def convert_to_issue
    @contact = Contact.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: contacts_path, notice: 'The contact was not found') && return if @contact.blank?

    if @contact.github_issue_url.blank?
      @contact.github_issue
      flash.notice = 'Issue created on Github.'
      redirect_to(contact_path(@contact.id)) && return
    else
      flash.notice = 'Issue had already been created on Github.'
      redirect_to(action: 'show') && return
    end
  end

  def create
    @contact = Contact.new(contact_params)
    if @contact.contact_name.blank? #spam trap
      @contact.previous_page_url = request.env['HTTP_REFERER']
      if @contact.selected_county == 'nil'
        @contact.selected_county = nil # string 'nil' to nil
      end
      if @contact.contact_type == 'Data Problem'
        merge_contact_body_for_data_problem
        assign_record_url_and_save
      end
      @contact.save
      if @contact.errors.any?
        flash[:notice] = [
          'There was a problem with your submission please review.',
          @contact.errors.full_messages.join(' ')
        ].join(' ')
        if @contact.contact_type == 'Data Problem'
          redirect_to(@contact.previous_page_url) && return
        else
          @options = FreeregOptionsConstants::ISSUES
          render :new
        end
      else
        flash[:notice] = 'Thank you for contacting us!'
        @contact.communicate_initial_contact
        if @contact.contact_type == 'Data Problem'
          redirect_to(contact_path(@contact.id)) && return
        elsif @contact.query
          redirect_to(search_query_path(@contact.query)) && return
        else
          redirect_to(new_search_query_path) && return
        end
      end
    end
  end

  def destroy
    @contact = Contact.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: contacts_path, notice: 'The contact was not found') && return if @contact.blank?

    @contact.delete
    flash.notice = 'Contact destroyed'
    redirect_to action: 'index'
  end

  def edit
    @contact = Contact.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: contacts_path, notice: 'The contact was not found') && return if @contact.blank?

    if @contact.github_issue_url.present?
      flash[:notice] = 'Issue cannot be edited as it is already committed to GitHub. Please edit there'
      redirect_to(action: 'show') && return
    end
  end

  def force_destroy
    @contact = Contact.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: contacts_path, notice: 'The contact was not found') && return if @contact.blank?

    delete_reply_messages(params[:id]) if @contact.has_replies?(params[:id])
    @contact.delete
    flash.notice = 'Contact and all its replies are destroyed'
    redirect_to(action: 'index') && return
  end

  def index
    session[:archived_contacts] = false
    session[:message_base] = 'contact'
    params[:source] = 'original'
    get_user_info_from_userid
    order = 'contact_time DESC'
    @contacts = Contact.results(session[:archived_contacts], order, @user)
    @archived = session[:archived_contacts]
  end

  def keep
    @contact = Contact.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: contacts_path, notice: 'The contact was not found') && return if @contact.blank?

    session[:archived_contacts] = true
    @contact.update_keep
    flash.notice = 'Contact to be retained'
    return_after_keep(params[:source], params[:id])
  end

  def list_archived
    session[:archived_contacts] = true
    session[:message_base] = 'contact'
    params[:source] = 'original'
    get_user_info_from_userid
    order = 'contact_time  ASC'
    @contacts = Contact.results(session[:archived_contacts], order, @user)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_date
    get_user_info_from_userid
    order = 'contact_time ASC'
    @contacts = Contact.results(session[:archived_contacts], order, @user)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_most_recent
    get_user_info_from_userid
    order = 'contact_time DESC'
    @contacts = Contact.results(session[:archived_contacts], order, @user)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_name
    get_user_info_from_userid
    order = 'name ASC'
    @contacts = Contact.results(session[:archived_contacts], order, @user)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_type
    get_user_info_from_userid
    order = 'contact_type ASC'
    @contacts = Contact.results(session[:archived_contacts], order, @user)
    @archived = session[:archived_contacts]
    render :index
  end

  def new
    @contact = Contact.new
    @options = FreeregOptionsConstants::ISSUES
    @contact.contact_time = Time.now
    @contact.contact_type = FreeregOptionsConstants::ISSUES[0]
    #flash.notice = 'Please use Communicate Action to contact your Syndicate Coordinator first.' if session[:userid].present?
  end

  def report_error
    @contact = Contact.new
    @contact.contact_time = Time.now
    @contact.contact_type = 'Data Problem'
    @contact.problem_page_url = request.headers["HTTP_REFERER"]
    @contact.query = params[:query]
    @contact.record_id = params[:id]
    case appname_downcase
    when 'freereg'
      redirect_back(fallback_location: contacts_path, notice: 'The record was not found') && return if params[:id].blank? || SearchRecord.find(params[:id]).blank?
      @contact.entry_id = SearchRecord.find(params[:id]).freereg1_csv_entry._id
      @freereg1_csv_entry = Freereg1CsvEntry.find(@contact.entry_id)
      @contact.county = @freereg1_csv_entry.freereg1_csv_file.county
      @contact.line_id = @freereg1_csv_entry.line_id
    when 'freecen'
      @rec = SearchRecord.where("id" => @contact.record_id).first
      @ind_id = @rec.freecen_individual_id
      @contact.county = @rec.chapman_code
      unless @rec.nil?
        fc_ind = FreecenIndividual.where("id" => @ind_id).first if @ind_id.present?
        if fc_ind.present?
          @contact.entry_id = fc_ind.freecen1_vld_entry_id.to_s unless fc_ind.freecen1_vld_entry_id.nil?
          if @contact.entry_id.present?
            ent = Freecen1VldEntry.where("id" => @contact.entry_id).first
            if ent.present?
              if ent.freecen1_vld_file.present?
                vldfname = ent.freecen1_vld_file.file_name
              end
              @contact.line_id = '' + (vldfname unless vldfname.nil?) + ':dwelling#' + (ent.dwelling_number.to_s unless  ent.dwelling_number.nil?) + ',individual#'+ (ent.sequence_in_household.to_s unless ent.sequence_in_household.nil?)
            end #ent.present
          end # @contact.entry_id.present?
        end # fc_ind.present
      end # unless rec.nil?
    when 'freebmd'
      @freebmd_record = BestGuess.find_by(RecordNumber: @contact.record_id) if @contact.record_id.present?
    end
  end

  def restore
    @contact = Contact.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: contacts_path, notice: 'The contact was not found') && return if @contact.blank?

    @contact.restore
    flash.notice = 'Contact restored'
    return_after_restore(params[:source], params[:id])
  end

  def reply_contact
    @respond_to_contact = Contact.find(params[:source_contact_id])
    redirect_back(fallback_location: contacts_path, notice: 'The contact was not found') && return if @respond_to_contact.blank?

    get_user_info_from_userid
    @contact_replies = Message.where(source_contact_id: params[:source_contact_id]).all
    @contact_replies.each do |reply|
    end
    @message = Message.new
    @message.message_time = Time.now
    @message.userid = @user.userid
  end

  def return_after_archive(source, id)
    if source == 'show'
      redirect_to action: 'show', id: id
    else
      redirect_to action: 'index'
    end
  end

  def return_after_keep(source, id)
    if source == 'show'
      redirect_to action: 'show', id: id
    else
      redirect_to action: 'index'
    end
  end

  def return_after_restore(source, id)
    if source == 'show'
      redirect_to action: 'show', id: id
    else
      redirect_to action: 'index'
    end
  end

  def return_after_unkeep(source, id)
    if source == 'show'
      redirect_to action: 'show', id: id
    else
      redirect_to action: 'list_archived'
    end
  end

  def select_by_identifier
    get_user_info_from_userid
    @options = {}
    order = 'identifier ASC'
    Contact.results(session[:archived_contacts], order, @user).each do |contact|
      @options[contact.identifier] = contact.id
    end
    @contact = Contact.new
    @location = 'location.href= "/contacts/" + this.value'
    @prompt = 'Select Identifier'
    render '_form_for_selection'
  end

  def  set_nil_session_parameters
    session[:freereg1_csv_file_id] = nil
    session[:freereg1_csv_file_name] = nil
    session[:place_name] = nil
    session[:church_name] = nil
    session[:county] = nil
  end

  def set_session_parameters_for_record(file)
    return true if MyopicVicar::Application.config.template_set == 'freecen'

    return false if file.blank?

    register = file.register
    return false if register.blank?

    church = register.church
    return false if church.blank?

    place = church.place
    return false if place.blank?

    session[:freereg1_csv_file_id] = file._id
    session[:freereg1_csv_file_name] = file.file_name
    session[:place_name] = place.place_name
    session[:church_name] = church.church_name
    session[:county] = place.county
    true
  end

  def show
    @contact = Contact.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: contacts_path, notice: 'The contact was not found') && return if @contact.blank?

    if @contact.entry_id.present? && Freereg1CsvEntry.id(@contact.entry_id).present?
      file = Freereg1CsvEntry.id(@contact.entry_id).first.freereg1_csv_file
      result = set_session_parameters_for_record(file)
      redirect_back(fallback_location: contacts_path, notice: 'The contact was not found') && return unless result
    else
      set_nil_session_parameters
    end
  end

  def unkeep
    @contact = Contact.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: contacts_path, notice: 'The contact was not found') && return if @contact.blank?

    get_user_info_from_userid
    @contact.update_unkeep
    flash.notice = 'Contact no longer being kept'
    return_after_unkeep(params[:source], params[:id])
  end

  def update
    @contact = Contact.find(params[:id]) if params[:id].present?
    redirect_back(fallback_location: contacts_path, notice: 'The contact was not found') && return if @contact.blank?

    @contact.update_attributes(contact_params)
    redirect_to(action: 'show') && return
  end

  def question_answer_finder
    question_id = params[:question_id]
    question_v = question_id
    file = File.open("#{Rails.root}/public/faq.html.erb")
    read_file = file.read
    file = Nokogiri::HTML(read_file)
    @answer = file.css("div.answer_#{question_v}").to_html
  end

  private

  def assign_record_url_and_save
    return unless @contact.record_id.present?

    record = BestGuess.find_by(RecordNumber: @contact.record_id)
    @contact.record_url = build_record_url(record) if record.present?
  end

  # report_error does not submit contact[body]; the model requires :body. Build it from
  # session_data (FreeBMD corrections, section 3 missing-entry fields) or a minimal fallback.
  def merge_contact_body_for_data_problem
    attach_freebmd_field_report_snapshot!
    extra_comments = @contact.body.to_s.strip
    auto = auto_body_from_report_error_session_data
    if auto.present? && extra_comments.present?
      @contact.body = "#{auto}\n\n--- Additional comments ---\n#{extra_comments}"
    elsif extra_comments.present?
      @contact.body = extra_comments
    elsif auto.present?
      @contact.body = auto
    else
      parts = []
      parts << "Subsection: #{@contact.query}" if @contact.query.present?
      parts << "Record: #{@contact.record_id}" if @contact.record_id.present?
      @contact.body = parts.any? ? "Data problem report. #{parts.join('. ')}." : 'Data problem report.'
    end
  end

  def attach_freebmd_field_report_snapshot!
    return unless appname_downcase == 'freebmd'
    return if @contact.record_id.blank?

    record = BestGuess.find_by(RecordNumber: @contact.record_id)
    return unless record

    sd = normalize_session_data_hash(@contact.session_data)
    corrections = sd['corrections']
    corrections = {} unless corrections.is_a?(Hash)
    sd['freebmd_field_report'] = FreebmdContactFieldReport.build_rows(record, corrections)
    @contact.session_data = sd
  end

  REPORT_ERROR_BODY_SECTION_RULE = '------------------------------------------------------------'

  def auto_body_from_report_error_session_data
    sd = normalize_session_data_hash(@contact.session_data)
    return nil if sd.blank?

    chunks = []
    if sd['freebmd_field_report'].present?
      inner = FreebmdContactFieldReport.to_plain_text(sd['freebmd_field_report'])
      chunks << [
        'CURRENT INDEX ENTRY (FreeBMD — values as shown on the report page)',
        REPORT_ERROR_BODY_SECTION_RULE,
        inner
      ].join("\n")
    else
      co = corrections_only_plain_text_chunk(sd['corrections'])
      chunks << co if co.present?
    end

    s3 = section3_plain_text_chunk(sd['section3'])
    chunks << s3 if s3.present?

    chunks.any? ? chunks.compact.join("\n\n#{REPORT_ERROR_BODY_SECTION_RULE}\n\n") : nil
  end

  def corrections_only_plain_text_chunk(corrections)
    return nil unless corrections.is_a?(Hash)

    lines = []
    correction_labels = {
      'surname' => 'Surname',
      'given_name' => 'Given name',
      'registration_date' => 'Registration date',
      'mothers_maiden_name' => "Mother's maiden name",
      'age_or_dob' => 'Age at death / date of birth',
      'spouse_name' => 'Spouse name',
      'district' => 'District',
      'volume' => 'Volume',
      'register_number' => 'Register number',
      'entry_number' => 'Entry number',
      'page' => 'Page'
    }
    corrections.each do |key, val|
      next if val.blank?

      key_s = key.to_s
      label = correction_labels[key_s] || key_s.tr('_', ' ').split.map(&:capitalize).join(' ')
      lines << "#{label}: #{val}"
    end
    lines.any? ? lines.join("\n") : nil
  end

  def section3_plain_text_chunk(section3)
    return nil unless section3.is_a?(Hash) && section3.values.any? { |v| v.present? }

    field_lines = []
    section3.each do |key, val|
      next if val.blank?

      key_s = key.to_s
      next if key_s == 'multiple_entries' && val.to_s != '1'

      label = key_s == 'multiple_entries' ? 'Multiple entries' : key_s.tr('_', ' ').split.map(&:capitalize).join(' ')
      field_lines << "#{label}: #{val}"
    end
    return nil if field_lines.empty?

    [
      'MISSING OR ADDITIONAL ENTRY (details supplied by reporter — may not relate to the line above)',
      REPORT_ERROR_BODY_SECTION_RULE,
      field_lines.join("\n")
    ].join("\n")
  end

  def normalize_session_data_hash(sd)
    return {} if sd.blank?

    h = sd.respond_to?(:to_unsafe_h) ? sd.to_unsafe_h : sd
    h = h.to_hash if h.respond_to?(:to_hash) && !h.is_a?(Hash)
    h.stringify_keys
  rescue StandardError
    {}
  end

  def build_record_url(record)
    helpers.full_entry_information_url_for(record)
  end

  def contact_params
    params.require(:contact).permit!
  end

  def delete_reply_messages(contact_id)
    Message.where(source_contact_id: contact_id).destroy
  end

end
