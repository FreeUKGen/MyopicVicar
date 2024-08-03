module FreecenCsvEntriesHelper

  def previous_list_entry
    unless @freecen_csv_entry.id == session[:previous_list_entry]
      previous_list_entry = FreecenCsvEntry.find_by(id: session[:previous_list_entry])
      link_to "Previous #{Freecen::Listings::NAMES[session[:cen_index_type]]} entry", freecen_csv_entry_path(previous_list_entry), method: :get, class: "btn btn--small",
        title: "Show the previous entry in the #{Freecen::Listings::NAMES[session[:cen_index_type]]} List" if previous_list_entry.present? && session[:cen_index_type] != 'Ind'
    end
  end

  def next_list_entry
    unless @freecen_csv_entry.id == session[:next_list_entry]
      next_list_entry = FreecenCsvEntry.find_by(id: session[:next_list_entry])
      link_to "Next #{Freecen::Listings::NAMES[session[:cen_index_type]]} entry", freecen_csv_entry_path(next_list_entry), method: :get, class: "btn btn--small",
        title: "Show the next in the #{Freecen::Listings::NAMES[session[:cen_index_type]]} List" if next_list_entry.present? && session[:cen_index_type] != 'Ind'
    end
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
    return if session[:propagate_alternate] == session[:propagated_alternate]

    if session[:propagate_alternate].present? && session[:propagate_alternate] == @freecen_csv_entry.id && @year != '1841' && @freecen_csv_entry.record_valid.downcase == 'true'
      link_to 'Propagate Alternate POB Fields', propagate_pob_freecen_csv_entry_path(id: @freecen_csv_entry._id, propagation_fields: 'Alternative'), method: :get, class: "btn btn--small",
        title: 'Allows you to specify the scope of Propagation the alternative POB fields',
        data: { confirm: 'Are you sure you want to Propagate the Alternate POB of this entry' }
    end
  end

  def propagate_note
    if session[:propagate_note].present? && session[:propagate_note] == @freecen_csv_entry.id
      link_to 'Propagate Notes Field', propagate_pob_freecen_csv_entry_path(id: @freecen_csv_entry._id, propagation_fields: 'Notes'), method: :get, class: "btn btn--small",
        title: 'Allows you to specify the scope of Propagation the Notes fields',
        data: { confirm: 'Are you sure you want to Propagate the Notes of this entry' }
    end
  end

  def propagate_both
    return if session[:propagate_alternate] == session[:propagated_alternate]

    if session[:propagate_alternate].present? && session[:propagate_note].present? && session[:propagate_alternate] == @freecen_csv_entry.id && @year != '1841' && @freecen_csv_entry.record_valid.downcase == 'true'
      link_to 'Propagate POB and Notes Field', propagate_pob_freecen_csv_entry_path(id: @freecen_csv_entry._id, propagation_fields: 'Both'), method: :get, class: "btn btn--small",
        title: 'Allows you to specify the scope of Propagation the alternative POB and Notes fields',
        data: { confirm: 'Are you sure you want to Propagate the Alternate POB and Notes of this entry' }
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
