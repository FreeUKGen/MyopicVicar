class FeedbacksController < InheritedResources::Base
  
  def new
    @feedback = Feedback.new(params)
  end
  
  def convert_to_issue
    @feedback = Feedback.find(params[:id])
    @feedback.github_issue
    flash[:success] = "Issue created on Github."
    show
  end
end
