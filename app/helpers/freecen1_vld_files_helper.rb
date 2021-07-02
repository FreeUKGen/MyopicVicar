module Freecen1VldFilesHelper

  def edit_freecen1_vld_file
    link_to 'Edit Transcriber', edit_freecen1_vld_file_path(@freecen1_vld_file, type: 'transcriber'), method: :get, class: 'btn   btn--small', title: 'Allows you to enter/edit the name of the person who transcribed the file.'
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
      vld.u_at.strftime('%Y-%m-%d %H:%M') if vld.u_at.present?
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

end
