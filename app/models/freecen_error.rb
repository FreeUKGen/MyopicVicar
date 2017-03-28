class FreecenError
  require 'freecen1_vld_file'
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
end
