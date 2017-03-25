class FreecenPiecesController < InheritedResources::Base
  require 'freecen_constants'

  def freecen_piece_params
    params.require(:freecen_piece).permit!
  end



  def index
  end

  

  def show
    if params[:id].present?
      @freecen_piece = FreecenPiece.where('_id' => params[:id])
      @freecen_piece = @freecen_piece.first if @freecen_piece.present?
    end
    redirect_to freecen_pieces_path if @freecen_piece.blank?
  end



  def new
    @freecen_piece = FreecenPiece.new
    @freecen_piece.year = params[:year] if params[:year].present? && 
      Freecen::CENSUS_YEARS_ARRAY.include?(params[:year])
    @freecen_piece.chapman_code = params[:chapman_code].upcase if params[:chapman_code].present?
    @freecen_piece.subplaces = [{'name'=>'','lat'=>'0.0','long'=>'0.0'}]
    #puts "\n\n*** new *** yy=#{@freecen_piece.year} chap=#{@freecen_piece.chapman_code}\n\n"
  end

  def select_new_county
    @county = ''
    if Freecen::CENSUS_YEARS_ARRAY.include?(params[:year])
      @year = params[:year] 
      year_pieces = FreecenPiece.only(:chapman_code).where('year'=>@year).entries
      existing_year_counties = []
      if year_pieces.present?
        year_pieces.each do |yp|
          existing_year_counties << yp[:chapman_code]
        end
      end
      @year_counties = (ChapmanCode::values - existing_year_counties).sort
    else
      puts "year parameter missing in freecen_pieces_controller select_new_county"
      flash[:notice] = 'Invalid or blank census year'
      redirect_to :back
    end
  end

  def edit
    #puts "\n\n*** edit ***\n\n"
    if params[:id].present?
      @freecen_piece = FreecenPiece.where('_id' => params[:id])
      @freecen_piece = @freecen_piece.first if @freecen_piece.present?
    end
    redirect_to freecen_pieces_path if @freecen_piece.blank?
  end

  def create
    #puts "\n\n*** create ***\n\n"
    unless params[:freecen_piece].blank?
      piece_params = transform_piece_params(params[:freecen_piece])
      @piece_params_errors = check_piece_params(params[:freecen_piece])
      @freecen_piece = FreecenPiece.new(piece_params.permit!) unless piece_params.blank?
      set_piece_place(@freecen_piece)
      if @piece_params_errors.present? && @piece_params_errors.any?
        flash[:notice] = "***Could not create the new piece"
        render :new and return
      end
    end
    if @freecen_piece.present?
      #puts "@freecen_piece present _id=#{@freecen_piece['_id']}"
      #puts "@freecen_piece.inspect #{@freecen_piece.inspect}"
      unless @freecen_piece.save
        flash[:notice] = 'There was an error while saving the new piece'
        puts "\n\n***could not save @freecen_piece in create method!!\n\n"
        render :new and return
      end
      # clear cached database coverage so it picks up the change for display
      Rails.cache.delete("freecen_coverage_index")
      #redirect to the right page
      next_page = freecen_coverage_path+"/#{@freecen_piece.chapman_code}##{@freecen_piece.year}"
      redirect_to next_page and return
    end
    flash[:notice] = 'There was an error while attempting to save the new piece'
    puts "\n\n***could not find freecen_piece in create method!!\n\n"
    redirect_to freecen_coverage_path
  end



  #transform the params before checking them.
  def check_piece_params(piece_params)
    error_list = []
    unless ChapmanCode::values.include? piece_params['chapman_code']
      error_list << "Unknown Chapman code '#{piece_params['chapman_code']}'."
    end
    unless Freecen::CENSUS_YEARS_ARRAY.include? piece_params['year']
      error_list << "Invalid census year '#{piece_params['year']}'."
    end
    unless piece_params['piece_number'].to_i.to_s==piece_params['piece_number'] && piece_params['piece_number'].to_i > 0
      error_list << "Piece Number should be a positive integer."
    end
    unless piece_params['district_name'].present? && piece_params['district_name'].length > 0
      error_list << "District name is required."
    end
    sp_names_err = false
    sp_lat_err = false
    sp_long_err = false
    piece_params['subplaces'].each do |sp|
      sp_names_err=true if sp['name'].blank? || sp['name'].length < 1
      sp_lat_err=true if sp['lat'].to_f < -90.0 || sp['lat'].to_f > 90.0
      sp_long_err=true if sp['long'].to_f < -180.0 || sp['long'].to_f > 180.0
    end
    if sp_lat_err || piece_params['latitude'].to_f < -90.0 || piece_params['latitude'].to_f > 90.0
      error_list << "Latitudes must be between -90 and 90 (UK is between 49 and 61)."
    end
    if sp_long_err || piece_params['longitude'].to_f < -180.0 || piece_params['longitude'].to_f > 180.0
      error_list << "Longitudes must be between -180 and 180 (UK is between -11 and 2)."
    end
    if sp_names_err
      error_list << "Sub-place names are required."
    end
    # parish number should be empty if not SCT
    is_scot = 'SCS'==piece_params['chapman_code']||ChapmanCode::CODES['Scotland'].values.include?(piece_params['chapman_code'])
    if !is_scot && piece_params['parish_number'].length > 0
      error_list << "Par number currently only supported for Scotland"
    end
    # file name should agree with parish number if SCT
    if is_scot
      file_partnum = piece_params['freecen1_filename'][3,2]
      if file_partnum != piece_params['parish_number']
        error_list << "Par number seems to disagree with FreeCen1 Filename"
      end
    end
    return error_list
  end

  def transform_piece_params(piece_params)
    return piece_params if piece_params.blank?
    subplaces = []
    (0..piece_params[:subplaces_max_id].to_i).each do |ii|
      unless piece_params["subplaces_#{ii}_name"].nil?
        sp_name = piece_params["subplaces_#{ii}_name"].strip
        piece_params.delete("subplaces_#{ii}_name")
      end
      unless piece_params["subplaces_#{ii}_lat"].nil?
        sp_lat = piece_params["subplaces_#{ii}_lat"].strip
        piece_params.delete("subplaces_#{ii}_lat")
      end
      unless piece_params["subplaces_#{ii}_long"].nil?
        sp_long = piece_params["subplaces_#{ii}_long"].strip
        piece_params.delete("subplaces_#{ii}_long")
      end
      if sp_name && sp_lat && sp_long
        subplaces << {'name' => sp_name.to_s, 'lat' => sp_lat.to_f, 'long' => sp_long.to_f}
      else
        puts "*** ERROR! missing piece_params[freecen_piece_subplaces_#{ii}_*] in freecen_pieces_controller.rb check_and_transform_param()\n\n"
        puts piece_params.inspect
      end
    end
    subplaces_sort = ''
    subplaces.each do |sp|
      unless sp.blank? || sp['name'].strip.blank?
        subplaces_sort += ', ' unless ''==subplaces_sort
        subplaces_sort += sp['name'].strip.downcase
      end
    end
    piece_params[:subplaces] = subplaces
    piece_params[:subplaces_sort] = subplaces_sort
    piece_params.delete('subplaces_max_id') if piece_params['subplaces_max_id'].present?
    #strip stray whitespace from parameters
    piece_params[:district_name].strip! unless piece_params[:district_name].nil?
    piece_params[:place_latitude].strip! unless piece_params[:place_latitude].nil?
    piece_params[:place_longitude].strip! unless piece_params[:place_longitude].nil?
    piece_params[:suffix].strip! unless piece_params[:suffix].nil?
    piece_params[:film_number].strip! unless piece_params[:film_number].nil?
    piece_params[:freecen1_filename].strip! unless piece_params[:freecen1_filename].nil?
    piece_params[:status].strip! unless piece_params[:status].nil?
    piece_params[:remarks].strip! unless piece_params[:remarks].nil?
    piece_params[:remarks_coord].strip! unless piece_params[:remarks_coord].nil?
    return piece_params
  end

  def update
    #puts "\n\n*** update ***\n"
    redirect_to :back and return if params[:id].blank?
    @freecen_piece = FreecenPiece.where('_id' => params[:id]).first
    if @freecen_piece.blank?
      flash[:notice] = "Could not update the piece! (piece not found)"
      puts "\n*** piece not found! in freecen_pieces_controller update\n"
      redirect_to :back and return
    end
    unless params[:freecen_piece].blank?
      piece_params = transform_piece_params(params[:freecen_piece])
      @piece_params_errors = check_piece_params(params[:freecen_piece])
      if @piece_params_errors.present? && @piece_params_errors.any?
        flash[:notice] = "Could not update the piece (errors present)"
        render :edit and return
      end
      # update the fields
      @freecen_piece.chapman_code = piece_params['chapman_code']
      @freecen_piece.piece_number = piece_params['piece_number'].to_i
      @freecen_piece.district_name = piece_params['district_name']
      @freecen_piece.subplaces = piece_params['subplaces']
      @freecen_piece.subplaces_sort = piece_params['subplaces_sort']
      @freecen_piece.parish_number = piece_params['parish_number']
      @freecen_piece.suffix = piece_params['suffix']
      @freecen_piece.year = piece_params['year']
      @freecen_piece.film_number = piece_params['film_number']
      @freecen_piece.freecen1_filename = piece_params['freecen1_filename']
      @freecen_piece.status = piece_params['status']
      @freecen_piece.remarks = piece_params['remarks']
      @freecen_piece.remarks_coord = piece_params['remarks_coord']
      #online_time not editable by coords for now
      #num_individuals not editable by coords for now
      set_piece_place(@freecen_piece) #update the place / create one if needed
      if !@freecen_piece.save
        flash[:notice] = "Could not update the piece (save returned false)"
        render :edit and return
      end
      # bust database coverage cache so it picks up the change for display
      Rails.cache.delete("freecen_coverage_index")
      next_page = freecen_coverage_path+"/#{@freecen_piece.chapman_code}##{@freecen_piece.year}"
      redirect_to next_page and return
    end
    flash[:notice] = 'There was an error while updating the piece (parameters)'
    render :edit and return
  end

  def set_piece_place(piece)
    place = Place.where(:chapman_code => piece.chapman_code, :place_name => piece.district_name).first
    unless place #create the new place
      place = Place.new
      place.chapman_code = piece.chapman_code
      place.place_name = piece.district_name
      place.latitude = 0
      place.longitude = 0
      place.save!
    end
    piece.place = place
  end


end
