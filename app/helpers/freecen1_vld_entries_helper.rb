module Freecen1VldEntriesHelper

  def skip_record(file_id, entry_id)
    freecen1_vld_entry = Freecen1VldEntry.where(freecen1_vld_file_id: file_id, pob_valid: false, id: {'$gt': entry_id}).order_by(dwelling_number: 1, sequence_in_household: 1).first
    if freecen1_vld_entry.blank?
      link_to 'Skip', manual_validate_pobs_freecen1_vld_file_path(id: file_id), class: 'btn btn--small', title: 'Back (this is the last invalid entry)', data: { confirm: 'Are you sure you want to Skip this record?'}
    else
      link_to 'Skip', edit_pob_freecen1_vld_entry_path(id: freecen1_vld_entry.id), class: 'btn btn--small', title: 'Move to next invalid entry', data: { confirm: 'Are you sure you want to Skip this record?'}
    end
  end
end
