class Api::V1::BmdSearchController < Api::V1::BaseController
  DEFAULT_LIMIT = 10
  MAX_LIMIT = 100

  def index
    return render json: {error: 'surname is required'}, status: :bad_request if params[:surname].blank?
    query = build_query
    records, total, success, _code = query.search_records
    return render json: {error: 'search failed'}, status: :unprocessable_entity unless success
    page = records.to_a.sort_by(&:record_hash).first(limit)
    render json: {
      total: total,
      returned: page.size,
      results: page.map{|r| business_object(r)}
    }
  end

  private

  def limit
    [[params[:limit].to_i, 1].max, MAX_LIMIT].min
  rescue StandardError
    DEFAULT_LIMIT
  end

  def build_query
    attrs = { last_name: params[:surname] }
    attrs[:first_name] = params[:first_name] if params[:first_name].present?
    if params[:year].present?
      attrs[:start_year] = params[:year].to_i
      attrs[:end_year] = params[:year].to_i
    end
    attrs[:chapman_codes] = [params[:county]] if params[:county].present? # expects a chapman code, e.g. "DEV"

    SearchQuery.create!(attrs)
  end

  # Fixed business object — no RecordNumber/Volume/Page, per the no-primary-key principle.
  def business_object(record)
    {
      id: record.record_hash,
      record_type: record.RecordTypeID,
      forename: record.GivenName,
      surname: record.Surname,
      district: record.District,
      quarter: QuarterDetails.quarter(record.QuarterNumber),
      year: QuarterDetails.quarter_year(record.QuarterNumber)
    }
  end

end