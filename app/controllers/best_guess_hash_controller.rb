class BestGuessHashController < ApplicationController
  skip_before_action :require_login

  def show
    # Get hash from params[:id] (could be in path or query string)
    hash_id = params[:id]
    clean_id = URI.decode_www_form_component(hash_id) if hash_id.present?
    
    redirect_to(new_search_query_path, notice: 'Hash ' + hash_id.to_s + ' is no longer valid: please re-run your search') && return if clean_id.blank? || BestGuessHash.where(Hash: clean_id).empty?
    
    best_guess_hash = BestGuessHash.where(Hash: clean_id).first
    record = BestGuess.where(RecordNumber: best_guess_hash.RecordNumber).first
    
    redirect_to(new_search_query_path, notice: 'Record not found') && return unless record
    
    # Redirect to BestGuess#show using the friendly URL
    redirect_to friendly_bmd_record_details_non_search_path(record.RecordNumber, record.friendly_url, hash: true,locale: params[:locale])
  end

  def bmd1_url
    @hash = params[:cite]
    redirect_to '/entry-information/'+@hash.to_s+'/hash'
  end

end