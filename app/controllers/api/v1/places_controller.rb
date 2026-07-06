class Api::V1::PlacesController < Api::V1::BaseController
  def index
    if params[:chapman_code].blank?
      render json: { error: 'chapman_code is required' }, status: :bad_request
      return
    end

    places = Place.chapman_code(params[:chapman_code]).not_disabled.order_by(place_name: 1)
    render json: places.as_json(only: %i[id place_name chapman_code county country])
  end
end
