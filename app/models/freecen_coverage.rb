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
      next if yy.blank?
      cc = piece[:chapman_code]
      cty = ChapmanCode.name_from_code(cc)
      if all_years[yy]['counties'][cty].nil?
        all_years[yy]['counties'][cty] = {'yy'=>yy, 'cty'=>cty, 'cc'=>cc, 'num_rec'=>0, 'num_pieces'=>0,'num_online'=>0, 'pct_online'=>0}
      end
      all_years[yy]['counties'][cty]['num_pieces'] += 1
      piece_rec = piece[:num_individuals]
      if piece_rec > 0
        #p "    piece_rec=#{piece_rec}"
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
      next if yy.blank?
      all_years[yy]['stats']['num_pieces'] += 1
      piece_rec = piece[:num_individuals]
      piece_idx = all_years[yy]['pieces'].length
      display_piece = "#{piece.piece_number}"
      display_piece += "/#{piece.suffix}" if !piece.suffix.blank?
      subplaces=[]
      if piece.subplaces.kind_of?(Array) #in case mangled into a string by form
        piece.subplaces.each do |sp|
          subplaces << sp unless sp.nil? || sp['name'].blank?
          p "nil subplace! piece id=#{piece._id}" if sp.nil? || sp['name'].nil?
          p "empty subplace! piece id=#{piece._id}" if !sp.nil? && sp['name'].blank?
        end
      end
      all_years[yy]['pieces'][piece_idx] = {'display_piece'=>display_piece,
        'country'=>piece.place_country,'latitude'=>piece.place_latitude,'longitude'=>piece.place_longitude,'subplaces'=>subplaces,'status'=>piece.status,'remarks'=>piece.remarks,'parish_number'=>piece.parish_number,'online_time'=>piece.online_time,'yy'=>yy,'district_name'=>piece.district_name,'place_id'=>piece.place._id,'piece_id'=>piece._id}
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
      if 'SCS'==chapman||ChapmanCode::CODES['Scotland'].values.include?(chapman)
        yyhash['header'] = "#{yykey} (Scotland)"
      elsif !proref[yykey].nil? && !proref_census[yykey].nil?
        yyhash['header'] = "#{yykey} / #{proref[yykey]}"
        yyhash['header_info'] = "#{proref[yykey]} is the Public Record Office (now The National Archives) identifier for the #{proref_census[yykey]}"
      end
    end
    all_years
  end


  #leave year blank for all years. leave chapman blank for all counties.
  #'ind'=return results as # of individuals, 'pct'=percent of pieces complete
  def self.get_graph_data_from_stats_file(stats_file, chapman, year, ind_or_pct)
    values_at_time = []
    year = nil if 'all' == year
    chapman = nil if 'all' == chapman
    first_time = 0
    max_value = 0
    prev_value = 0
    lines = File.readlines(stats_file)
    lines.each do |line|
      tstamp = line.to_i
      first_time = tstamp if 0==first_time
      label = " "
      label += "#{year}-" unless year.blank?
      label += "#{chapman}-" unless chapman.blank?
      label += "#{ind_or_pct}:"
      idx = line.index(label)
      unless idx.nil?
        idx += label.length
        value = ('ind'==ind_or_pct) ? line[idx,16].to_i : line[idx,16].to_f
        values_at_time << [tstamp,value] unless value==prev_value
        prev_value = value
        max_value = value if value > max_value
      end
    end
    values_at_time = values_at_time.sort_by {|k| k[0]}
    {'values_at_time'=>values_at_time, 'max'=>max_value, 'first_time'=>first_time, 'chapman'=>chapman, 'year'=>year}
  end

  def self.calculateGraphParms(first_timestamp, last_timestamp, max_y, max_x_ticks=40, ind_or_pct='ind')
    # decide the xtick interval, adjust the first/last times to start and stop
    # on interval boundaries
    ft = Time.at(first_timestamp)
    lt = Time.at(last_timestamp)
    minmon = ft.utc.month
    minyear = ft.utc.year
    maxmon = lt.utc.month
    maxyear = lt.utc.year
    if maxmon > 12
      maxmon -= 12
      maxyear += 1
    end
    xinterval=1
    xintervals = [1,2,3,6,12,24,36,48,60,72,84,96,108,120,240,480,960]
    x_ticks = max_x_ticks+1
    while x_ticks > max_x_ticks && xintervals.length > 0
      xinterval = xintervals.shift
      monmin = (minmon/xinterval)*xinterval+1
      first_timestamp = Time.utc(minyear,monmin,1,12).to_i
      yearmax = maxyear
      monmax = (maxmon+xinterval-1)/xinterval*xinterval + 1
      if monmax > 12
        monmax -= 12
        yearmax += 1
      end
      last_timestamp = Time.utc(yearmax,monmax,1,12).to_i
      x_ticks = (yearmax*12 + monmax - minyear*12 - monmin)/xinterval
    end
    # create date label strings for the xticks
    x_tick_labels=[]
    for tt in 0..x_ticks
      ttmp = Time.at(first_timestamp) + (xinterval*tt).months
      ttmpyear = ttmp.utc.year - 1900
      while ttmpyear > 99
        ttmpyear -= 100
      end
      x_tick_labels << [ttmp.to_i,"01/#{"%02d" % ttmp.month}/#{"%02d" % ttmpyear}"]
    end
    
    # adjust max_y to next threshold for graphing and calculate yticks / labels
    if 'pct'==ind_or_pct
      max_y_adjusted = 100
      yinterval = 20
    else
      ylog = 0
      ylog = Math::log10(max_y).to_i unless 0==max_y
      ratio = max_y.to_f / 10**(ylog+1)
      thresholds = [0.15, 0.20, 0.25, 0.30, 0.50, 0.75, 1.0]
      ii = 0
      while ratio > thresholds[ii] && ii<thresholds.length
        ii+=1
      end
      max_y_adjusted = 10**(ylog) * (10*thresholds[ii])
      yinterval = max_y_adjusted / 5
    end
    y_ticks=[]
    for yy in 0..5
      y_ticks << yy*yinterval.to_i;
    end

    # return the computed parameters to be used in the graph
    {'first_time_adjusted'=>first_timestamp, 'last_time_adjusted'=>last_timestamp,'num_x_ticks'=>x_ticks,'x_ticks'=>x_tick_labels,'max_y_adjusted'=>max_y_adjusted, 'y_ticks'=>y_ticks}
  end


end
