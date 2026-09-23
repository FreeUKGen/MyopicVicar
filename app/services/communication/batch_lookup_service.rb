# frozen_string_literal: true

module Communication
  class BatchLookupService
    # ---------------------------------------------------------------------------
    # Public API
    # ---------------------------------------------------------------------------
    def initialize(file_name:, userid:, appname:, dry_run: false )
      @file_name = file_name
      @userid    = userid.is_a?(UseridDetail) ? userid.userid : userid
      @appname   = appname.to_s.downcase
      @dry_run   = dry_run
    end

    def call
      return fallback_result("Missing file name") unless @file_name.present?
      return fallback_result("Missing userid")     unless @userid.present?

      # If dry_run is true, we log the attempt for audit purposes
      Rails.logger.info("BatchLookupService: DRY RUN for #{@file_name} (User: #{@userid})") if @dry_run
      
      Rails.logger.info("\nBatchLookupService: Userid: #{@userid} for file: #{@file_name}")

      batch = lookup_batch

      Rails.logger.info("BatchLookupService: batch #{batch.inspect} for #{@file_name}")

      if batch.present?
        Rails.logger.info("BatchLookupService: Found batch #{batch.id} for #{@file_name}")
        success(batch)
      else
        Rails.logger.info("BatchLookupService: No record found for File: #{@file_name}, User: #{@userid}, App: #{@appname}")
        fallback_result("Batch not found")
      end
    end

    # ---------------------------------------------------------------------------
    # Internal workflow
    # ---------------------------------------------------------------------------
    private

    # Determine which model to query based on appname
    def lookup_batch
      case @appname
      when "freereg"
        Freereg1CsvFile.where(file_name: @file_name, userid: @userid).first
      when "freecen"
        FreecenCsvFile.where(file_name: @file_name, userid: @userid).first
      else
        Rails.logger.warn("BatchLookupService: Unknown appname #{@appname.inspect}")
        nil
      end
    end

    # ---------------------------------------------------------------------------
    # Result builders
    # ---------------------------------------------------------------------------
    def success(batch)
      OpenStruct.new(
        found: true,
        batch: batch,
        county: batch.county,
        datemin: batch.datemin,
        datemax: batch.datemax,
        errors: batch.error,
        reason: @dry_run ? "Dry Run: Record exists" : nil,
        dry_run: @dry_run
      )
    end

    def fallback_result(reason)
      OpenStruct.new(
        found: false,
        batch: nil,
        county: nil,
        datemin: nil,
        datemax: nil,
        errors: nil,
        reason: @dry_run ? "Dry Run: #{reason}" : reason,
        dry_run: @dry_run
      )
    end
  end
end
