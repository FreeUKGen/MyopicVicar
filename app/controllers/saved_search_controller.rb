class SavedSearchController < ApplicationController
	def index
		get_user_info_from_userid
		@saved_searches = @user.saved_searches
	end

	def save_search
    @search_id = params[:id]
    search_results = SearchQuery.find(@search_id).search_result.records
    @results_hash = search_results.keys#BestGuess.results_hash(search_results)
    @records_hash = search_results
		get_saved_search
    if @saved_search.present?
    	flash[:notice] = "Search is already saved"
    else
    	saved_search = @user.saved_searches.new(search_id: @search_id, results: @results_hash)
      saved_search.persist_saved_search_results(search_results.values)
    	if saved_search.save
      	flash[:notice] = "Search Saved Successfully"
    	else
      	flash[:notice] = "We experienced problem, please try again later"
    	end
    end
    redirect_to search_query_path(@search_id)
  end

  def get_saved_search
  	get_user_info_from_userid
  	@saved_search = @user.saved_searches.where(search_id: @search_id, results: @results_hash)
  end

  def destroy
  	get_user_info_from_userid
    saved_search = @user.saved_searches.find(params[:id])
    saved_search.saved_search_result.destroy if saved_search.saved_search_result.present?
    saved_search.destroy
    flash[:notice] = 'The search removed successfully'
    redirect_to saved_search_index_path
  end

end