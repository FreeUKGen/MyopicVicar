class DonateCtaFeedbackController < ApplicationController
  skip_before_action :require_login
	def new
    @feedback = DonateCtaFeedback.new
  end

  def create
  	@feedback = DonateCtaFeedback.new(feedback_params.delete_if { |_k, v| v.blank? })
  	if @feedback.save
  		@feedback.complete_process
      redirect_to new_search_query_path
  	else
      render :new
  	end
  end

  private

  def feedback_params
    params.require(:feedback).permit!
  end
end