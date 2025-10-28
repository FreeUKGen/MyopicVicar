class BestGuessHashController < ApplicationController
  skip_before_action :require_login

  def show


    clean_id = URI.decode_www_form_component(params[:id])
    redirect_to( new_search_query_path, notice: 'Hash '+params[:id]+' is no longer valid: please re-run your search') && return if BestGuessHash.where(Hash: clean_id).empty?
    @entry_hash = BestGuessHash.find('clean_id')
    @record_number = BestGuessHash.where(Hash: clean_id).first.RecordNumber
    @search_record = BestGuess.find(@record_number)
    @search = params[:search_id].present? ? true : false
    @page_number = params[:page_number].to_i
    @postems_count = @search_record&.postems_list&.count || 0
    page_entries = @search_record.entries_in_the_page
    show_scans
    list_postems
    @display_date = false
    respond_to do |format|@current_record
      format.html # show.html.erb
      format.json { render json: @search_record }
      format.xml { render xml: @search_record }
    end
    #@entry.display_fields(@search_record)
    
  end

  def show_scans
    @scan_links = @search_record.uniq_scanlists if @search_record.uniq_scanlists.present?
    @acc_scans = @search_record.get_non_multiple_scans if @search_record.get_non_multiple_scans.present?
    @acc_mul_scans = @search_record.multiple_best_probable_scans if @search_record.multiple_best_probable_scans.present?
  end

  def list_postems
    record_best_guess_hash = @entry_hash
    @new_postem = record_best_guess_hash.postems.new
    @postem_honeypot = "postem#{rand.to_s[2..11]}"
    session[:postem_honeypot] = @postem_honeypot
  end

  def bmd1_url
    @hash = params[:cite]
    redirect_to '/entry-information/'+@hash.to_s+'/hash'
  end

end