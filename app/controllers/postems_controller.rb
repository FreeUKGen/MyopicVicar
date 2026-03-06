class PostemsController < ApplicationController
  include MasterOnlyRedirect

  skip_before_action :require_login
  before_action :redirect_to_master_unless_master, only: [:create]
  require 'rails_autolink'

  def create
    return if spam_detected?(postem_params[:honeypot])

    if postem_hash_blocked?(postem_params[:Hash])
      flash[:notice] = "Postems cannot be added for this record."
      redirect_back(fallback_location: root_path) && return
    end

    best_guess_hash = BestGuessHash.find_by(Hash: postem_params[:Hash])
    unless best_guess_hash
      flash[:notice] = "Record not found."
      redirect_back(fallback_location: root_path) && return
    end

    @record = best_guess_hash.best_guess
    @postem = build_postem(@record)
    @search_query = SearchQuery.find_by(id: params[:search_query])

    if @postem.save
      set_postem_flag_on_record(@record)
      flash[:notice] = "Added Postem successfully. Please note that it may take up to 24 hours for this entry to be marked as having a postem in search results."
      redirect_to postem_success_redirect_path
    else
      flash[:notice] = @postem.errors.full_messages.join('; ')
      redirect_back(fallback_location: root_path)
    end
  end

  private

  def spam_detected?(honeypot)
    honeypot.present?
  end

  def postem_hash_blocked?(hash_value)
    return false if hash_value.blank?
    blocked = Rails.application.config.respond_to?(:postem_blocked_hashes) ? Rails.application.config.postem_blocked_hashes : []
    blocked.is_a?(Array) && blocked.include?(hash_value.to_s)
  end

  # Set the ENTRY_POSTEM bit on BestGuess (and BestGuessMarriage if present) so the record
  # is immediately marked as having postems (search icon, redirect-to-master logic).
  def set_postem_flag_on_record(best_guess_record)
    new_confirmed = (best_guess_record.Confirmed.to_i | BestGuess::ENTRY_POSTEM)
    best_guess_record.update_column(:Confirmed, new_confirmed)
    marriage = BestGuessMarriage.find_by(RecordNumber: best_guess_record.RecordNumber)
    marriage&.update_column(:Confirmed, (marriage.Confirmed.to_i | BestGuess::ENTRY_POSTEM))
  end

  def build_postem(record)
    postem = Postem.new(postem_params.except(:honeypot).delete_if { |_k, v| v.blank? })
    postem.QuarterNumberEvent = (record.QuarterNumber * 3) + record.RecordTypeID
    postem.RecordInfo = [record.Surname, record.GivenName, "#{record.AgeAtDeath}#{record.AssociateName}", record.District, record.Volume, record.Page].join('|')
    postem.SourceInfo = request.remote_ip
    postem.Created = Time.current.to_i.to_s
    postem
  end

  def postem_success_redirect_path
    if @search_query.present?
      friendly_bmd_record_details_path(@search_query.id, @record.RecordNumber, @record.friendly_url)
    else
      friendly_bmd_record_details_non_search_path(@record.RecordNumber, @record.friendly_url)
    end
  end

  def postem_params
    params.require(:postem).permit!
  end
end