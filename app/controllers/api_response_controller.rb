# frozen_string_literal: true
class ApiResponseController < ApplicationController
  skip_before_action :require_login
  skip_before_action :verify_authenticity_token

  # need to map comma-separated District numbers to target array: done
  # Record types hit a problem when split is applied to the parameter value
  # Ideally, also allow searching on District names and counties
  # Alternatively, provide API support for querying District names and counties
  # and getting back a comma-separated list of District numbers
  # Need to support date-based searches, including 'fudge factor' support: done
  # Would be good to return the persistent URL for the record
  # Support the fields parameter; provide a default set of fields
  def api_response_as_json
    response = ApiResponse.new
    query = SearchQuery.new
    search_params = params.select{ |parm| not( parm['controller'] or parm['action'])}
    query.last_name = params[:LastName] if params[:LastName].present?
    query.first_name = params[:FirstName] if params[:FirstName].present?
    query.districts << params[:DistrictNumber].split(',') if params[:DistrictNumber].present?
    query.bmd_record_type << params[:RecordTypeId] if params[:RecordTypeId].present?
    if params[:StartDate].present?
      query.start_year = params[:StartDate]
    elsif params[:EventDate].present?
      query.start_year = params[:EventDate]
    end
    if params[:EndDate].present?
      query.end_year = params[:EndDate]
    elsif params[:EventDate].present?
      query.end_year = params[:EventDate]
    end
    if params[:dateSpread].present?
      date_spread = params[:dateSpread].to_i / 2
      if query.start_year
        query.start_year = query.start_year - date_spread
      end
      if query.end_year
        query.end_year = query.end_year + date_spread
      end
    end
    #raise date_spread.inspect
    query.search_records
    response.request << search_params
    response.total = query.result_count
    #raise query.search_result.records.inspect
    start = 0
    start = params[:start].to_i if params[:start].present?
    limit = 10
    limit = params[:limit].to_i if params[:limit].present?
    response.start = start
    response.limit = limit
    return_selected_range(query.search_result.records.values, start, limit, response.matches)
    render json: response
  end

  private

  def return_selected_range(records, start, limit, matches)
    i = 0
    output = 0
    records.each do |record|
      output_this_one = (i >= start and output < limit)
      matches << record if output_this_one
      i += 1
      output += 1 if output_this_one
    end
  end

  def year_to_start_quarter(year)
    quarter = 4*(year.to_i - 1837) + 1
    quarter
  end

  def year_to_end_quarter(year)
    quarter = 4*(year.to_i - 1837) + 4
    quarter
  end

end
