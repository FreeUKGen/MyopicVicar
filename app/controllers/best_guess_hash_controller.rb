class BestGuessHashController < ApplicationController
  skip_before_action :require_login

  def show
    #redirect_back(fallback_location: new_search_query_path) && return unless show_value_check
    @record_number = BestGuessHash.where(Hash: params[:id]).first.RecordNumber
    @search_record = BestGuess.where(RecordNumber: @record_number).first
    @display_date = false
    #@entry.display_fields(@search_record)
    
  end

  def bmd1_url
    @hash = params[:cite]
    @hash_record = BestGuessHash.where(Hash: @hash).first
    @record_id  = @hash_record.RecordNumber unless @hash_record.blank?
    redirect_to( new_search_query_path, notice: 'Hash '+@hash+' is no longer valid: please re-run your search') && return if @record_id.blank?
    redirect_to '/entry-information/'+@hash.to_s+'/hash'
  end


  def bmd1_show
    @hash = params[:hash]
    #@record_number = params[:record_id]
    @record_number = BestGuessHash.where(Hash: @hash).first.RecordNumber
    @search_record = BestGuess.where(RecordNumber: @record_number).first
    @display_date = false
    respond_to do |format|
      format.html # bmd1_show.html.erb
      format.json { render json: @search_record }
      format.xml { render xml: @search_record }
      # format.rdf { render rdf: @search_record }
    end
  end
end