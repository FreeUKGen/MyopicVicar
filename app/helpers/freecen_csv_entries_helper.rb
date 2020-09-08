module FreecenCsvEntriesHelper

  def previous_list_entry
    previous_list_entry = FreecenCsvEntry.find_by(id: session[:previous_list_entry])
    link_to "Previous #{Freecen::Listings::NAMES[session[:cen_index_type]]} entry", freecen_csv_entry_path(previous_list_entry), method: :get, class: "btn btn--small",
      title: 'Show the previous entry in the View List' if previous_list_entry.present? && session[:cen_index_type] != 'Ind'
  end

  def next_list_entry
    next_list_entry = FreecenCsvEntry.find_by(id: session[:next_list_entry])
    link_to "Next #{Freecen::Listings::NAMES[session[:cen_index_type]]} entry", freecen_csv_entry_path(next_list_entry), method: :get, class: "btn btn--small",
      title: 'Show the previous entry in the View List' if next_list_entry.present? && session[:cen_index_type] != 'Ind'
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
    link_to 'Edit entry', edit_freecen_csv_entry_path(@freecen_csv_entry), method: :get, class: "btn btn--small",
      title: 'Edit the individual aspects of this entry', data: { confirm: 'Are you sure you want to edit this entry' }
  end

  def accept_entry
    if @freecen_csv_entry.file_validation && @freecen_csv_entry.record_valid == 'false'
      link_to 'Accept entry', accept_freecen_csv_entry_path(@freecen_csv_entry), method: :get, class: "btn btn--small",
        title: 'Accept the entry as correct; warnings will be removed and not recreated when reloaded',
        data: { confirm: 'Are you sure you want to accept this entry' }
    end
  end

  def reject_entry
    if @freecen_csv_entry.file_validation && @freecen_csv_entry.record_valid == 'true'

      link_to 'Force Review', revalidate_freecen_csv_entry_path(@freecen_csv_entry), method: :get, class: "btn btn--small",
        title: 'Force review of this entry even though accepted or true', data: { confirm: 'Are you sure you want to force a reprocessing of this entry' }
    end
  end
end
