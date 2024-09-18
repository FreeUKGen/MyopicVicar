# frozen_string_literal: true
class ApiResponseController < ApplicationController
  skip_before_action :require_login
  skip_before_action :verify_authenticity_token

  def api_response_as_json
    response = ApiResponse.new
    query = SearchQuery.new
    search_params = params.select{ |parm| not( parm['controller'] or parm['action'])}
    query.last_name = params[:LastName] if params[:LastName].present?
    query.first_name = params[:FirstName] if params[:FirstName].present?
    query.districts << params[:DistrictNumber] if params[:DistrictNumber].present?
    query.bmd_record_type << params[:RecordTypeId] if params[:RecordTypeId].present?
    #raise query.inspect
    query.search_records
    response.request << search_params
    response.total = query.result_count
    #raise query.search_result.inspect
    start = 0
    start = params[:start].to_i if params[:start].present?
    limit = 10
    limit = params[:limit].to_i if params[:limit].present?
    response.start = start
    response.limit = limit
    return_selected_range(query.search_result.records, start, limit, response.matches)
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

end
