class Api::V1::CsvfilesController < Api::V1::BaseController
  def upload
    csvfile = build_csvfile
    return unless csvfile

    proceed, message = csvfile.setup_batch_on_upload
    return render_result(false, message) unless proceed

    process_csvfile(csvfile)
  end

  def replace
    csvfile = build_csvfile
    return unless csvfile

    proceed, message = csvfile.setup_batch_on_replace(csvfile.file_name)
    return render_result(false, message) unless proceed

    process_csvfile(csvfile)
  end

  def destroy
    freereg1_csv_file = Freereg1CsvFile.where(id: params[:id], userid: @current_user.userid).first
    return render_result(false, 'The file was not found for your userid', status: :not_found) if freereg1_csv_file.blank?

    ok, message = freereg1_csv_file.check_file
    return render_result(false, message) unless ok

    if freereg1_csv_file.locked_by_transcriber || freereg1_csv_file.locked_by_coordinator
      return render_result(false, "The removal of the batch #{freereg1_csv_file.file_name} was unsuccessful; the batch is locked.")
    end

    physical_file = PhysicalFile.userid(@current_user.userid).file_name(freereg1_csv_file.file_name).first
    freereg1_csv_file.add_to_rake_delete_list
    physical_file.update_attributes(file_processed: false, file_processed_date: nil) if physical_file.present?
    freereg1_csv_file.save_to_attic
    freereg1_csv_file.delete

    render_result(true, "File #{freereg1_csv_file.file_name} removed")
  end

  private

  def build_csvfile
    if params[:csvfile].blank?
      render_result(false, 'You must select a file', status: :bad_request)
      return nil
    end

    csvfile = Csvfile.new
    csvfile.userid = @current_user.userid
    csvfile.csvfile = params[:csvfile]
    csvfile.file_name = csvfile.csvfile.identifier

    if csvfile.file_name.blank?
      render_result(false, 'The file had an incorrect extension', status: :bad_request)
      return nil
    end

    csvfile
  end

  def process_csvfile(csvfile)
    proceed, message = csvfile.process_the_batch(@current_user)
    csvfile.delete
    render_result(proceed, message)
  end

  def render_result(success, message, status: :ok)
    render json: { result: success ? 'success' : 'failure', message: message }, status: status
  end
end
