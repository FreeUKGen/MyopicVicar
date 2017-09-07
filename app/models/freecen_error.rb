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
    plist = []
    pcs = FreecenPiece.where(:status.nin => [nil, '', 'Online'])
    pcs.each do |pc|
      plist << "#{pc.chapman_code} filename:#{pc.freecen1_filename} #{pc.year} piece:#{pc.piece_number} suffix:#{pc.suffix} status:#{pc.status}"
    end
    pcs = FreecenPiece.where(:status => 'Online', :freecen1_filename.in=>[nil,''])
    pcs.each do |pc|
      plist << "missing-filename #{pc.chapman_code} #{pc.year} piece:#{pc.piece_number} suffix:#{pc.suffix} status:#{pc.status}"
    end

    return plist
  end
end
