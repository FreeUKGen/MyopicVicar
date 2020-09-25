class BestGuessHashController < ApplicationController
  skip_before_action :require_login

  def show
    #redirect_back(fallback_location: new_search_query_path) && return unless show_value_check
    @record_number = BestGuessHash.where(Hash: params[:id]).first.RecordNumber
    @search_record = BestGuess.where(RecordNumber: @record_number).first
    @display_date = false
    #@entry.display_fields(@search_record)
    
  end
end