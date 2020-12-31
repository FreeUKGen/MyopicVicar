module FreecenCsvEntriesHelper

  def previous_list_entry
    previous_list_entry = FreecenCsvEntry.find_by(id: session[:previous_list_entry])
    link_to "Previous #{Freecen::Listings::NAMES[session[:cen_index_type]]} entry", freecen_csv_entry_path(previous_list_entry), method: :get, class: "btn btn--small",
      title: "Show the previous entry in the #{Freecen::Listings::NAMES[session[:cen_index_type]]} List" if previous_list_entry.present? && session[:cen_index_type] != 'Ind'
  end

  def next_list_entry
    next_list_entry = FreecenCsvEntry.find_by(id: session[:next_list_entry])
    link_to "Next #{Freecen::Listings::NAMES[session[:cen_index_type]]} entry", freecen_csv_entry_path(next_list_entry), method: :get, class: "btn btn--small",
      title: "Show the previous entry in the #{Freecen::Listings::NAMES[session[:cen_index_type]]} List" if next_list_entry.present? && session[:cen_index_type] != 'Ind'
  end

  def current_list_entry
    unless @freecen_csv_entry.id == session[:current_list_entry]
      current_list_entry = FreecenCsvEntry.find_by(id: session[:current_list_entry])
      link_to "Current #{Freecen::Listings::NAMES[session[:cen_index_type]]} entry", freecen_csv_entry_path(current_list_entry), method: :get, class: "btn btn--small",
        title: "Show the current entry in the #{Freecen::Listings::NAMES[session[:cen_index_type]]} List" if current_list_entry.present? && session[:cen_index_type] != 'Ind'
    end
  end

  def previous_entry
    link_to 'Previous entry', freecen_csv_entry_path(@previous_entry), method: :get, class: "btn btn--small",
      title: 'Show the previous sequential entry' if @previous_entry.present?
  end

  def next_entry
    link_to 'Next entry', freecen_csv_entry_path(@next_entry), method: :get, class: "btn btn--small",
      title: 'Show the next sequential entry'  if @next_entry.present?
  end

  def edit_entry
    unless @freecen_csv_file.incorporated
      link_to 'Edit entry', edit_freecen_csv_entry_path(@freecen_csv_entry), method: :get, class: "btn btn--small",
        title: 'Edit the individual aspects of this entry', data: { confirm: 'Are you sure you want to edit this entry' }
    end
  end

  def accept_entry
    if @file_validation && @freecen_csv_entry.record_valid.downcase == 'false' && !@freecen_csv_file.incorporated
      link_to 'Accept entry', accept_freecen_csv_entry_path(@freecen_csv_entry), method: :get, class: "btn btn--small",
        title: 'Accept the entry as correct; warnings will be removed and not recreated when reloaded',
        data: { confirm: 'Are you sure you want to accept this entry' }
    end
  end

  def propagate_alternate
    if session[:propagate_alternate].present? && session[:propagate_alternate] == @freecen_csv_entry.id
      link_to 'Propagate Alternate Fields', propagate_alternate_freecen_csv_entry_path(@freecen_csv_entry), method: :get, class: "btn btn--small",
        title: 'Propagates the alternate fields to entries with the same verbatim fields as this entry',
        data: { confirm: 'Are you sure you want to propagate this entry' }
    end
  end

  def reject_entry
    if @file_validation && @freecen_csv_entry.record_valid.downcase == 'true' && !@freecen_csv_file.incorporated
      link_to 'Force Review', revalidate_freecen_csv_entry_path(@freecen_csv_entry), method: :get, class: "btn btn--small",
        title: 'Force review of this entry even though accepted or true', data: { confirm: 'Are you sure you want to force a reprocessing of this entry' }
    end
  end

  def folio(entry)
    Freecen::LOCATION_FOLIO.include?(entry.data_transition) ? entry.folio_number : ''
  end
end
