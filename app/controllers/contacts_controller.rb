class ContactsController < InheritedResources::Base
  require 'freereg_options_constants'
  skip_before_filter :require_login, only: [:new, :report_error, :create]
  def index
    get_user_info_from_userid
    if @user.person_role == 'county_coordinator' || @user.person_role == 'country_coordinator'
      @county = @user.county_groups
      @contacts = Contact.in(:county => @county).all.order_by(contact_time: -1)
    else
      @contacts = Contact.all.order_by(contact_time: -1)
    end  
  end

  def show
    @contact = Contact.id(params[:id]).first
    if @contact.present?
      if @contact.entry_id.present? && Freereg1CsvEntry.id(@contact.entry_id).present?
        file = Freereg1CsvEntry.id(@contact.entry_id).first.freereg1_csv_file
        set_session_parameters_for_record(file)
      else
        set_nil_session_parameters
      end
    else
      go_back("contact",params[:id])
    end   
  end

  def list_by_name
    get_user_info_from_userid
    @contacts = Contact.all.order_by(name: 1)
    render :index
  end

  def list_by_identifier
    get_user_info_from_userid
    @contacts = Contact.all.order_by(identifier: -1)
    render :index
  end

  def list_by_type
    get_user_info_from_userid
    @contacts = Contact.all.order_by(contact_type: 1)
    render :index
  end


  def list_by_date
    get_user_info_from_userid
    @contacts = Contact.all.order_by(contact_time: 1)
    render :index
  end

  def select_by_identifier
    get_user_info_from_userid
    @options = Hash.new
    @contacts = Contact.all.order_by(identifier: -1).each do |contact|
      @options[contact.identifier] = contact.id
    end
    @contact = Contact.new
    @location = 'location.href= "/contacts/" + this.value'
    @prompt = 'Select Identifier'
    render '_form_for_selection'
  end

  def new
    @contact = Contact.new
    @options = FreeregOptionsConstants::ISSUES
    @contact.contact_time = Time.now
    @contact.contact_type = FreeregOptionsConstants::ISSUES[0]
  end

  def create
    @contact = Contact.new(params[:contact])
    if @contact.contact_name.blank? #spam trap
      session.delete(:flash)
      @contact.session_data = session
      @contact.previous_page_url= request.env['HTTP_REFERER']
      if @contact.save
        flash[:notice] = "Thank you for contacting us!"
        @contact.communicate
        if @contact.query
          redirect_to search_query_path(@contact.query, :anchor => "#{@contact.record_id}")
          return
        else
          redirect_to @contact.previous_page_url
          return
        end
      else
        @options = FreeregOptionsConstants::ISSUES
        @contact.contact_type = FreeregOptionsConstants::ISSUES[0]
        render :new
        return
      end
    else
      redirect_to @contact.previous_page_url
      return
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
  
  def update
    @contact = Contact.id(params[:id]).first
    if @contact.present? 
      @contact.update_attributes(params[:contact])
      redirect_to :action => 'show'
      return
    else
      go_back("contact",params[:id])
    end  
  end

  def report_error
    @contact = Contact.new
    @contact.contact_time = Time.now
    @contact.contact_type = 'Data Problem'
    @contact.query = params[:query]
    @contact.record_id = params[:id]
    @contact.entry_id = SearchRecord.find(params[:id]).freereg1_csv_entry._id
    @freereg1_csv_entry = Freereg1CsvEntry.find( @contact.entry_id)
    @contact.county = @freereg1_csv_entry.freereg1_csv_file.register.church.place.chapman_code
    @contact.line_id  = @freereg1_csv_entry.line_id
  end

  def delete
   @contact = Contact.id(params[:id]).first
    if @contact.present? 
      @contact.destroy
      flash.notice = "Contact destroyed"
      redirect_to :action => 'index'
      return
    else
      go_back("contact",params[:id])
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
        redirect_to :show
        return
      end 
    else
      go_back("contact",params[:id])
    end  
  end

  def set_session_parameters_for_record(file)
    church = file.register.church
    place = church.place
    session[:freereg1_csv_file_id] = file._id
    session[:freereg1_csv_file_name] = file.file_name
    session[:place_name] = place.place_name
    session[:church_name] = church.church_name
    session[:county] = place.county
  end

  def  set_nil_session_parameters
    session[:freereg1_csv_file_id] = nil
    session[:freereg1_csv_file_name] = nil
    session[:place_name] = nil
    session[:church_name] = nil
    session[:county] = nil
  end

  def load(contact)
    @contact = Contact.id(contact).first
    if @contact.blank?
      go_back("contact",contact)
    end  
    @contact 
  end
end
