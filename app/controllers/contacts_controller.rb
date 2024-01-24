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

  skip_before_action :require_login, only: [:new, :report_error, :create, :show]

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
      @contact.save
      if @contact.errors.any?
        flash[:notice] = 'There was a problem with your submission please review'
        if @contact.contact_type == 'Data Problem'
          redirect_to(@contact.previous_page_url) && return
        else
          @options = FreeregOptionsConstants::ISSUES
          render :new
        end
      else
        flash[:notice] = 'Thank you for contacting us!'
        @contact.communicate_initial_contact
        if @contact.query
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
    @primary_contacts = Contact.primary_results(session[:archived_contacts], order, @user)
    @secondary_contacts = Contact.secondary_results(session[:archived_contacts], order, @user)
    @primary_contact_present = @primary_contacts.present?
    @secondary_contact_present = @secondary_contacts.present?
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
    @primary_contacts = Contact.primary_results(session[:archived_contacts], order, @user)
    @secondary_contacts = Contact.secondary_results(session[:archived_contacts], order, @user)
    @primary_contact_present = @primary_contacts.present?
    @secondary_contact_present = @secondary_contacts.present?
    #@contacts = Contact.results(session[:archived_contacts], order, @user)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_date
    get_user_info_from_userid
    order = 'contact_time ASC'
    @primary_contacts = Contact.primary_results(session[:archived_contacts], order, @user)
    @secondary_contacts = Contact.secondary_results(session[:archived_contacts], order, @user)
    @primary_contact_present = @primary_contacts.present?
    @secondary_contact_present = @secondary_contacts.present?
    #@contacts = Contact.results(session[:archived_contacts], order, @user)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_most_recent
    get_user_info_from_userid
    order = 'contact_time DESC'
    @primary_contacts = Contact.primary_results(session[:archived_contacts], order, @user)
    @secondary_contacts = Contact.secondary_results(session[:archived_contacts], order, @user)
    @primary_contact_present = @primary_contacts.present?
    @secondary_contact_present = @secondary_contacts.present?
    #@contacts = Contact.results(session[:archived_contacts], order, @user)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_name
    get_user_info_from_userid
    order = 'name ASC'
    @primary_contacts = Contact.primary_results(session[:archived_contacts], order, @user)
    @secondary_contacts = Contact.secondary_results(session[:archived_contacts], order, @user)
    @primary_contact_present = @primary_contacts.present?
    @secondary_contact_present = @secondary_contacts.present?
    #@contacts = Contact.results(session[:archived_contacts], order, @user)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_type
    get_user_info_from_userid
    order = 'contact_type ASC'
    @primary_contacts = Contact.primary_results(session[:archived_contacts], order, @user)
    @secondary_contacts = Contact.secondary_results(session[:archived_contacts], order, @user)
    @primary_contact_present = @primary_contacts.present?
    @secondary_contact_present = @secondary_contacts.present?
    #@contacts = Contact.results(session[:archived_contacts], order, @user)
    @archived = session[:archived_contacts]
    render :index
  end

  def new
    @contact = Contact.new
    @options = FreeregOptionsConstants::ISSUES
    @options = @options - ['Thank-you'] if appname_downcase == 'freereg'
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
    end # case
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
    @userids = array_of_userids
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
    @secondary_options ={}
    order = 'identifier ASC'
    @primary_contacts = Contact.primary_results(session[:archived_contacts], order, @user)
    @secondary_contacts = Contact.secondary_results(session[:archived_contacts], order, @user)
    @primary_contacts.each do |contact|
      @options[contact.identifier] = contact.id
    end
    @secondary_contacts.each do |contact|
      @secondary_options[contact.identifier] = contact.id
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

  private

  def contact_params
    params.require(:contact).permit!
  end

  def delete_reply_messages(contact_id)
    Message.where(source_contact_id: contact_id).destroy
  end

end
