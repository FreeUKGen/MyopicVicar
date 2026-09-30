class DistrictsController < ApplicationController
  require 'freebmd_constants'
  skip_before_action :require_login

  def index
    @districts = District.not_invented.all
  end

  def show
    @district = get_district(params[:id])
    unless @district
      flash[:notice] = 'Please select a registration district from the list.'
      redirect_to districts_overview_path
      return
    end
    @search_query = get_search_query(params[:search_id])
    @search_record = get_entry(params[:entry_id])
    counts = fetch_unique_name_counts(@district.DistrictNumber)
    @birth_count, @birth_uniq_surname_count, @birth_uniq_forename_count = counts[1]
    @marriage_count, @marriage_uniq_surname_count, @marriage_uniq_forename_count = counts[3]
    @death_count, @death_uniq_surname_count, @death_uniq_forename_count = counts[2]
  end

  def districts_overview
  end

  def unique_district_names
    if params[:record_type].present? then @record_type = params[:record_type] else @record_type = "birth" end
    record_type_id = RecordType::FREEBMD_OPTIONS[@record_type.upcase]
    if params[:name_type].present? then @name_type = params[:name_type] else @name_type = "1" end
    @district_number = params[:id]
    @district = District.where(DistrictNumber: @district_number).first
    if @name_type == "0"
      @unique_names_0 = DistrictUniqueName.where(district_number: @district_number, record_type: record_type_id).first.unique_surnames
    else
      @unique_names_0 = DistrictUniqueName.where(district_number: @district_number, record_type: record_type_id).first.unique_forenames
    end
    if params[:filter].present?
      @filter = params[:filter].downcase
      pattern = ::Regexp.new(Regexp.escape(@filter))
      @unique_names_filtered = []
      @unique_names_0.each do |name|
        @unique_names_filtered << name if pattern.match(name.downcase)
      end
      @unique_names = @unique_names_filtered.sort_by!(&:downcase)
    else
      @unique_names = @unique_names_0.sort_by!(&:downcase)
    end
    @unique_names.map!(&:titleize)
    @unique_names, @remainders = @district.letterize(@unique_names)
  end

  def alphabet_selection
    @district = District.new
    @options = FreebmdConstants::ALPHABETS[0]
    @location = 'location.href= "/districts/districts_list?params=" + this.value'
    @prompt = 'Select District Range'
  end

  def county_selection
    @county = County.new
    @options = ['Aberdeenshire', 'Cheshire']
    @location = 'location.href= "/counties/show?params=" + this.value'
    @prompt = 'Select County'
  end

  def district_selection
    @districts = District.new
    @options = districts_as_array
    @location = 'location.href= "/districts/districts_list?params=" + this.value'
    @prompt = 'Select District'
  end

  def districts_list
    raw = params[:params].to_s.downcase
    unless raw.match?(/\A[a-z](-[a-z])?\z/)
      redirect_to districts_overview_path, alert: 'Invalid selection.'
      return
    end
    @character = raw
    @all_districts = District.not_invented.all
    @districts = @all_districts.select { |d| d.DistrictName.downcase =~ /#{@character}/ }
    @districts.sort_by! { |d| d.DistrictName }
    render :index
  end

  def districts_hash
    @all_districts = District.not_invented.all
    hash = Hash.new
    @all_districts.each do |district|
      hash[district.DistrictName] = district.DistrictNumber
    end
    hash
  end

  def district_page_map
    id = params[:id]
    @district = District.where(DistrictNumber: id).first if id.present?
  end

  def year_page_map
    @year = params[:year]
    @quarter = params[:quarter]
    @event_type = params[:event_type]
  end

  private

  def get_district(id=nil)
    District.find_by(DistrictNumber: id) if id.present?
  end

  def get_search_query(search_id=nil)
    SearchQuery.find(search_id) if search_id.present?
  end

  def get_entry(entry_id=nil)
    BestGuess.find_by(RecordNumber: entry_id) if entry_id.present?
  end

  # Fetches birth/marriage/death unique-name counts for a district in a single
  # round trip instead of three, and asks Mongo to compute the array sizes
  # server-side ($size) so the (potentially very large) unique_surnames /
  # unique_forenames arrays are never transferred over the wire. Results are
  # cached briefly since DistrictUniqueName rows only change via periodic
  # background rebuilds.
  def fetch_unique_name_counts(district_number)
    Rails.cache.fetch("district_unique_name_counts_#{district_number}", expires_in: 1.hour) do
      rows = DistrictUniqueName.collection.aggregate([
        { '$match' => { district_number: district_number, record_type: { '$in' => [1, 2, 3] } } },
        { '$project' => {
            record_type: 1,
            total_records: 1,
            unique_surname_count: { '$size' => { '$ifNull' => ['$unique_surnames', []] } },
            unique_forename_count: { '$size' => { '$ifNull' => ['$unique_forenames', []] } }
          } }
      ]).to_a

      counts = Hash.new([0, 'none', 'none'])
      rows.each do |row|
        counts[row['record_type']] = [row['total_records'] || 0, row['unique_surname_count'], row['unique_forename_count']]
      end
      counts
    end
  end
end
