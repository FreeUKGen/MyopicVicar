class FeedbacksController < InheritedResources::Base
  skip_before_filter :require_login
  def index
    @feedbacks = Feedback.all.order_by(feedback_time: -1)
  end

   def list_by_name
    get_user_info_from_userid
    @feedbacks = Feedback.all.order_by(name: 1)
    render :index
  end

  def list_by_identifier
    get_user_info_from_userid
    @feedbacks = Feedback.all.order_by(identifier: -1)
    render :index
  end

  def list_by_userid
    get_user_info_from_userid
    @feedbacks = Feedback.all.order_by(user_id: 1)
    render :index
  end

  def list_by_date
    get_user_info_from_userid
    @feedbacks = Feedback.all.order_by(feedback_time: 1)
    render :index
  end

  def select_by_identifier
    get_user_info_from_userid
    @options = Hash.new
    @feedbacks = Feedback.all.order_by(identifier: -1).each do |contact|
      @options[contact.identifier] = contact.id
    end
    @feedback = Feedback.new
    @location = 'location.href= "/feedbacks/" + this.value'
    @prompt = 'Select Identifier'
    render '_form_for_selection'
  end
 
  def edit
    load(params[:id]) 
    if @feedback.github_issue_url.present?
      flash[:notice] = "Issue cannot be edited as it is already committed to GitHub. Please edit there"
      redirect_to :action => 'show'
      return
    end    
  end
  
  def update
    load(params[:id])
    @feedback.update_attributes(params[:feedback])
    redirect_to :action => 'show'
  end

  def new
    @feedback = Feedback.new(params)
  end

  def create
    @feedback = Feedback.new(params[:feedback])
    #eliminate any flash message as the conversion to bson fails
    session.delete(:flash)
    @feedback.session_data = session
    @feedback.save
    if @feedback.errors.any?
       flash.notice = "There was a problem reporting your feedback!"
      render :action => 'new'
      return
    end
    flash.notice = "Thank you for your feedback!"
    @feedback.communicate
    redirect_to @feedback.problem_page_url
  end

  def delete
    Feedback.find(params[:id]).destroy
    flash.notice = "Feedback destroyed"
    redirect_to :action => 'index'
  end

  def convert_to_issue
    @feedback = load(params[:id])
    if @feedback.github_issue_url.blank?
      @feedback.github_issue
      flash.notice = "Issue created on Github."
      redirect_to feedback_path(@feedback.id)
      return
    else
      flash.notice = "Issue has already been created on Github."
      redirect_to :show
      return
    end 
  end

  def load(feedback)
    @feedback = Feedback.id(feedback).first
    if @feedback.blank?
      go_back("feedback",feedback)
    end 
    @feedback 
  end
end
