class BestGuessHashController < ApplicationController
  skip_before_action :require_login

  def show
    clean_id = URI.decode_www_form_component(params[:id])
    redirect_to( new_search_query_path, notice: 'Hash '+params[:id]+' is no longer valid: please re-run your search') && return if BestGuessHash.where(Hash: clean_id).empty?
    @record_number = BestGuessHash.where(Hash: clean_id).first.RecordNumber
    @search_record = BestGuess.where(RecordNumber: @record_number).first
    @display_date = false
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @search_record }
      format.xml { render xml: @search_record }
      # format.rdf { render rdf: @search_record }
    end
    #@entry.display_fields(@search_record)
    
  end

  def bmd1_url
    @hash = params[:cite]
    redirect_to '/entry-information/'+@hash.to_s+'/hash'
  end

end