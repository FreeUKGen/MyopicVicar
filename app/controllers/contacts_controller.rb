class ContactsController < ApplicationController

  require 'freereg_options_constants'
  require 'contact_rules'

  skip_before_filter :require_login, only: [:new, :report_error, :create, :show, :contact_reply_messages]

  def archive
    @contact = Contact.id(params[:id]).first
    if @contact.present?
      @contact.update_attribute(:archived, true)
      flash.notice = "Feedback archived"
      redirect_to :action => "list_archived" and return
    else
      go_back("contact",params[:id])
    end
  end

  def contact_reply_messages
    #get_user_info_from_userid; return if performed?
    @contact = Contact.id(params[:id]).first
    if @contact.present?
      @messages = Message.where(source_contact_id: params[:id]).all
      @links = false
      render 'messages/index'
    end
  end

  def convert_to_issue
    @contact = Contact.id(params[:id]).first
    if @contact.present?
      if @contact.github_issue_url.blank?
        @contact.github_issue
        flash.notice = "Issue created on Github."
        redirect_to contact_path(@contact.id)
        return
      else
        flash.notice = "Issue has already been created on Github."
        redirect_to :action => "show"
        return
      end
    else
      go_back("contact",params[:id])
    end
  end

  def create
    @contact = Contact.new(contact_params)
    if @contact.contact_name.blank? #spam trap
      session.delete(:flash)
      @contact.session_data = session.to_hash
      #avoid invalid character in warden.user.authentication_devise_user.key key
      @contact.session_data["warden_user_authentication_devise_user_key_key"] = @contact.session_data["warden.user.authentication_devise_user.key"][0].to_s.gsub(/\W/, "") unless @contact.session_data["warden.user.authentication_devise_user.key"].blank?
      @contact.session_data["warden_user_authentication_devise_user_key_value"] = @contact.session_data["warden.user.authentication_devise_user.key"][1] unless @contact.session_data["warden.user.authentication_devise_user.key"].blank?
      @contact.session_data.delete("warden.user.authentication_devise_user.key")  unless @contact.session_data["warden.user.authentication_devise_user.key"].blank?
      @contact.session_data["warden_user_authentication_devise_user_key_session"] = @contact.session_data["warden.user.authentication_devise_user.session"]
      @contact.session_data.delete("warden.user.authentication_devise_user.session") unless @contact.session_data["warden.user.authentication_devise_user.session"].blank?
      @contact.session_id = session.to_hash["session_id"]
      @contact.previous_page_url= request.env['HTTP_REFERER']
      @contact.save
      if !@contact.errors.any?
        flash[:notice] = "Thank you for contacting us!"
        @contact.communicate_initial_contact
        if @contact.query
          redirect_to search_query_path(@contact.query)
          return
        else
          redirect_to @contact.previous_page_url
          return
        end
      else
        flash[:notice] = "There was a problem with your submission please review"
        if @contact.contact_type == 'Data Problem'
          redirect_to @contact.previous_page_url
          return
        else
          @options = FreeregOptionsConstants::ISSUES
          @contact.contact_type = FreeregOptionsConstants::ISSUES[0]
          render :new
          return
        end
      end
    else
      @options = FreeregOptionsConstants::ISSUES
      @contact.contact_type = FreeregOptionsConstants::ISSUES[0]
      render :new
      return
    end
  end

  def destroy
    @contact = Contact.id(params[:id]).first
    if @contact.present?
      @contact.delete
      flash.notice = "Contact destroyed"
      redirect_to :action => 'index'
      return
    else
      go_back("contact",params[:id])
    end
  end

  def edit
    @contact = Contact.id(params[:id]).first
    if @contact.present?
      if @contact.github_issue_url.present?
        flash[:notice] = "Issue cannot be edited as it is already committed to GitHub. Please edit there"
        redirect_to :action => 'show'
        return
      end
    else
      go_back("contact",params[:id])
    end
  end

  def force_destroy
    @contact = Contact.id(params[:id]).first
    if @contact.present?
      delete_reply_messages(params[:id]) if @contact.has_replies?(params[:id])
      @contact.delete
      flash.notice = "Contact and all its replies are destroyed"
      redirect_to :action => 'index'
      return
    else
      go_back("contact",params[:id])
    end
  end

  def get_contacts
    ContactRules.new(@user)
  end

  def index
    session[:archived_contacts] = false
    get_user_info_from_userid
    order = "contact_time DESC"
    @contacts = get_contacts.result(session[:archived_contacts],order)
    @archived = session[:archived_contacts]
  end

  def list_archived
    session[:archived_contacts] = true
    get_user_info_from_userid
    order = "contact_time  DESC"
    @contacts = get_contacts.result(session[:archived_contacts],order)
    @archived = session[:archived_contacts]
    render :index
  end


  def list_by_date
    get_user_info_from_userid
    order = "contact_time ASC"
    @contacts = get_contacts.result(session[:archived_contacts],order)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_most_recent
    get_user_info_from_userid
    order = "contact_time DESC"
    @contacts = get_contacts.result(session[:archived_contacts],order)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_name
    get_user_info_from_userid
    order = "name ASC"
    @contacts = get_contacts.result(session[:archived_contacts],order)
    @archived = session[:archived_contacts]
    render :index
  end

  def list_by_type
    get_user_info_from_userid
    order = "contact_type ASC"
    @contacts = get_contacts.result(session[:archived_contacts],order)
    @archived = session[:archived_contacts]
    render :index
  end

  def new
    @contact = Contact.new
    @options = FreeregOptionsConstants::ISSUES
    @contact.contact_time = Time.now
    @contact.contact_type = FreeregOptionsConstants::ISSUES[0]
  end

  def report_error
    @contact = Contact.new
    @contact.contact_time = Time.now
    @contact.contact_type = 'Data Problem'
    @contact.query = params[:query]
    @contact.record_id = params[:id]
    @contact.entry_id = SearchRecord.find(params[:id]).freereg1_csv_entry._id
    @freereg1_csv_entry = Freereg1CsvEntry.find( @contact.entry_id)
    @contact.county = @freereg1_csv_entry.freereg1_csv_file.county
    @contact.line_id  = @freereg1_csv_entry.line_id
  end

  def restore
    @contact = Contact.id(params[:id]).first
    if @contact.present?
      @contact.update_attribute(:archived, false)
      flash.notice = "Contact restored"
      redirect_to :action => "index" and return
    else
      go_back("contact",params[:id])
    end
  end

  def select_by_identifier
    get_user_info_from_userid
    @options = Hash.new
    order = "identifier ASC"
    @contacts = get_contacts.result(session[:archived_contacts],order).each do |contact|
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
    return true
  end

  def show
    @contact = Contact.id(params[:id]).first
    if @contact.present?
      if @contact.entry_id.present? && Freereg1CsvEntry.id(@contact.entry_id).present?
        file = Freereg1CsvEntry.id(@contact.entry_id).first.freereg1_csv_file
        result = set_session_parameters_for_record(file)
        go_back("contact",params[:id]) unless result
      else
        set_nil_session_parameters
      end
    else
      go_back("contact",params[:id])
    end
  end

  def reply_contact
    get_user_info_from_userid; return if performed?
    @respond_to_contact = Contact.id(params[:source_contact_id]).first
    if @respond_to_contact.blank?
      go_back("contact",params[:id])
    end
    @contact_replies = Message.where(source_contact_id: params[:source_contact_id]).all
    @contact_replies.each do |reply|
    end
    @message = Message.new
    @message.message_time = Time.now
    @message.userid = @user.userid
  end

  def update
    @contact = Contact.id(params[:id]).first
    if @contact.present?
      @contact.update_attributes(contact_params)
      redirect_to :action => 'show'
      return
    else
      go_back("contact",params[:id])
    end
  end

  private
  def contact_params
    params.require(:contact).permit!
  end

  def delete_reply_messages(contact_id)
    Message.where(source_contact_id: contact_id).destroy
  end
end
