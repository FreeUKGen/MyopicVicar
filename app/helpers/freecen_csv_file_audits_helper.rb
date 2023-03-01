module FreecenCsvFileAuditsHelper
  def csv_audit_piece_link(file_name, piece_id)
    piece = Freecen2Piece.find_by(id: piece_id)
    if piece.present?
      link_to "#{file_name}", freecen2_piece_path(piece.id), class: 'btn   btn--small', title: 'Links to the FreeCEN2 Piece'
    else
      "#{file_name}"
    end
  end

  def csv_audit_loaded_at(load_date)
    load_date.strftime('%Y-%m-%d %H:%M')  if load_date.present?
  end


  def csv_audit_action_on(action_date)
    action_date.strftime('%Y-%m-%d %H:%M')  if action_date.present?
  end


  def csv_audit_csv_files_piece_unincorporated(piece_id)
    piece = Freecen2Piece.find_by(id: piece_id)
    if piece.freecen_csv_files.present?
      files = []
      piece.freecen_csv_files.incorporated(false).order_by(file_name: 1).each do |file|
        if file.userid.blank?
          files << file.file_name + ' ()'
        else
          files << file.file_name + ' (' + file.userid + ')'
        end
      end
      files.length > 0 ? files : 'None'
    else
      'None'
    end
  end

  def csv_audit_csv_files_piece_incorporated(piece_id)
    piece = Freecen2Piece.find_by(id: piece_id)
    if piece.freecen_csv_files.present?
      files = []
      piece.freecen_csv_files.incorporated(true).order_by(file_name: 1).each do |file|
        if file.userid.blank?
          files << file.file_name + ' ()'
        else
          files << file.file_name + ' (' + file.userid + ')'
        end
      end
      files.length > 0 ? files : 'None'
    else
      'None'
    end
  end
end
