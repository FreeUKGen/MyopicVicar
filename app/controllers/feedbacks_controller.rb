class FeedbacksController < InheritedResources::Base
  skip_before_filter :require_login
  def index
    @feedbacks = Feedback.all.order_by(feedback_time: -1).page(params[:page])

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
      render :action => 'new'
      return
    end
    flash.notice = "Thank you for your feedback!"
    redirect_to @feedback.problem_page_url
  end

  def delete
    Feedback.find(params[:id]).destroy
    flash.notice = "Feedback destroyed"
    redirect_to :action => 'index'
  end

  def convert_to_issue
    @feedback = Feedback.find(params[:id])
    @feedback.github_issue
    flash.notice = "Issue created on Github."
    show
  end
end
