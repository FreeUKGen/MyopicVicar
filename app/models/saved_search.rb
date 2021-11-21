class SavedSearch
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :search_id, type: String
  field :results, type: Array, default: []
  belongs_to :userid_detail

  def bmd_saved_search_results
    save_search_result_hash = self.results
    BestGuess.get_best_guess_records(save_search_result_hash)
  end

   def get_bmd_saved_search_results
    search_results = SearchQuery.sort_saved_search_results
    return search_results, ucf_save_search_results, saved_search_result_count
  end

  def saved_search_result_count
    bmd_saved_search_results.length
  end

  def sort_saved_search_results
    SearchQuery.sort_results(bmd_saved_search_results) unless bmd_saved_search_results.nil?
  end

  def get_bmd_save_search_response
    self.respond_to?(:bmd_saved_search_results)
  end

  def ucf_save_search_results
    []
  end

end