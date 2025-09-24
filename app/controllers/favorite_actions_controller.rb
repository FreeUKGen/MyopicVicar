class FavoriteActionsController < ApplicationController
  before_action :authenticate_user!
  before_action :get_user_info_from_userid

  def add
    action = params[:action_name]
    if @user.can_add_favorite?
      if @user.add_favorite_action(action)
        flash[:notice] = "#{action} added to favorites"
      else
        flash[:alert] = "Failed to add #{action} to favorites"
      end
    else
      flash[:alert] = "You can only have 5 favorite actions"
    end
    redirect_back(fallback_location: root_path)
  end

  def remove
    action = params[:action_name]
    @user.remove_favorite_action(action)
    flash[:notice] = "#{action} removed from favorites"
    redirect_back(fallback_location: root_path)
  end

  def manage
    # This will show a page to manage favorites
    @available_actions = UseridRole::OPTIONS.fetch(@user.person_role)
    @favorite_actions = @user.favorite_actions
  end

  def update_favorites
    selected_actions = params[:favorite_actions] || []
    
    # Validate that no more than 5 are selected
    if selected_actions.length > 5
      flash[:alert] = "You can only select up to 5 favorite actions"
      redirect_to manage_favorites_path and return
    end
    
    # Validate that all selected actions are available for the user's role
    available_actions = UseridRole::OPTIONS.fetch(@user.person_role)
    invalid_actions = selected_actions - available_actions
    if invalid_actions.any?
      flash[:alert] = "Invalid actions selected: #{invalid_actions.join(', ')}"
      redirect_to manage_favorites_path and return
    end
    
    @user.favorite_actions = selected_actions
    @user.save
    
    flash[:notice] = "Favorites updated successfully"
    redirect_to manage_favorites_path
  end

  private

  def authenticate_user!
    redirect_to(new_search_query_path) unless current_refinery_user.present?
  end
end
