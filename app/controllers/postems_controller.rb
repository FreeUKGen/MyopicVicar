class PostemsController < ApplicationController
  # flash lives in the session cookie (~4KB total after signing); keep notices short
  FLASH_NOTICE_MAX_CHARS = 1500

  skip_before_action :require_login

  def create
    return if spam_detected?(postem_params[:honeypot])

    if postem_hash_blocked?(postem_params[:Hash])
      assign_postem_flash_notice("Postems cannot be added for this record.")
      redirect_back(fallback_location: root_path) && return
    end

    best_guess_hash = BestGuessHash.find_by(Hash: postem_params[:Hash])
    unless best_guess_hash
      assign_postem_flash_notice("Record not found.")
      redirect_back(fallback_location: root_path) && return
    end

    @record = best_guess_hash.best_guess
    @search_query = SearchQuery.find_by(id: params[:search_query])

    # delegate to freebmd1 perl api
    service = FreebmdPostemService.new
    source_info = "MyopicVicar submission from: #{request.remote_ip}"

    # check for dry-run mode (for testing/preview)
    dry_run = params[:dry_run].present? || postem_params[:dry_run].present?

    begin
      response = service.create_postem(
        record: @record,
        information: postem_params[:Information],
        source_info: source_info,
        dry_run: dry_run
      )

      if response[:dry_run]
        assign_postem_flash_notice("Preview: #{response[:message]} No data was saved.")
        redirect_back(fallback_location: root_path)
      else
        assign_postem_flash_notice("Added Postem successfully. #{response[:note]}")
        redirect_to postem_success_redirect_path
      end

    rescue FreebmdPostemService::ValidationError => e
      Rails.logger.warn("Postem validation: #{e.message}")
      assign_postem_flash_notice("Validation error: #{e.message}")
      redirect_back(fallback_location: root_path)

    rescue FreebmdPostemService::AuthenticationError => e
      Rails.logger.error("FreeBMD API authentication failed: #{e.message}")
      assign_postem_flash_notice("System error: unable to create postem. Please try again later.")
      redirect_back(fallback_location: root_path)

    rescue FreebmdPostemService::PostemCreationError => e
      Rails.logger.error("FreeBMD API error (full): #{e.message}")
      assign_postem_flash_notice("Error creating postem: #{e.message}")
      redirect_back(fallback_location: root_path)

    rescue StandardError => e
      Rails.logger.error("Unexpected error creating postem: #{e.message}\n#{e.backtrace.join("\n")}")
      assign_postem_flash_notice("System error: unable to create postem. Please try again later.")
      redirect_back(fallback_location: root_path)
    end
  end

  private

  def spam_detected?(honeypot)
    honeypot.present?
  end

  def assign_postem_flash_notice(text)
    flash[:notice] = text.to_s.truncate(FLASH_NOTICE_MAX_CHARS, omission: "…", separator: " ")
  end

  def postem_hash_blocked?(hash_value)
    return false if hash_value.blank?
    blocked = Rails.application.config.respond_to?(:postem_blocked_hashes) ?
              Rails.application.config.postem_blocked_hashes : []
    blocked.is_a?(Array) && blocked.include?(hash_value.to_s)
  end

  def postem_success_redirect_path
    if @search_query.present?
      friendly_bmd_record_details_path(@search_query.id, @record.RecordNumber, @record.friendly_url, search_entry: @record.RecordNumber, record_hash: @record.record_hash)
    else
      friendly_bmd_record_details_non_search_path(@record.RecordNumber, @record.friendly_url)
    end
  end

  def postem_params
    params.require(:postem).permit!
  end
end
