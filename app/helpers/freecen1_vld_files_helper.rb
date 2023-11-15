module Freecen1VldFilesHelper

  def edit_freecen1_vld_file
    link_to 'Edit Transcriber', edit_freecen1_vld_file_path(@freecen1_vld_file, type: 'transcriber'), method: :get, class: 'btn   btn--small', title: 'Allows you to enter/edit the name of the person who transcribed the file.'
  end

  def edit_cp_freecen1_vld_file
    link_to 'Edit Civil Parishes', edit_civil_parishes_freecen1_vld_file_path(id: @freecen1_vld_file.id, type: 'civil parishes'), method: :get, class: 'btn   btn--small', title: 'Allows you to edit civil parishes for the VLD file.'
  end

  def piece_link(vld)
    piece = vld.freecen_piece
    if piece.present?
      link_to "#{vld.file_name}", freecen_piece_path(piece.id), class: 'btn   btn--small', title: 'Links to the piece'
    else
      "#{vld.file_name}"
    end
  end

  def piece_number_link(vld)
    piece = vld.freecen_piece
    if piece.present?
      link_to "#{vld.piece}", freecen_piece_path(piece.id), class: 'btn   btn--small'
    else
      "#{vld.piece}"
    end
  end

  def loaded_at(vld)
    if vld.action.present?
      vld.c_at.strftime('%Y-%m-%d %H:%M') if vld.c_at.present?
    else
      vld.id.generation_time.strftime('%Y-%m-%d %H:%M') if vld.id.present?
    end
  end

  def loaded_process(vld)
    if vld.present?
      'Upload'
    else
      'Monthly'
    end
  end

  def pob_val_status(vld)
    status = ''
    num_pob_invalid = Freecen1VldEntry.where(freecen1_vld_file_id: vld._id, pob_valid: false).count
    num_pob_valid = Freecen1VldEntry.where(freecen1_vld_file_id: vld._id, pob_valid: true).count
    if num_pob_invalid.zero? && num_pob_valid.zero?
      status = 'Not Started'
    elsif vld.num_individuals > (num_pob_invalid + num_pob_valid)
      status = 'Processing'
    elsif num_pob_invalid.positive?
      status = "#{num_pob_invalid} Invalid POBs"
    else
      status = 'All POBs are valid'
    end
    status
  end
end
