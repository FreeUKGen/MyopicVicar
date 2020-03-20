module FreecenCsvFilesHelper

  def edit_freecen_file
    link_to 'Edit', edit_freecen_csv_file_path(@freecen_csv_file), method: :get, class: 'btn   btn--small'
  end

  def download_freecen_file
    link_to 'Download file', download_freecen_csv_file_path(@freecen_csv_file),
      data: { confirm: 'Are you sure you want to download these records?' }, method: :get, class: 'btn   btn--small'
  end

  def browse_freecen_file_entries
    link_to 'Browse entries', freecen_csv_entries_path, method: :get, class: 'btn   btn--small'
  end

  def list_freecen_file_error_entries
    link_to 'Listing of error entries', error_freecen_csv_file_path(@freecen_csv_file), method: :get, class: 'btn   btn--small'
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
    link_to 'Change owner (userid)', change_userid_freecen_csv_file_path(@freecen_csv_file),
      data: { confirm: 'Are you sure you want to move this file ' }, class: 'btn   btn--small', method: :get
  end

  def freecen_file_errors(file)
    if file.error > 0
      link_to "#{file.error}", error_freecen_csv_file_path(file.id)
    else
      'Zero'
    end
  end
end
