class UserActivitiesController < ApplicationController
  before_action :get_user_info_from_userid

  def index
    @activities = UserActivity.for_user(@user_id)
                            .recent(100)
                            .page(params[:page] || 1)
                            .per(params[:per_page] || 25)

    if params[:activity_type].present?
      @activities = @activities.by_type(params[:activity_type])
    end

    if params[:date_from].present?
      @activities = @activities.where(c_at: Date.parse(params[:date_from]).beginning_of_day..)
    end

    if params[:date_to].present?
      @activities = @activities.where(c_at: ..Date.parse(params[:date_to]).end_of_day)
    end

    if params[:success].present?
      @activities = @activities.where(success: params[:success] == 'true')
    end

    # Search in description
    if params[:search].present?
      @activities = @activities.where(description: /#{Regexp.escape(params[:search])}/i)
    end

    @activity_types = UserActivity::ActivityType::ALL_TYPES
    @total_activities = UserActivity.for_user(@user_id).count
    @recent_activities = UserActivity.for_user(@user_id).recent(10)
  end

  def show
    @activity = UserActivity.find(params[:id])
    
    unless @activity.user_id == @user_id.to_s
      flash[:notice] = 'You can only view your own activities'
      redirect_to user_activities_path and return
    end
  end
end


