class Api::V1::CsvfilesController < Api::V1::BaseController
  def upload
    process_file('Upload')
  end

  def replace
    process_file('Replace')
  end

  def destroy
    freereg1_csv_file = Freereg1CsvFile.where(id: params[:id], userid: @current_user.userid).first

    if freereg1_csv_file.blank?
      render json: { error: 'File not found' }, status: :not_found
      return
    end

    if freereg1_csv_file.locked_by_transcriber || freereg1_csv_file.locked_by_coordinator
      render json: { error: "The removal of the batch #{freereg1_csv_file.file_name} was unsuccessful; the batch is locked." }, status: :unprocessable_entity
      return
    end

    physical_file = PhysicalFile.userid(freereg1_csv_file.userid).file_name(freereg1_csv_file.file_name).first
    physical_file&.update_attributes(file_processed: false, file_processed_date: nil)

    freereg1_csv_file.add_to_rake_delete_list
    freereg1_csv_file.save_to_attic
    freereg1_csv_file.delete

    render json: { message: "File #{freereg1_csv_file.file_name} removed" }
  end

  private

  def process_file(action)
    if params[:csvfile].blank? || params[:csvfile][:csvfile].blank?
      render json: { error: 'You must select a file' }, status: :unprocessable_entity
      return
    end

    csvfile = Csvfile.new(csvfile_params)
    csvfile.userid = @current_user.userid
    csvfile.file_name = csvfile.csvfile.identifier

    if csvfile.csvfile.identifier.blank?
      render json: { error: 'The file had an incorrect extension' }, status: :unprocessable_entity
      return
    end

    csvfile.file_name = csvfile.downcase_extension if MyopicVicar::Application.config.template_set == 'freecen'

    if csvfile.file_name.blank?
      render json: { error: 'A csv file with that name does not exist on your computer (You likely tried to upload a file with a different extension' }, status: :unprocessable_entity
      return
    end

    proceed, message = action == 'Replace' ? csvfile.setup_batch_on_replace(csvfile.file_name) : csvfile.setup_batch_on_upload

    unless proceed
      render json: { error: message }, status: :unprocessable_entity
      return
    end

    proceed, message = csvfile.process_the_batch(@current_user)
    csvfile.delete

    if proceed
      render json: { message: message }
    else
      render json: { error: message }, status: :unprocessable_entity
    end
  end

  def csvfile_params
    params.require(:csvfile).permit!
  end
end
