class ReminderToDonateController < ApplicationController
  skip_before_action :require_login
	def new
    @reminder_to_donate = ReminderToDonate.new
  end

  def create
  	@reminder_to_donate = ReminderToDonate.new(reminder_to_donate_params.delete_if { |_k, v| v.blank? })
  	if @reminder_to_donate.save
      redirect_to new_search_query_path
  	else
      render :new
  	end
  	
  end

  def index
    get_user_info_from_userid
    @feedbacks = ReminderToDonate.all
  end

  private

  def reminder_to_donate_params
    params.require(:reminder_to_donate).permit!
  end
end