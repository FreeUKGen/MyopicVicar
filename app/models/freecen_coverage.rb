class FreecenCoverage
  require 'chapman_code'


  def self.get_index_stats
    all_years = {'1841'=>Hash.new, '1851'=>Hash.new, '1861'=>Hash.new,
      '1871'=>Hash.new, '1881'=>Hash.new, '1891'=>Hash.new}
    all_years.each do |yykey, yyhash|
      yyhash['counties'] = Hash.new
    end
    FreecenPiece.each do |piece|
      yy = piece[:year]
      cc = piece[:chapman_code]
      cty = ChapmanCode.name_from_code(cc)
      if all_years[yy]['counties'][cty].nil?
        all_years[yy]['counties'][cty] = {'yy'=>yy, 'cty'=>cty, 'cc'=>cc, 'num_rec'=>0, 'num_pieces'=>0,'num_online'=>0, 'pct_online'=>0}
      end
      all_years[yy]['counties'][cty]['num_pieces'] += 1
      piece_rec = piece[:num_individuals]
      if piece_rec > 0
        p "    piece_rec=#{piece_rec}"
        all_years[yy]['counties'][cty]['num_rec'] += piece_rec
        all_years[yy]['counties'][cty]['num_online'] += 1
      end
    end
    #grand total and subtotals
    tot_rec = 0
    tot_pieces = 0
    tot_pieces_online = 0
    all_years.each do |yrkey,yr|
      #sort counties alphabetically within each year
      yr['counties'] = yr['counties'].sort_by{ |k, v| k.nil? ? '' : k } unless yr['counties'].nil?
      #subtotals
      subtot_rec = 0
      subtot_pieces = 0
      subtot_pieces_online = 0
      yr['counties'].each do |yc_key,yr_cty|
        if yr_cty['num_online'] > 0 && yr_cty['num_pieces'] > 0
          yr_cty['pct_online'] = (100.0*yr_cty['num_online']) / yr_cty['num_pieces']
          subtot_rec += yr_cty['num_rec']
          subtot_pieces_online += yr_cty['num_online']
        end
        subtot_pieces += yr_cty['num_pieces']
      end
      yr['subtot_records_online'] = subtot_rec
      yr['subtot_pieces'] = subtot_pieces
      yr['subtot_pieces_online'] = subtot_pieces_online
      yr['subtot_pct_pieces_online'] = 0
      yr['subtot_pct_pieces_online'] = (100.0*subtot_pieces_online)/subtot_pieces if subtot_pieces > 0
      tot_rec += subtot_rec
      tot_pieces += subtot_pieces
      tot_pieces_online += subtot_pieces_online
    end
    all_years['tot_records_online'] = tot_rec
    all_years['tot_pieces'] = tot_pieces
    all_years['tot_pieces_online'] = tot_pieces_online
    all_years['tot_pct_pieces_online'] = 0
    all_years['tot_pct_pieces_online'] = (100.0*tot_pieces_online)/tot_pieces if tot_pieces > 0
    all_years['index_time'] = Time.now.getutc

    all_years
  end
  

  def self.get_county_coverage(chapman)
    all_years = {'1841'=>Hash.new, '1851'=>Hash.new, '1861'=>Hash.new,
      '1871'=>Hash.new, '1881'=>Hash.new, '1891'=>Hash.new}
    all_years.each do |yykey, yyhash|
      yyhash['pieces'] = Array.new
      yyhash['stats'] = {'yy'=>yykey, 'num_rec'=>0, 'num_pieces'=>0,'num_online'=>0, 'pct_online'=>0}
      yyhash['header'] = yykey
    end
    FreecenPiece.where(chapman_code: chapman).asc(:year, :piece_number, :suffix, :district_name, :subplaces_sort).each do |piece|
      yy = piece[:year]
      all_years[yy]['stats']['num_pieces'] += 1
      piece_rec = piece[:num_individuals]
      piece_idx = all_years[yy]['pieces'].length
      display_piece = "#{piece.piece_number}"
      display_piece += "/#{piece.suffix}" if !piece.suffix.nil? && !piece.suffix.empty?
      subplaces=''
      piece.subplaces.each do |sp|
        subplaces += ', ' if ''!= subplaces && !sp.nil? && sp != ''
        subplaces += sp if !sp.nil? && sp != ''
        p "nil subplace! piece id=#{piece._id}" if sp.nil?
        p "empty subplace! piece id=#{piece._id}" if ''==sp
      end
      all_years[yy]['pieces'][piece_idx] = {'display_piece'=>display_piece,
        'country'=>piece.place.country,'place_name'=>piece.place.place_name,'subplace_names'=>subplaces,'status'=>piece.status,'remarks'=>piece.remarks,'parish_number'=>piece.parish_number,'online_time'=>piece.online_time,'yy'=>yy,'district_name'=>piece.district_name,'place_id'=>piece.place._id}
      if piece_rec > 0
        all_years[yy]['stats']['num_rec'] += piece_rec
        all_years[yy]['stats']['num_online'] += 1
        all_years[yy]['pieces'][piece_idx]['num_individuals']=piece_rec
      end
    end

    # header text for each year (includes PRO# and info text, or Scotland)
    proref = {'1841'=>'HO107','1851'=>'HO107','1861'=>'RG9','1871'=>'RG10','1881'=>'RG11','1891'=>'RG12','1901'=>'RG13','1911'=>'RG14'}
    proref_census = {'1841'=>'England/Wales 1841 and 1851 Censuses','1851'=>'England/Wales 1841 and 1851 Censuses','1861'=>'England/Wales 1861 Census','1871'=>'England/Wales 1871 Census','1881'=>'England/Wales 1881 Census','1891'=>'England/Wales 1891 Census','1901'=>'England/Wales 1901 Census','1911'=>'England/Wales 1911 Census'}
    all_years.each do |yykey, yyhash|
      if ChapmanCode::CODES['Scotland'].values.include?(chapman)
        yyhash['header'] = "#{yykey} (Scotland)"
      elsif !proref[yykey].nil? && !proref_census[yykey].nil?
        yyhash['header'] = "#{yykey} / #{proref[yykey]}"
        yyhash['header_info'] = "#{proref[yykey]} is the Public Record Office (now The National Archives) identifier for the #{proref_census[yykey]}"
      end
    end
    all_years
  end



end
