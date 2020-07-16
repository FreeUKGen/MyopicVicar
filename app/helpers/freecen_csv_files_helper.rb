module FreecenCsvFilesHelper

  def edit_freecen_file
    link_to 'Edit Header', edit_freecen_csv_file_path(@freecen_csv_file), method: :get, class: 'btn   btn--small'
  end

  def download_freecen_file
    link_to 'Download file', download_freecen_csv_file_path(@freecen_csv_file),
      data: { confirm: 'Are you sure you want to download these entries?' }, method: :get, class: 'btn   btn--small'
  end

  def browse_freecen_file_individuals
    link_to 'View individuals', freecen_csv_entries_path(type: 'Ind'), method: :get, class: 'btn   btn--small'
  end

  def browse_freecen_file_civil_parishes
    link_to 'View civil parishes', freecen_csv_entries_path(type: 'Civ'), method: :get, class: 'btn   btn--small'
  end
  def browse_freecen_file_pages
    link_to 'View pages', freecen_csv_entries_path(type: 'Pag'), method: :get, class: 'btn   btn--small'
  end

  def browse_freecen_file_dwellings
    link_to 'View dwellings', freecen_csv_entries_path(type: 'Dwe'), method: :get, class: 'btn   btn--small'
  end

  def list_freecen_file_error_entries
    link_to 'View error messages', freecen_csv_entries_path(type: 'Err'), method: :get, class: 'btn   btn--small'
  end

  def list_freecen_file_warning_entries
    link_to 'View warning messages', freecen_csv_entries_path(type: 'War'), method: :get, class: 'btn   btn--small'
  end

  def list_freecen_file_information_entries
    link_to 'View information messages', freecen_csv_entries_path(type: 'Inf'), method: :get, class: 'btn   btn--small'
  end

  def download_spreadsheet
    link_to 'Download Spreadsheet', download_spresdsheet_freecen_csv_file_path, method: :get, class: 'btn   btn--small'
  end

  def download_messages
    link_to 'Download Message Report', download_message_report_freecen_csv_file_path(@freecen_csv_file), method: :get, class: 'btn   btn--small'
  end

  def list_freecen_file_flags
    link_to 'View Flags', freecen_csv_entries_path(type: 'Fla'), method: :get, class: 'btn   btn--small'
  end

  def remove_freecen_file
    link_to 'Remove file', remove_freecen_csv_file_path(@freecen_csv_file), data: { confirm: 'Are you sure you want to remove this batch' }, class: 'btn   btn--small', method: :get
  end

  def replace_freecen_file
    link_to 'Replace file', edit_csvfile_path(@freecen_csv_file), method: :get,
      data: { confirm:  'Are you sure you want to replace these records?' }, class: 'btn   btn--small'
  end

  def relocate_freecen_file
    link_to 'Relocate file', relocate_freecen_csv_file_path(@freecen_csv_file),
      data: { confirm:  'Are you sure you want to relocate this batch?' }, method: :get, class: 'btn   btn--small'
  end

  def merge_freecen_files
    link_to 'Merge batches from same userid/filename into this one', merge_freecen_csv_file_path(@freecen_csv_file),
      data: { confirm: 'Are you sure you want to merge all files for the same userid and filename in this piece into this file?' }, class: 'btn   btn--small', method: :get
  end

  def reprocess_freecen_file
    link_to '(Re)Process file', reprocess_physical_file_path(@freecen_csv_file), class: 'btn   btn--small', method: :get,
      data: { confirm:  'Are you sure you want to reprocess this file?' }
  end

  def delete_freecen_file
    link_to 'Delete original file and all associated entries', freecen_csv_file_path(@freecen_csv_file),
      data: { confirm: 'Are you sure you want to remove this file and entries' }, class: 'btn   btn--small', method: :delete
  end

  def change_freecen_file_owner
    link_to 'Copy to Another Person', change_userid_freecen_csv_file_path(@freecen_csv_file),
      data: { confirm: 'Are you sure you want to copy this file ' }, class: 'btn   btn--small', method: :get
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
    piece_number = actual_piece.present? ? actual_piece.district_chapman_code : ''
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
