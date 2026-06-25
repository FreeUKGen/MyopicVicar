class Api::V1::BatchesController < Api::V1::BaseController
  def index
    batches = Freereg1CsvFile.where(userid: @current_user.userid).order_by(uploaded_date: :desc)
    render json: batches.as_json(only: [:id, :file_name, :userid, :uploaded_date, :record_count, :error, :locked])
  end
end
