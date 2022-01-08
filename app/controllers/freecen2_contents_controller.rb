class Freecen2ContentsController < ApplicationController
  require 'chapman_code'
  require 'freecen_constants'
  skip_before_action :require_login

  def county_index
    redirect_back(fallback_location: freecen2_contents_path, notice: 'County not found') && return if set_county_vars == false

    records_places = @freecen2_contents.records[@chapman_code][:total][:places]
    @places_for_county = {}
    @places_for_county =  { '' => "Select a Place in #{@county_description} ..." }
    records_places.each { |place| @places_for_county[place] = add_dates_place(@chapman_code, place) }
    return unless params[:commit] == 'View Place Records'

    if !params[:place_description].present? || params[:place_description] == ''
      flash[:notice] = 'You must select a Place'
    else
      session[:contents_county_description] = @county_description
      session[:contents_place_description] = params[:place_description]
      redirect_to freecen2_contents_place_index_path and return
    end
  end

  def new_records_index
    if session[:contents_id].blank?
      @freecen2_contents = Freecen2Content.order(interval_end: :desc).first
      session[:contents_id] = @freecen2_contents.id
    end
    @id = session[:contents_id]
    @freecen2_contents = Freecen2Content.find_by(id: @id)
    @interval_end = @freecen2_contents.interval_end
    @recent_additions = []
    @additions_county = params[:new_records] if params[:new_records].present?
    return if @freecen2_contents.new_records.blank?
    redirect_back(fallback_location: freecen2_contents_path, notice: 'Recent Additions not found') && return if @additions_county.blank?

    if @additions_county == 'All'
      @recent_additions = @freecen2_contents.new_records
    else
      @freecen2_contents.new_records.each do |entry|
        # [0] = county name [1] = place name [2] = chapman code [3] = freecen2_place_id [4] = year
        @recent_additions << entry if entry[0] == @additions_county
      end
    end
  end

  def place_index
    redirect_back(fallback_location: freecen2_contents_path, notice: 'County not found') && return if set_county_vars == false

    @place_description = params[:place_description].presence || session[:contents_place_description]
    if @place_description.blank?
      redirect_back(fallback_location: freecen2_contents_path, notice: 'Place not found') && return
    end

    @key_place = Freecen2Content.get_place_key(@place_description)
    @place_id = @freecen2_contents.records[@chapman_code][@key_place][:total][:place_id]
    check_names_exist
  end

  def piece_index
    redirect_back(fallback_location: freecen2_contents_path, notice: 'County not found') && return if set_county_vars == false

    if params[:census_year].blank? || params[:place_description].blank? || params[:place_id].blank?
      redirect_back(fallback_location: freecen2_contents_path, notice: 'Place not found') && return
    end

    @census = params[:census_year]
    @place_description = params[:place_description]
    @place_id = params[:place_id]
    @key_place = Freecen2Content.get_place_key(@place_description)
    if params[:census_year] == 'all'
      @census = 'All Years'
      @place_piece_ids = @freecen2_contents.records[@chapman_code][@key_place][:total][:piece_ids]
      @place_pieces = Freecen2Piece.where(:_id.in => @place_piece_ids).order_by(name: 1, year: 1, number: 1)
    else
      @census = params[:census_year]
      @place_piece_ids = @freecen2_contents.records[@chapman_code][@key_place][@census][:piece_ids]
      @place_pieces = Freecen2Piece.where(:_id.in => @place_piece_ids).order_by(name: 1, number: 1)
    end
  end

  def place_names
    redirect_back(fallback_location: freecen2_contents_path, notice: 'County not found') && return if set_county_vars == false

    if params[:census_year].blank? || params[:place_description].blank?
      redirect_back(fallback_location: freecen2_contents_path, notice: 'Names not found') && return
    end

    @year = params[:census_year]
    @place_description = params[:place_description]
    @place = Freecen2Place.find_by(chapman_code: @chapman_code, place_name: @place_description)
    @place_unique_names = Freecen2PlaceUniqueName.find_by(freecen2_place_id: @place.id)
    @first_names = @place_unique_names.unique_forenames[@year]
    @last_names = @place_unique_names.unique_surnames[@year]
    @first_names_cnt = @first_names.count
    @last_names_cnt = @last_names.count
    if params[:name_type] == 'Surnames' || params[:name_type].to_s.empty?
      @unique_names = @last_names
      @name_type = 'Surnames'
    else
      @unique_names = @first_names
      @name_type = 'Forenames'
    end
    @first_letter = params[:first_letter].presence || 'All'
    @unique_names, @remainder = Freecen2Content.letterize(@unique_names)
  end

  def index
    @freecen2_contents = Freecen2Content.order(interval_end: :desc).first
    @interval_end = @freecen2_contents.interval_end
    session[:contents_id] = @freecen2_contents.id
    records_counties = @freecen2_contents.records[:total][:counties]
    @all_counties = {}
    @all_counties = { '' => 'Select a County ... ' }
    records_counties.each { |county| @all_counties[county] = county }
    case params[:commit]
    when 'View County Records'
      session[:contents_county_description] = params[:county_description]
      redirect_to index_by_county_freecen2_contents_path and return
    when 'View Place Records'
      if params[:place_description].blank? || params[:place_description] == ''
        flash[:notice] = 'You must select a Place'
      else
        session[:contents_county_description] = params[:county_description]
        session[:contents_place_description] = params[:place_description]
        redirect_to freecen2_contents_place_index_path and return
      end
    end
  end

  def for_place_names
    @id = session[:contents_id]
    @freecen2_contents = Freecen2Content.find_by(id: @id)
    if params[:county_description]
      county_description = params[:county_description]
    else
      log_possible_host_change
      county_description = ''
    end
    chapman_code = ChapmanCode.code_from_name(county_description)
    county_places = @freecen2_contents.records[chapman_code][:total][:places]
    county_places_hash = { '' => "Select a Place in #{county_description} ..." }
    county_places.each { |place| county_places_hash[place] = add_dates_place(chapman_code, place) }
    if county_places_hash.present?
      respond_to do |format|
        format.json do
          render json: county_places_hash
        end
      end
    else
      flash[:notice] = 'An Error was encountered: No places found'
    end
  end

  def set_county_vars
    @id = session[:contents_id].presence || Freecen2Content.order(interval_end: :desc).first.id
    session[:contents_id] = @id
    @freecen2_contents = Freecen2Content.find_by(id: @id)
    @interval_end = @freecen2_contents.interval_end
    @county_description = params[:county_description].presence || session[:contents_county_description]
    session[:contents_county_description] = @county_description
    @chapman_code = ChapmanCode.code_from_name(@county_description) if @county_description.present?
    @freecen2_contents.present? && @county_description.present? && @chapman_code.present?
  end

  def check_names_exist
    @has_some_names = false
    @has_names = {}
    names_present = Freecen2PlaceUniqueName.find_by(freecen2_place_id: @place_id).present?
    return unless names_present

    @names = Freecen2PlaceUniqueName.find_by(freecen2_place_id: @place_id)
    Freecen::CENSUS_YEARS_ARRAY.each do |year|
      if @names.unique_forenames[year].present? && @names.unique_surnames[year].present?
        @has_names[year] = true
        @has_some_names = true
      else
        @has_names[year] = false
      end
    end
  end

  def add_dates_place(chapman_code, place_description)
    place_dropdown = place_description
    key_place = Freecen2Content.get_place_key(place_description)
    if @freecen2_contents.records[chapman_code][key_place][:total][:records_online].positive?
      place = Freecen2Place.find_by(chapman_code: chapman_code, place_name: place_description)
      unless place.cen_data_years.blank?
        years = "(" + place.cen_data_years.sort.to_s.gsub(/\"|\[|\]/,"") + ")"
        place_dropdown = "#{place_description} #{years}"
      end
    end
    place_dropdown
  end

  private

  def freecen2_content_params
    params.require(:freecen2_content).permit!
  end
end
