class Api::V1::ChurchesController < Api::V1::BaseController
  def index
    if params[:place_id].blank?
      render json: { error: 'place_id is required' }, status: :bad_request
      return
    end

    churches = Church.where(place_id: params[:place_id])
    render json: churches.as_json(only: %i[id church_name place_id])
  end
end
