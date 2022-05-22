desc 'List orphan freecen1 vld files'
task List_fc_orphan_VLD_files:  :environment do

  file_for_warning_messages = "#{Rails.root}/log/List_fc_orphan_VLD_files.txt"
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  output_file = File.new(file_for_warning_messages, 'w')

  output_file.puts "Started listing of orphan freecen1 vld files (#{Time.now})"
  output_file.puts 'Chapman_code,File_name,Userid,Freecen_piece_id,Freecen2_piece_id,Message'

  time_start = Time.now


  p "*** Started listing of orphan freecen1 vld files at #{time_start}"

  vld_recs = 0
  total_orphans = 0

  ChapmanCode.merge_counties.each do |chapman_code|
    this_county = chapman_code
    county_recs = 0
    orphan_recs = 0
    vld_files = Freecen1VldFile.where(dir_name: chapman_code).order_by(file_name: 1)
    vld_files.each do |vld|
      this_county = vld.dir_name unless county_recs.positive?
      fc_piece_found = false
      fc2_piece_found = false
      message = ''
      fc_piece = FreecenPiece.find_by(_id: vld.freecen_piece_id)
      fc_piece_found = true if fc_piece.present?
      fc2_piece = Freecen2Piece.find_by(_id: vld.freecen2_piece_id)
      fc2_piece_found = true if fc2_piece.present?
      message = 'Freecen Piece Not found' if vld.freecen_piece_id.present? && fc_piece_found == false
      if vld.freecen2_piece_id.present? && fc2_piece_found == false
        message = message.length.positive? ? "#{message} and Freecen2 Piece Not found" : 'Freecen2 Piece Not found'
      end
      if message.length.positive?
        output_file.puts "#{vld.dir_name}, #{vld.file_name}, #{vld.userid}, #{vld.freecen_piece_id}, #{vld.freecen2_piece_id}, #{message}"
      end
      orphan_recs += 1 if message.length.positive?
      county_recs += 1
      vld_recs += 1
    end
    p  "#{this_county} - #{county_recs} vld records found" if county_recs.zero?
    p  "#{this_county} - #{county_recs} vld records processed - #{orphan_recs} orphan records found" if county_recs.positive?
    total_orphans += orphan_recs
  end

  time_elapsed = Time.now - time_start

  p "*** Finished listing of orphan freecen1 vld files - #{vld_recs} VLD records processed, found #{total_orphans} VLD files with orphans in #{time_elapsed} secs"

  output_file.puts "Finished listing of orphan freecen1 vld files - #{vld_recs} VLD records processed, found #{total_orphans} VLD files with orphans in #{time_elapsed} secs"

  output_file.close
end
