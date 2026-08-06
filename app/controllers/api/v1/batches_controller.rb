class Api::V1::BatchesController < Api::V1::BaseController
  def index
    batches = Freereg1CsvFile.where(userid: @current_user.userid).order_by(uploaded_date: :desc)
    render json: batches.as_json(only: [:id, :file_name, :userid, :uploaded_date, :records, :error, :processed, :processed_date, :locked_by_transcriber, :locked_by_coordinator])
  end
end
