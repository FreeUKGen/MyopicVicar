# frozen_string_literal: true

module Communication
  class CountyLookupService
    # ---------------------------------------------------------------------------
    # Public API
    # ---------------------------------------------------------------------------
    def initialize(file_name:, userid:, appname:, batch_record: nil)
      @file_name     = file_name
      @appname       = appname.to_s.downcase
      @batch_record  = batch_record

      if userid.is_a?(UseridDetail)
        @user_obj = userid
        @userid   = userid.userid # The string "test33"
      else
        @userid   = userid
        @user_obj = UseridDetail.where(userid: userid).first
      end
    end

    def call
      chapman_code = resolve_chapman_code
      return fallback_result unless ChapmanCode.value?(chapman_code)

      county = County.where(chapman_code: chapman_code).first
      return fallback_result unless county.present?

      coordinator_result = CoordinatorLookupService.new(
        userid: @userid,               # Pass the String
        county: county,                # Pass the Object
        appname: @appname
        ).call

      OpenStruct.new(
        chapman_code: chapman_code,
        county: county,
        coordinator: coordinator_result.coordinator,
        coordinator_email: coordinator_result.email
      )
    end

    # ---------------------------------------------------------------------------
    # Internal workflow
    # ---------------------------------------------------------------------------
    private

    # Resolve the county code from:
    # 1. Batch record (if present)
    # 2. Filename (Freereg)
    # 3. Filename → FreeCEN piece lookup
    def resolve_chapman_code
      return @batch_record.county if @batch_record&.county.present?

      case @appname
      when "freereg"
        extract_freereg_code
      when "freecen"
        extract_freecen_code
      else
        Rails.logger.warn("CountyLookupService: Unknown appname #{@appname.inspect}")
        nil
      end
    end

    # Example: "NFK123.csv" → "NFK"
    def extract_freereg_code
      return nil unless @file_name.present?

      base = @file_name.split('.').first.to_s
      base[0..2].to_s.upcase
    end

    # FreeCEN: extract year + piece → lookup Freecen2Piece → chapman_code
    def extract_freecen_code
      return nil unless @file_name.present?

      year, piece, _ = Freecen2Piece.extract_year_and_piece(@file_name, nil)
      return nil unless year.present? && piece.present?

      actual_piece = Freecen2Piece.where(year: year, number: piece.to_s.upcase).first
      actual_piece&.chapman_code
    end

    # ---------------------------------------------------------------------------
    # Fallback result (uses CoordinatorLookupService)
    # ---------------------------------------------------------------------------
    def fallback_result
      coordinator_result = CoordinatorLookupService.new(
        userid: @userid,
        county: nil,
        appname: @appname
      ).call

      OpenStruct.new(
        chapman_code: nil,
        county: nil,
        coordinator: coordinator_result.coordinator,
        coordinator_email: coordinator_result.email
      )
    end
  end
  
end
