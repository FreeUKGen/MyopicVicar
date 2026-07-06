class Api::V1::CountiesController < Api::V1::BaseController
  require 'register_type'

  def index
    counties = County.application_counties
    render json: counties.as_json(only: %i[id chapman_code county_description])
  end

  def register_types
    render json: RegisterType::APPROVED_OPTIONS
  end
end
