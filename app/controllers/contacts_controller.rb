class ContactsController < InheritedResources::Base
  require 'freereg_options_constants'
  skip_before_filter :require_login, only: [:new, :report_error, :create]
  def index
    @contacts = Contact.all.order_by(contact_time: -1)
  end
  def show
    @contact = Contact.id(params[:id]).first
    if @contact.nil?
      go_back("contact",params[:id])
    else
      set_session_parameters_for_record(@contact) if @contact.entry_id.present?
    end
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
  def report_error
    @contact = Contact.new
    @contact.contact_time = Time.now
    @contact.contact_type = 'Data Problem'
    @contact.query = params[:query]
    @contact.record_id = params[:id]
    @contact.entry_id = SearchRecord.find(params[:id]).freereg1_csv_entry._id
    @freereg1_csv_entry = Freereg1CsvEntry.find( @contact.entry_id)
    @contact.line_id  = @freereg1_csv_entry.line_id
  end

  def delete
    Contact.find(params[:id]).destroy
    flash.notice = "Contact destroyed"
    redirect_to :action => 'index'
  end

  def convert_to_issue
    @contact = Contact.find(params[:id])
    @contact.github_issue
    flash.notice = "Issue created on Github."
    redirect_to contact_path(@contact.id)
  end

  def set_session_parameters_for_record(contact)
    file_id = Freereg1CsvEntry.find(contact.entry_id).freereg1_csv_file
    file = Freereg1CsvFile.find(file_id)
    church = file.register.church
    place = church.place
    session[:freereg1_csv_file_id] = file._id
    session[:freereg1_csv_file_name] = file.file_name
    session[:place_name] = place.place_name
    session[:church_name] = church.church_name
    session[:county] = place.county
  end

  def message
    
    
  end
end
