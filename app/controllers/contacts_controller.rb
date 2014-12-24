class ContactsController < InheritedResources::Base
  require 'freereg_options_constants'
  skip_before_filter :require_login
  def index
    @contacts = Contact.all.order_by(contact_time: -1).page(params[:page])
  end
  
  def new
    @contact = Contact.new(params)
    @options = FreeregOptionsConstants::ISSUES
  end

  def create
    @contact = Contact.new(params[:contact])
    @contact.session_id = request.session["session_id"]
    @contact.problem_page_url= request.env['REQUEST_URI']
    @contact.previous_page_url= request.env['HTTP_REFERER']
    @contact.contact_time = Time.now
    @contact.save!
    flash[:notice] = "Thank you for contacting us!"
    redirect_to new_search_query_path
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
    show
  end
end
