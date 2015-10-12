class FreeregContentsController < ApplicationController
  require 'chapman_code'
  require 'freereg_options_constants'
  skip_before_filter :require_login

  def index
    redirect_to :action => :new
  end

  def new
    @freereg_content = FreeregContent.new
    @options = ChapmanCode.add_parenthetical_codes(ChapmanCode.remove_codes(ChapmanCode::CODES))
  end

  def create
    if params[:freereg_content][:place_ids].blank?
      params[:freereg_content][:place_ids] = ""
    end
    @freereg_content = FreeregContent.new(params[:freereg_content].delete_if{|k,v| v.blank? })
    @county = params[:freereg_content][:chapman_codes][1]
    place = params[:freereg_content][:place_ids]
    session[:chapman_code] = @county
    if  @freereg_content.save
      @county = ChapmanCode.name_from_code(@county)
      session[:county] = @county
      if place.present?
        redirect_to show_place_freereg_content_path(place)
        return
      else
        redirect_to freereg_content_path(@county)
        return
      end
    else
      @freereg_content.chapman_codes = []
      @options = ChapmanCode.add_parenthetical_codes(ChapmanCode.remove_codes(ChapmanCode::CODES))
      render :new
    end
  end


  def show
    if @page = Refinery::Page.where(:slug => 'dap-place-index-text').exists?
      @page = Refinery::Page.where(:slug => 'dap-place-index-text').first.parts.first.body.html_safe
    else
      @page = ""
    end
    @county = session[:county]
    @chapman_code = session[:chapman_code]
    @coordinator = County.coordinator_name(@chapman_code)
    @places = Places.where(:data_present => true).all.order_by(place_name: 1) if @county == 'all'
    @places = Place.where(:chapman_code => @chapman_code, :data_present => true).all.order_by(place_name: 1)  unless @county == 'all'
    session[:page] = request.original_url
    session[:county_id]  = params[:id]
    @records = number_of_records_in_county(@county)

  end

  def show_place
    @place = Place.find(params[:id])
    @county = session[:county]
    @chapman_code = session[:chapman_code]
    @coordinator = County.coordinator_name(@chapman_code)
    @country = @place.country
    @place_name = @place.place_name
    @names = @place.get_alternate_place_names
    @stats = @place.data_contents
    session[:place] = @place_name
    session[:place_id] = @place._id
  end

  def show_church
    if @page = Refinery::Page.where(:slug => 'dap-place-index-text').exists?
      @page = Refinery::Page.where(:slug => 'dap-place-index-text').first.parts.first.body.html_safe
    else
      @page = ""
    end
    @church = Church.find(params[:id])
    @stats = @church.data_contents
    @place_name = @church.place.place_name
    @place = @church.place
    @county = session[:county]
    @church_name = @church.church_name
    @registers = Register.where(:church_id => params[:id]).order_by(:record_types.asc, :register_type.asc, :start_year.asc).all
  end

  def show_register
    if @page = Refinery::Page.where(:slug => 'register-sidebar-text').exists?
      @page = Refinery::Page.where(:slug => 'register-sidebar-text').first.parts.first.body.html_safe
    else
      @page = ""
    end
    @register = Register.find(params[:id])
    @church  = @register.church
    @place = @church.place
    @county = session[:county]
    @files_id = Array.new
    @place_name = @place.place_name
    session[:register_id] = params[:id]
    @register_name = @register.register_name
    @register_name = @register.alternate_register_name if @register_name.nil?
    session[:register_name] = @register_name
    @church = @church.church_name
    individual_files = Freereg1CsvFile.where(:register_id =>params[:id]).order_by(:record_types.asc, :start_year.asc).all
    @files = Freereg1CsvFile.combine_files(individual_files)
    session[:county] = @county
    session[:church_name] = @church
    session[:place_name] = @place_name
    session[:place_id] = @place._id
  end

  def show_decade
    if session[:register_id].nil?
      #trap bots
      redirect_to :action => :new
      return
    end
    @register = Register.find(session[:register_id])
    @files_id = session[:files]
    @register_id = session[:register_id]
    @register_name = session[:register_name]
    individual_files = Freereg1CsvFile.where(:register_id => @register_id).order_by(:record_types.asc, :start_year.asc).all
    @files = Freereg1CsvFile.combine_files(individual_files)
    @decade = { }
    max = 1
    @files.each_pair do |key,my_file|
      @decade[key] = my_file["daterange"]
      if @decade[key]
        if my_file["daterange"].length > max
          max = my_file["daterange"].length
        end
      end
    end
    @decade["ba"] = Array.new(max, 0) unless @decade["ba"]
    @decade["bu"] = Array.new(max, 0) unless @decade["bu"]
    @decade["ma"] = Array.new(max, 0) unless @decade["ma"]
    @record_type = params[:id]
    @place = Place.find(session[:place_id])
    @church = session[:church_name]
    @place_name = session[:place_name]
    @county = session[:county]
    @RType = RegisterType.display_name(@register.register_type)
  end

  def remove_countries_from_parenthetical_codes
  end
  def number_of_records_in_county(county)
    chapman = ChapmanCode.values_at(county)
    files = Freereg1CsvFile.county(chapman).all
    record = Array.new
    records = 0
    records_ma = 0
    records_ba = 0
    records_bu = 0
    files.each do |file|
      p file
      records = records.to_i + file.records.to_i unless file.records.nil?
      case file.record_type
      when "ba"
        records_ba = records_ba + file.records.to_i unless file.records.nil?
      when "ma"
        records_ma = records_ma + file.records.to_i unless file.records.nil?
      when "bu"
        records_bu = records_bu + file.records.to_i unless file.records.nil?
      end
    end
    record[0] = records
    record[1] = records_ba
    record[2] = records_bu
    record[3] = records_ma
    record
  end

end
