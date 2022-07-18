class SavedSearch
  extend SharedSearchMethods
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short
  field :search_id, type: String
  field :results, type: Array, default: []
  field :records, type: Hash, default: {}
  field :result_count, type: Integer
  field :day, type: String
  embeds_one :saved_search_result
  belongs_to :userid_detail

  def bmd_saved_search_results
    save_search_result_hash = self.saved_search_result.records.values
    #BestGuess.get_best_guess_records(save_search_result_hash)
  end

   def get_bmd_saved_search_results
    search_results = bmd_saved_search_results
    return get_bmd_save_search_response, search_results.map{|h| SearchQuery.get_search_table.new(h)}, ucf_save_search_results, result_count if get_bmd_save_search_response
    return get_bmd_save_search_response if !get_bmd_save_search_response
    #return search_results, ucf_save_search_results, saved_search_result_count
  end

  def saved_search_result_count
    bmd_saved_search_results.length
  end

  def sort_saved_search_results
    #SearchQuery.sort_results(bmd_saved_search_results) unless bmd_saved_search_results.nil?
  end

  def get_bmd_save_search_response
    self.respond_to?(:bmd_saved_search_results)
  end

  def ucf_save_search_results
    []
  end

  def persist_saved_search_results(results)
    records = {}
    results.each do |rec|
      record = rec
      best_guess = BestGuess.new(record)
      rec_hash = best_guess.record_hash
      records[rec_hash] = record
    end
    self.saved_search_result = SavedSearchResult.new
    self.saved_search_result.records = records
    self.result_count = records.length
    self.day = Time.now.strftime('%F')
  end
end