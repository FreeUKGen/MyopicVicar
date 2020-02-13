module Freereg1CsvFilesHelper
  def coordinator_index_breadcrumbs
    if session[:place_name].present?
      breadcrumb :files
    elsif session[:syndicate] && session[:sorted_by] == '; selects files with zero date records then alphabetically by userid and file name'
      breadcrumb :listing_of_zero_year_files
    elsif session[:county] && session[:sorted_by] == '; selects files with zero date records then alphabetically by userid and file name'
      breadcrumb :listing_of_zero_year_files
    else
      breadcrumb :files
    end
  end

  def my_own_files_breadcrumbs
    if session[:sorted_by] == 'Zero years'
      breadcrumb :listing_of_zero_year_files
    else
      breadcrumb :my_own_files
    end
  end

  def can_view_files?(role)
    %w[county_coordinator syndicate_coordinator country_coordinator system_administrator technical
       data_manager volunteer_coordinator documentation_coordinator].include?(role)
  end

  def sorted_by?(sort)
    sort == '; sorted by descending number of errors and then file name'
  end

  def edit_headers
    link_to 'Edit headers', edit_freereg1_csv_file_path(@freereg1_csv_file), method: :get, class: 'btn   btn--small'
  end

  def download_batch
    link_to 'Download batch', download_freereg1_csv_file_path(@freereg1_csv_file),
      data: { confirm: 'Are you sure you want to download these records?' }, method: :get, class: 'btn   btn--small'
  end

  def browse_batch_entries
    link_to 'Browse entries', freereg1_csv_entries_path, method: :get, class: 'btn   btn--small'
  end

  def list_error_entries
    link_to 'Listing of error entries', error_freereg1_csv_file_path(@freereg1_csv_file), method: :get, class: 'btn   btn--small'
  end

  def list_zero_year_entries
    link_to 'Listing of zero year entries', zero_year_freereg1_csv_file_path(@freereg1_csv_file), method: :get, class: 'btn   btn--small'
  end

  def list_embargoed_entries
    link_to 'Listing of embargoed entries', embargoed_entries_freereg1_csv_file_path(@freereg1_csv_file), method: :get, class: 'btn   btn--small'
  end

  def unique_names
    link_to 'Unique names', unique_names_freereg1_csv_file_path(object: @freereg1_csv_file.id), method: :get, class: 'btn   btn--small'
  end

  def remove_batch
    link_to 'Remove batch', remove_freereg1_csv_file_path(@freereg1_csv_file),  data: { confirm: 'Are you sure you want to remove this batch' }, class: 'btn   btn--small', method: :get
  end

  def replace_batch
    link_to 'Replace batch', edit_csvfile_path(@freereg1_csv_file), method: :get,
      data: { confirm:  'Are you sure you want to replace these records?' }, class: 'btn   btn--small'
  end

  def relocate_batch
    link_to 'Relocate batch', relocate_freereg1_csv_file_path(@freereg1_csv_file),
      data: { confirm:  'Are you sure you want to relocate this batch?' }, method: :get, class: 'btn   btn--small'
  end

  def merge_batches
    link_to 'Merge batches from same userid/filename into this one', merge_freereg1_csv_file_path(@freereg1_csv_file),
      data: { confirm: 'Are you sure you want to merge all batches for the same userid and filename in this register into this batch?' }, class: 'btn   btn--small', method: :get
  end

  def reprocess_batch
    link_to '(Re)Process batch', reprocess_physical_file_path(@freereg1_csv_file), class: 'btn   btn--small', method: :get,
      data: { confirm:  'Are you sure you want to reprocess this file?' }
  end

  def delete_file
    link_to 'Delete original file and all associated batch entries', freereg1_csv_file_path(@freereg1_csv_file),
      data: { confirm: 'Are you sure you want to remove this file and batch entries' }, class: 'btn   btn--small', method: :delete
  end

  def change_owner
    link_to 'Change owner (userid)', change_userid_freereg1_csv_file_path(@freereg1_csv_file),
      data: { confirm: 'Are you sure you want to move this file ' }, class: 'btn   btn--small', method: :get
  end

  def which_file_gaps_link(gaps)
    file = @freereg1_csv_file.id
    if gaps
      link_to 'List Gaps', gaps_path(register: @register, freereg1_csv_file: file), method: :get, class: 'btn   btn--small'
    elsif @freereg1_csv_file.register_type == 'PR'
      link_to 'Create Gap', new_gap_path(register: @register, freereg1_csv_file: file), method: :get, class: 'btn  btn--small'
    end
  end

  def file_format_ucf_list(record)
    search = SearchRecord.find_by(_id: record.to_s)
    entry = search.freereg1_csv_entry if search.present?
    if entry.present?
      link_to "#{entry.id.to_s}", freereg1_csv_entry_path(entry.id.to_s, from: 'batch'), method: :get
    end
  end
end
