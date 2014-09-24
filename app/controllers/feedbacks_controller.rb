class FeedbacksController < InheritedResources::Base
  
  def new
    @feedback = Feedback.new(params)
  end

  def create
    @feedback = Feedback.new(params[:feedback])
    @feedback.session_data = session
    @feedback.save!

    flash[:notice] = "Thank you for your feedback!"
    redirect_to @feedback.problem_page_url    
  end
  
  def convert_to_issue
    @feedback = Feedback.find(params[:id])
    @feedback.github_issue
    flash[:notice] = "Issue created on Github."
    show
  end
end
