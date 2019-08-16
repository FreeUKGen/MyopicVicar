class FreecenError
  require 'freecen1_vld_file'
  require 'freecen_piece'

  def self.get_errors_list
    errlist = []
    vlds = Freecen1VldFile.where(:file_errors.ne => nil)
    vlds.each do |vld|
      vld.file_errors.each do |ferr|
        errlist << ferr unless ferr.blank?
      end unless vld.file_errors.blank?
    end unless vlds.blank?
    return errlist
  end

  def self.get_pieces_not_loaded_list
    piece_error_list = {}
    piece_error_list[:not_online] = []
    piece_error_list[:no_freecen1_filename] = []
    piece_error_list[:error_status] = []
    pcs = FreecenPiece.where(:status.nin => [nil, '', 'Online'])
    pcs.each do |pc|
      piece_error_list[:not_online] << pc.id
    end
    pcs = FreecenPiece.where(status: 'Error')
    pcs.each do |pc|
      piece_error_list[:error] << pc.id
    end
    pcs = FreecenPiece.where(:status => 'Online', :freecen1_filename.in=>[nil,''])
    pcs.each do |pc|
      piece_error_list[:no_freecen1_filename] << pc.id unless piece_error_list[:error].include?(pc.id)
    end
    piece_error_list
  end
end
