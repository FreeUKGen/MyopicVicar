class SavedSearchController < ApplicationController
	def index
		get_user_info_from_userid
		@saved_searches = @user.saved_searches
	end

	def save_search
    search_id = params[:id]
    search_results = SearchQuery.find(search_id).search_result.records.keys
    results_hash = BestGuess.results_hash(search_results)
    if @saved_search.present?
    	flash[:notice] = "Search is already saved"
    else
    	saved_search = user.saved_searches.new(search_id: search_id, results: results_hash)
    	if saved_search.save
      	flash[:notice] = "Search Saved Successfully"
    	else
      	flash[:notice] = "We experienced problem, please try again later"
    	end
    end
    redirect_to search_query_path(search_id)
  end

  def get_saved_search
  	get_user_info_from_userid
  	@saved_search = @user.saved_searches.where(search_id: search_id, results: results_hash)
  end

end