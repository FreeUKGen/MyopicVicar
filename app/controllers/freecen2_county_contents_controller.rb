class Freecen2CountyContentsController < ApplicationController
  require 'chapman_code'
  require 'freecen_constants'
  skip_before_action :require_login

  def county_index
    redirect_back(fallback_location: freecen2_county_contents_path, notice: 'County not found') && return if set_county_vars == false

    records_places = @freecen2_county_contents.records[:total][:places]
    @places_for_county = {}
    @places_for_county =  { '' => "Select a Place in #{@county_description} ..." }
    records_places.each { |place| @places_for_county[remove_dates_place(place)] = place.gsub('=', ' ') if Freecen2Place.find_by(chapman_code: @chapman_code, place_name: remove_dates_place(place)).present? }
    return unless params[:commit] == 'View Place Records'

    if params[:place_description].blank? || params[:place_description] == ''
      flash[:notice] = 'You must select a Place'
    else
      session[:contents_county_description] = @county_description
      session[:contents_place_description] = params[:place_description]
      redirect_to freecen2_county_contents_place_index_path and return
    end
  end

  def new_records_index
    if session[:contents_date].blank?
      @freecen2_contents = Freecen2CountyContent.where(county: 'ALL').order_by(interval_end: :desc).first
      session[:contents_date] = @freecen2_county_contents.interval_end
    end
    @interval_end = session[:contents_date]

    @recent_additions = []
    @additions_county = params[:new_records] if params[:new_records].present?

    if @additions_county == 'All'
      @freecen2_contents = Freecen2CountyContent.find_by(interval_end: @interval_end, county: 'ALL') if @freecen2_contents.blank?
      @recent_additions = @freecen2_contents.new_records
    else
      chapman = ChapmanCode.code_from_name(@additions_county)
      @freecen2_county_contents = Freecen2CountyContent.find_by(interval_end: @interval_end, county: chapman)
      @recent_additions = @freecen2_county_contents.new_records if @freecen2_county_contents.present?
    end
  end

  def place_index
    redirect_back(fallback_location: freecen2_county_contents_path, notice: 'County not found') && return if !session[:contents_county_description].presence

    redirect_back(fallback_location: freecen2_county_contents_path, notice: 'County not found') && return if set_county_vars == false

    redirect_back(fallback_location: freecen2_county_contents_path, notice: 'Place not found') && return if !session[:contents_place_description].presence

    @place_description = params[:place_description].presence || session[:contents_place_description]

    redirect_back(fallback_location: freecen2_county_contents_path, notice: 'Place not found') && return if @place_description.blank?

    @key_place = Freecen2CountyContent.get_place_key(@place_description)
    @place_id = @freecen2_county_contents.records[@key_place][:total][:place_id]
    check_names_exist
  end

  def piece_index
    redirect_to(freecen2_county_contents_path, notice: 'Obsolete link') && return
  end

  def piece_index_setup(order_by_for_total, order_by_for_year)
    redirect_to(freecen2_county_contents_path, notice: 'Record not found') && return if @freecen2_county_contents.blank?

    redirect_to(freecen2_county_contents_path, notice: 'Census Year not found') && return if !params[:census_year].presence || params[:census_year].blank?

    redirect_to(freecen2_county_contents_path, notice: 'Place not found') && return if !params[:place_description].presence || params[:place_description].blank?

    @census = params[:census_year]
    @place_description = params[:place_description]
    if @place_description != 'all'
      @place_id = params[:place_id]
      @key_place = Freecen2CountyContent.get_place_key(@place_description)
    end
    return unless set_county_vars == true

    if params[:census_year] == 'all'
      @census_text = 'All Years'
      if params[:place_description] == 'all'
        @place_piece_ids = @freecen2_county_contents.records[:total][:piece_ids]
      else
        @place_piece_ids = @freecen2_county_contents.records[@key_place][:total][:piece_ids]
      end

      @place_pieces = Freecen2Piece.where(:_id.in => @place_piece_ids).order(order_by_for_total)
    else
      @census_text = params[:census_year]
      if params[:place_description] == 'all'
        @place_piece_ids = @freecen2_county_contents.records[@census][:piece_ids]
      else
        @place_piece_ids = @freecen2_county_contents.records[@key_place][@census][:piece_ids]
      end
      @place_pieces = Freecen2Piece.where(:_id.in => @place_piece_ids).order(order_by_for_year)
    end
  end

  def display_pieces_by_status
    redirect_back(fallback_location: freecen2_county_contents_path, notice: 'County not found') && return if session[:contents_county_description].blank? && params[:county_description].blank?

    redirect_to(freecen2_county_contents_path, notice: 'County not found') && return if set_county_vars == false

    if params[:census_year].blank? || params[:place_description].blank? || (params[:place_description] != 'all' && params[:place_id].blank?)
      redirect_to(freecen2_county_contents_path, notice: 'County or Place not found') && return

    else
      piece_index_setup('status DESC, status_date.try(:to_date) DESC, name ASC, year ASC, number ASC', 'status DESC, status_date DESC, name ASC, number ASC')
      redirect_to(freecen2_county_contents_path, notice: 'County or Place not found') && return if @place_pieces.blank?

      @order_text = 'Most Recent Online'
      @order = 'status'
      render 'piece_index'
    end
  end

  def display_pieces_by_name
    redirect_back(fallback_location: freecen2_county_contents_path, notice: 'County not found') && return if session[:contents_county_description].blank? && params[:county_description].blank?

    redirect_to(freecen2_county_contents_path, notice: 'County not found') && return if set_county_vars == false

    if params[:census_year].blank? || params[:place_description].blank? || (params[:place_description] != 'all' && params[:place_id].blank?)
      redirect_to(freecen2_county_contents_path, notice: 'County or Place not found') && return

    else
      piece_index_setup('name ASC, year ASC, number ASC', 'name ASC, number ASC')
      redirect_to(freecen2_county_contents_path, notice: 'County or Place not found') && return if @place_pieces.blank?

      @order_text = 'Piece Name'
      @order = 'name'
      render 'piece_index'
    end
  end

  def display_pieces_by_number
    redirect_back(fallback_location: freecen2_county_contents_path, notice: 'County not found') && return if session[:contents_county_description].blank? && params[:county_description].blank?

    redirect_to(freecen2_county_contents_path, notice: 'County not found') && return if set_county_vars == false

    if params[:census_year].blank? || params[:place_description].blank? || (params[:place_description] != 'all' && params[:place_id].blank?)
      redirect_to(freecen2_county_contents_path, notice: 'County or Place not found') && return

    else
      piece_index_setup('number ASC', 'number ASC')
      redirect_to(freecen2_county_contents_path, notice: 'County or Place not found') && return if @place_pieces.blank?

      @order_text = 'Piece Number'
      @order = 'number'
      render 'piece_index'
    end
  end

  def place_names
    redirect_back(fallback_location: freecen2_county_contents_path, notice: 'County not found') && return if session[:contents_county_description].blank? && params[:county_description].blank?

    redirect_back(fallback_location: freecen2_county_contents_path, notice: 'County not found') && return if set_county_vars == false

    if !params[:census_year].presence || !params[:place_description].presence
      redirect_back(fallback_location: freecen2_county_contents_path, notice: 'Names not found') && return
    end

    if params[:census_year].blank? || params[:place_description].blank?
      redirect_back(fallback_location: freecen2_county_contents_path, notice: 'Names not found') && return
    end

    @year = params[:census_year]
    @place_description = params[:place_description]
    @place = Freecen2Place.find_by(chapman_code: @chapman_code, place_name: @place_description)
    if @place.present?
      @place_unique_names = Freecen2PlaceUniqueName.find_by(freecen2_place_id: @place.id)
      redirect_back(fallback_location: freecen2_county_contents_path, notice: 'Names not found') && return if @place_unique_names.blank?

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
      @unique_names, @remainder = Freecen2CountyContent.letterize(@unique_names)
    else
      redirect_back(fallback_location: freecen2_county_contents_path, notice: 'Place not found') && return
    end
  end

  def index
    @freecen2_county_contents = Freecen2CountyContent.where(county: 'ALL').order_by(interval_end: :desc).first
    @interval_end = @freecen2_county_contents.interval_end
    session[:contents_date] = @freecen2_county_contents.interval_end
    records_counties = @freecen2_county_contents.records[:total][:counties]
    @all_counties = {}
    @all_counties = { '' => 'Select a County ... ' }
    records_counties.each { |county| @all_counties[county] = county }
    case params[:commit]
    when 'View County Records'
      session[:contents_county_description] = params[:county_description]
      redirect_to index_by_county_freecen2_county_contents_path and return
    when 'View Place Records'
      if params[:place_description].blank? || params[:place_description] == ''
        flash[:notice] = 'You must select a Place'
      else
        session[:contents_county_description] = params[:county_description]
        session[:contents_place_description] = params[:place_description]
        redirect_to freecen2_county_contents_place_index_path and return
      end
    end
  end

  def for_place_names
    if params[:county_description] && session[:contents_date]
      @interval_end = session[:contents_date]
      county_description = params[:county_description]
    else
      log_possible_host_change
      flash[:notice] = 'An Error was encountered' && return
    end
    chapman_code = ChapmanCode.code_from_name(county_description)
    redirect_back(fallback_location: freecen2_county_contents_path, notice: 'County not found') && return if chapman_code.blank?

    @freecen2_county_contents = Freecen2CountyContent.find_by(interval_end: @interval_end, county: chapman_code)
    county_places = @freecen2_county_contents.records[:total][:places]
    county_places_hash = { '' => "Select a Place in #{county_description} ..." }
    county_places.each { |place| county_places_hash[remove_dates_place(place)] = place.gsub('=', ' ') if Freecen2Place.find_by(chapman_code: chapman_code, place_name: remove_dates_place(place)).present? }
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
    @interval_end = session[:contents_date].presence || Freecen2CountyContent.find_by(county: 'ALL').order(interval_end: :desc).first.interval_end
    session[:contents_date] = @interval_end
    @county_description = params[:county_description].presence || session[:contents_county_description]
    session[:contents_county_description] = @county_description
    @chapman_code = ChapmanCode.code_from_name(@county_description) if @county_description.present?
    @freecen2_county_contents = Freecen2CountyContent.find_by(interval_end: @interval_end, county: @chapman_code) if @county_description.present?
    @freecen2_county_contents.present? && @county_description.present? && @chapman_code.present?
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

  def remove_dates_place(place_with_dates)
    place_with_dates.split('=')[0]
  end

  def show
    redirect_to(freecen2_county_contents_path, notice: 'No such record') && return
  end

  private

  def freecen2_content_params
    params.require(:freecen2_content).permit!
  end
end
