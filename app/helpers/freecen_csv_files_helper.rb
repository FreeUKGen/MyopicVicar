module FreecenCsvFilesHelper

  def edit_freecen_file
    link_to 'Edit Header', edit_freecen_csv_file_path(@freecen_csv_file), method: :get, class: 'btn   btn--small', title: 'Allows you to Lock/Unlock file  and enter/edit the name of the person who transcribed the file.'
  end

  def download_freecen_file
    link_to 'Download file', download_freecen_csv_file_path(@freecen_csv_file),
      data: { confirm: 'Are you sure you want to download these entries?' }, method: :get, class: 'btn   btn--small', title: 'Download a copy of the file to your computer. This download WILL INCLUDE and on line changes. Downloading will remove any locks. It will be be stored in your downloads folder'
  end

  def convert_header
    if @freecen_csv_file.traditional.zero?
      link_to 'Convert to modern headers and download', modern_headers_freecen_csv_file_path(@freecen_csv_file),
        data: { confirm: 'Are you sure you want to convert the header of this file?' }, method: :get, class: 'btn   btn--small', title: 'Converts the file headers from the old format to the modern one used in proofreading, validation and incorporation.'  if @freecen_csv_file.traditional.zero?
    end
  end

  def browse_freecen_file_individuals
    link_to 'View individuals', freecen_csv_entries_path(type: 'Ind'), method: :get, class: 'btn   btn--small', title: 'Lists each entry that has individual information. Any of the entries can be displayed on line'
  end

  def browse_freecen_file_civil_parishes
    link_to 'View civil parishes', freecen_csv_entries_path(type: 'Civ'), method: :get, class: 'btn   btn--small', title: 'Lists each entry that contained a new civil parish. Any of the entries can be displayed on line'
  end
  def browse_freecen_file_pages
    link_to 'View pages', freecen_csv_entries_path(type: 'Pag'), method: :get, class: 'btn   btn--small', title: 'Lists each entry that contained a new folio or page number. Any of the entries can be displayed on line'
  end

  def browse_freecen_file_dwellings
    link_to 'View dwellings', freecen_csv_entries_path(type: 'Dwe'), method: :get, class: 'btn   btn--small', title: 'Lists each entry that has a new dwelling. Any of the entries can be displayed on line'
  end

  def list_freecen_file_error_entries
    unless  @freecen_csv_file.total_errors.zero?
      link_to 'View error messages', freecen_csv_entries_path(type: 'Err'), method: :get, class: 'btn   btn--small', title: 'Lists the entry numbers which have generated an error message. Any of the entries can be displayed on line'
    end
  end

  def list_freecen_file_warning_entries
    unless  @freecen_csv_file.total_warnings.zero?
      link_to 'View warning messages', freecen_csv_entries_path(type: 'War'), method: :get, class: 'btn   btn--small', title: 'Lists the entry numbers which have generated a warning message. Any of the entries can be displayed on line'
    end
  end

  def list_freecen_file_information_entries
    unless  @freecen_csv_file.total_info.zero?
      link_to 'View information messages', freecen_csv_entries_path(type: 'Inf'), method: :get, class: 'btn   btn--small', title: 'Lists the entry numbers which have generated an information message. Any of the entries can be displayed on line'
    end
  end

  def download_spreadsheet
    link_to 'Download Spreadsheet', download_spresdsheet_freecen_csv_file_path, method: :get, class: 'btn   btn--small', title: 'Lists the available census spreadsheet headers that can be downloaded to your computer and used for the transcription of a census document'
  end

  def download_messages
    link_to 'Download Message Report', download_message_report_freecen_csv_file_path(@freecen_csv_file), method: :get, class: 'btn   btn--small', title: 'Download a copy of the processing messages to your computer. It will be be stored in your downloads folder'
  end

  def list_freecen_file_flags
    link_to 'View Flags', freecen_csv_entries_path(type: 'Fla'), method: :get, class: 'btn   btn--small', title: 'Lists the entry numbers where any flag is set. Any of the entries can be displayed on line'
  end

  def remove_freecen_file
    link_to 'Remove file', remove_freecen_csv_file_path(@freecen_csv_file), data: { confirm: 'Are you sure you want to remove this batch' },
      class: 'btn   btn--small', method: :get,
      title: 'Removes the file and its entries and schedules their actual deletion overnight. Cannot be done if the coordinator has published its contents into the search database'
  end

  def replace_freecen_file
    link_to 'Replace file', edit_csvfile_path(@freecen_csv_file), method: :get, data: { confirm:  'Are you sure you want to replace these records?' },
      class: 'btn   btn--small', title: 'Allows the complete replacement of the csv file and all of its entries. Will not be permitted if the file is locked '
  end

  def relocate_freecen_file
    link_to 'Relocate file', relocate_freecen_csv_file_path(@freecen_csv_file),
      data: { confirm:  'Are you sure you want to relocate this batch?' }, method: :get, class: 'btn   btn--small'
  end

  def merge_freecen_files
    link_to 'Merge batches from same userid/filename into this one', merge_freecen_csv_file_path(@freecen_csv_file),
      data: { confirm: 'Are you sure you want to merge all files for the same userid and filename in this piece into this file?' },
      class: 'btn   btn--small', method: :get
  end

  def reprocess_freecen_file
    link_to '(Re)Process file', reprocess_physical_file_path(@freecen_csv_file), class: 'btn   btn--small', method: :get,
      title: 'Submits the file for processing. The report will go to the owner of the file', data: { confirm:  'Are you sure you want to reprocess this file?' }
  end

  def delete_freecen_file
    link_to 'Delete original file and all associated entries', freecen_csv_file_path(@freecen_csv_file),
      data: { confirm: 'Are you sure you want to remove this file and entries' }, class: 'btn   btn--small', method: :delete,
      title: 'This performs an immediate deletion of the file and its entries. Use with EXTREME care'
  end

  def change_freecen_file_owner
    link_to 'Copy to Another Person', change_userid_freecen_csv_file_path(@freecen_csv_file),
      data: { confirm: 'Are you sure you want to copy this file ' }, class: 'btn   btn--small', method: :get,
      title: 'Copies the file (and any on line edits) to a proofreader or validator or yourself. The file will be processed and the report sent.'
  end

  def accept_warnings
    link_to 'Accept all warnings', accept_warnings_freecen_csv_file_path(@freecen_csv_file),
      data: { confirm: 'Are you sure you want to accept all warning messages ' }, class: 'btn   btn--small', method: :get,
      title: 'Accepts all warning messages.'
  end


  def validate_freecen_file
    validation_heading = @freecen_csv_file.validation ? 'Validation under way' : 'Commence validation'
    link_to "#{validation_heading}", set_validation_freecen_csv_file_path(@freecen_csv_file), class: 'btn   btn--small', method: :get,
      title: 'Validation of file', data: { confirm:  'Are you sure you want to commence validation of the file?' }
  end

  def incorporate_freecen_file
    unless @freecen_csv_file.incorporated
      if @freecen_csv_file.completes_piece
        link_to 'Incorporate file', incorporate_freecen_csv_file_path(@freecen_csv_file, completes_piece: true), class: 'btn   btn--small', method: :get,
          title: 'Incorporates the records into the database and sets piece status to Online', data: { confirm:  'Are you sure you want to commence incorporation of the file?' }
      else
        link_to 'Incorporate file', incorporate_partial_freecen_csv_file_path(@freecen_csv_file), class: 'btn   btn--small', method: :get,
          title: 'Checks if partial piece file is last for the piece'
      end
    else
      get_user_info_from_userid
      link_to 'Remove records from database', unincorporate_freecen_csv_file_path(@freecen_csv_file, @user.userid), class: 'btn   btn--small', method: :get,
        title: 'Removes all of the records from the database', data: { confirm:  'Are you sure you want to remove all of the records from the database?' }
    end
  end

  def freecen_file_errors(file)
    if file.error > 0
      link_to "#{file.error}", error_freecen_csv_file_path(file.id)
    else
      'Zero'
    end
  end
  def freecen2_piece_number(file)
    actual_piece = file.freecen2_piece
    piece_number = actual_piece.present? ? actual_piece.number : ''
  end

  def freecen2_chapman(file)
    actual_piece = file.freecen2_piece
    piece_number = actual_piece.present? ? actual_piece.chapman_code : ''
  end

  def freecen2_year(file)
    actual_piece = file.freecen2_piece
    piece_number = actual_piece.present? ? actual_piece.year : ''
  end

  def freecen2_district_name(file)
    actual_piece = file.freecen2_piece
    piece_number = actual_piece.present? ? actual_piece.district_name : ''
  end
end
