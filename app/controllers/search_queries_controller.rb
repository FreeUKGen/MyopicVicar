# Copyright 2012 Trustees of FreeBMD
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
#

class SearchQueriesController < ApplicationController
  skip_before_action :require_login
  skip_before_action :verify_authenticity_token
  before_action :check_for_mobile, only: :show
  before_action :require_login, only: :compare_search
  rescue_from Mongo::Error::OperationFailure, with: :search_taking_too_long
  rescue_from Mongoid::Errors::DocumentNotFound, with: :missing_document
  rescue_from Timeout::Error, with: :search_taking_too_long
  autocomplete :BestGuess, :Surname, full: false,  limit: 5
  autocomplete :BestGuess, :GivenName, full: false, limit: 10
  include DownloadAsCsv

  RECORDS_PER_PAGE = 100

  def about
    @page_number = params[:page_number].present? ? params[:page_number].to_i : 0
    @search_query, proceed, message = SearchQuery.check_and_return_query(params[:id])
    redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed
  end

  def adjust_search_query_parameters
    @search_query['first_name'] = @search_query['first_name'].strip if @search_query['first_name'].present?
    @search_query['last_name'] = @search_query['last_name'].strip if @search_query['last_name'].present?
    @search_query['chapman_codes'] = ['', 'ERY', 'NRY', 'WRY'] if @search_query['chapman_codes'][1].eql?('YKS')
    @search_query['birth_chapman_codes'] = ['', 'ERY', 'NRY', 'WRY'] if @search_query['birth_chapman_codes'][1].eql?('YKS')
    @search_query['chapman_codes'] = ['', 'ALD', 'GSY', 'JSY', 'SRK'] if @search_query['chapman_codes'][1].eql?('CHI')
    @search_query['birth_chapman_codes'] = ['', 'ALD', 'GSY', 'JSY', 'SRK'] if @search_query['birth_chapman_codes'][1].eql?('CHI')
    @search_query.session_id = request.session_options[:id]
    @search_query['partial_search'] = true if @search_query['wildcard_field'].present? && @search_query['wildcard_option'].present?
  end

  def analyze
    @search_query, proceed, message = SearchQuery.check_and_return_query(params[:id])
    redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed

    begin
      @plan = @search_query.explain_plan
    rescue => ex
      @plan_error = ex.message
      @plan = @search_query.explain_plan_no_sort
    end
  end

  def broaden
    old_query, proceed, message = SearchQuery.check_and_return_query(params[:id])
    redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed

    new_parameters = old_query.reduce_attributes
    @search_query = SearchQuery.new(new_parameters)
    @search_query.radius_factor = @search_query.radius_factor * 2
    render :new unless @search_query.save
    session[:query] = @search_query.id
    @search_results = @search_query.search
    redirect_to search_query_path(@search_query)
  end

  def create
    condition = true if params[:search_query].present? && params[:search_query][:region].blank?
    redirect_back(fallback_location: new_search_query_path, notice: 'Invalid Search') && return unless condition
    county_hash = ChapmanCode.add_parenthetical_codes(ChapmanCode.remove_codes(ChapmanCode::FREEBMD_CODES))
    selected_counties = search_params['chapman_codes'].split(',').compact
    selected_counties = selected_counties.collect(&:strip).reject{|c| c.empty? }
    county_codes = []
    county_hash.each {|country, counties|
      selected_counties.each{|c|
        county_codes << county_hash.dig(country).fetch(c) if county_hash.dig(country).keys.include?c
      }
    }
    search_params['chapman_codes'] = county_codes.flatten
    @search_query = SearchQuery.new(search_params.delete_if { |_k, v| v.blank? })
    adjust_search_query_parameters
    if @search_query.save
      session[:query] = @search_query.id
      @search_results, success, error_type = @search_query.search_records.to_a
      error = error_type.to_i if error_type.present?
      redirect_to search_query_path(@search_query) and return if success
      redirect_to search_query_path(@search_query, timeout: true) and return if error == 1
      redirect_back(fallback_location: new_search_query_path(:search_id => @search_query), notice: 'Your search encountered a problem. Please try again') and return if error_type == 2
    else
      render :new
    end
  end

  def valid_wildcard_qurey

  end


  def edit
    @search_query, proceed, message = SearchQuery.check_and_return_query(params[:id])
    redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed
  end

  def index
    redirect_to action: :new
  end

  def missing_document
    logger.warn("#{appname_upcase}:SEARCH: Search encountered a missing document #{params}")
    flash[:notice] = 'We encountered a problem executing your request. You need to restart your query. If the problem continues please contact us explaining what you were doing that led to the failure.'
    redirect_to new_search_query_path
  end

  def narrow
    old_query, proceed, message = SearchQuery.check_and_return_query(params[:id])
    redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed

    new_parameters = old_query.reduce_attributes
    @search_query = SearchQuery.new(new_parameters)
    @search_query.radius_factor = @search_query.radius_factor / 2
    render :new unless @search_query.save
    session[:query] = @search_query.id
    @search_results = @search_query.search
    redirect_to search_query_path(@search_query)
  end

  def new
    test_page = Refinery::Page.where(slug: 'test_message').first
    beta_page = Refinery::Page.where(slug: 'beta_message').first
    url = request.original_url
    url.include?('beta') ? page = beta_page : page= test_page
    @page = session[:message] == 'load' && page.present? && page.parts.first.present? ? page.parts.first.body.html_safe : nil

    @search_query = SearchQuery.new
    session.delete(:query)
    old_query = SearchQuery.search_id(params[:search_id]).first if params[:search_id].present?
    old_query.search_result.records = {} if old_query.present? && old_query.search_result.present?
    @search_query = SearchQuery.new(old_query.attributes) if old_query.present?
    @chapman_codes = ChapmanCode::CODES
  end

  def remember
    @search_query, proceed, message = SearchQuery.check_and_return_query(params[:id])
    redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed

    get_user_info_from_userid
    @user.remember_search(@search_query)
    flash[:notice] = 'This search has been added to your remembered searches'
    redirect_to search_query_path(@search_query)
  end

  def reorder
    old_query, proceed, message = SearchQuery.check_and_return_query(params[:id])
    redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed

    proceed = SearchQuery.valid_order?(params[:order_field])
    redirect_back(fallback_location: new_search_query_path, notice: 'No such order') && return unless proceed

    order_field = params[:order_field]
    if order_field == old_query.order_field
      # reverse the directions
      old_query.order_asc = !old_query.order_asc
    else
      old_query.order_field = order_field
      old_query.order_asc = true
    end
    old_query[:results_per_page] = params[:results_per_page] if params[:results_per_page].present?
    old_query.save!
    #    old_query.new_order(old_query)
    redirect_to search_query_path(old_query)
  end

  def report
    # default criteria:
    # today
    if params[:session_id]
      report_for_session
    else
      report_for_day
    end
  end

  def report_for_day
    if day_param = params[:day]
      @start_day = DateTime.parse(day_param).strftime('%F')
    else
      @start_day = DateTime.now.strftime('%F')
    end
    order_param = :runtime unless order_param == params[:order]
    @previous_day = (Date.parse(@start_day) - 1).strftime('%F')
    @next_day = (Date.parse(@start_day) + 1).strftime('%F')
    @number = SearchQuery.where(day: @start_day).count
    @search_queries = SearchQuery.where(day: @start_day).limit(500).order_by(runtime: -1)
  end

  def report_for_session
    @session_id = params[:session_id]
    @feedback = nil
    @feedback = Feedback.find(params[:feedback_id]) if params[:feedback_id]
    @search_queries = SearchQuery.where(session_id: @session_id).order_by(c_at: 1)
  end

  def search_taking_too_long(message)
    if message.to_s =~ /operation exceeded time limit/ || message.to_s =~ /to receive data/
      @search_query = SearchQuery.find(session[:query]) if session[:query].present?
      runtime = Rails.application.config.max_search_time
      @search_query.update_attributes(runtime: runtime, day: Time.now.strftime('%F')) if session[:query].present?
      logger.warn("#{appname_upcase}:SEARCH: Search #{message} #{Rails.application.config.max_search_time} ms")
      session[:query] = nil
      flash[:notice] = 'Your search exceeded the maximum permitted time. Please review your search criteria. Advice is contained in the Help pages.'
    else
      logger.warn("#{appname_upcase}:SEARCH: Search #{session[:query]} had a problem #{message}") if @search_query.present? && @search_query.id.present?
      logger.warn("#{appname_upcase}:SEARCH: Search #{message}") unless @search_query.present? && @search_query.id.present?
      flash[:notice] = 'Your search encountered a problem please contact us with this message '
    end
    redirect_to new_search_query_path(search_id: @search_query)
  end

  def selection
    @start_day = day_param = params[:day] ? DateTime.parse(day_param).strftime('%F') : DateTime.now.strftime('%F')
    @search_queries = SearchQuery.where(day: @start_day).order_by('_id ASC')
    @searches = {}
    @search_queries.each do |search|
      @searches[":#{search.id}"] = search._id
    end
    @search_query = SearchQuery.new
    @options = @searches
    @location = 'location.href= "/search_queries/" + this.value + "/show_query?"'
    @prompt = 'Select query'
    render '_form_for_selection'
  end

  def show
    unless params[:timeout].present?
      @timeout = false
      @search_query, proceed, message = SearchQuery.check_and_return_query(params[:id])
      if params[:sort_option].present?
        @sort_condition = params[:sort_option]
        order_field = params[:sort_option]
        if order_field == @search_query.order_field
          # reverse the directions
          @search_query.order_asc = !@search_query.order_asc unless params[:page].present?
        else
          @search_query.order_field = order_field
          @search_query.order_asc = true
        end
        @search_query.save!
      end
      @search_results, success, error_type = @search_query.search_records.to_a if params[:saved_search].present?
      redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed

      flash[:notice] = 'Your search results are not available. Please repeat your search' if @search_query.result_count.blank?
      redirect_back(fallback_location: new_search_query_path) && return if @search_query.result_count.blank?
      @max_result = FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS unless appname_downcase == 'freebmd'
      @max_result = FreeregOptionsConstants::MAXIMUM_NUMBER_OF_BMD_RESULTS if appname_downcase == 'freebmd'
      @save_search_id = params[:saved_search] if params[:saved_search].present?
      if @search_query.result_count >= @max_result
        @result_count = @search_query.result_count
        @search_results = []
        @ucf_results = []
      else
        response, @search_results, @ucf_results, @result_count = @search_query.get_and_sort_results_for_display unless MyopicVicar::Application.config.template_set == 'freebmd'
        response, @search_results, @ucf_results, @result_count = @search_query.get_bmd_search_results if MyopicVicar::Application.config.template_set == 'freebmd'
        @filter_condition = params[:filter_option]
        @search_results = filtered_results if RecordType::BMD_RECORD_TYPE_ID.include?(@filter_condition.to_i)
        # Issue 693: results_per_page is now a SearchQuery field, set to DEFAULT_RESULTS_PER_PAGE on creation.
        # This allows the selected value to survive the reordering of search results.
        #@search_query[:results_per_page] = assign_value(params[:results_per_page],SearchQuery::DEFAULT_RESULTS_PER_PAGE)
        @search_query[:results_per_page] = params[:results_per_page] if params[:results_per_page].present?
        @page = assign_value(params[:page],SearchQuery::DEFAULT_PAGE)
        @bmd_search_results = @search_results if MyopicVicar::Application.config.template_set == 'freebmd'
        @paginatable_array = @search_query.paginate_results(@search_results, @page, @search_query[:results_per_page])
        if !response || @search_results.nil? || @search_query.result_count.nil?
          logger.warn("#{appname_upcase}:SEARCH_ERROR:search results no longer present for #{@search_query.id}")
          flash[:notice] = 'Your search results are not available. Please repeat your search'
          redirect_to(new_search_query_path(search_id: @search_query)) && return
        end
      end
    else
      @timeout=true
      @search_query, proceed, message = SearchQuery.check_and_return_query(params[:id])
    end
  end

  def assign_value value,default
    value ||= default
    value
  end

  def maximum_results
    case appname_downcase
    when 'freebmd'
      max_result = FreeregOptionsConstants::MAXIMUM_NUMBER_OF_BMD_RESULTS
    when 'freecen'
      max_result = FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS
    when 'freereg'
      max_result = FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS
    end
    max_result
  end

  def show_print_version
    @timeout = false
    @search_query, proceed, message = SearchQuery.check_and_return_query(params[:id])
    redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed

    flash[:notice] = 'Your search results are not available. Please repeat your search' if @search_query.result_count.blank?
    redirect_back(fallback_location: new_search_query_path) && return if @search_query.result_count.blank?
    max_result = FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS unless appname_downcase == 'freebmd'
    max_result = FreeregOptionsConstants::MAXIMUM_NUMBER_OF_BMD_RESULTS if appname_downcase == 'freebmd'
    @printable_format = true
    if @search_query.result_count >= max_result
      @result_count = @search_query.result_count
      @search_results = []
      @ucf_results = []
    else
      response, @search_results, @ucf_results, @result_count = @search_query.get_and_sort_results_for_display unless MyopicVicar::Application.config.template_set == 'freebmd'
      response, @search_results, @ucf_results, @result_count = @search_query.get_bmd_search_results if MyopicVicar::Application.config.template_set == 'freebmd'
      @paginatable_array = @search_results
      @max_result = max_result
      if !response || @search_results.nil? || @search_query.result_count.nil?
        logger.warn("#{appname_upcase}:SEARCH_ERROR:search results no longer present for #{@search_query.id}")
        flash[:notice] = 'Your search results are not available. Please repeat your search'
        redirect_to(new_search_query_path(search_id: @search_query)) && return
      end
    end
    render 'show', layout: 'printable_layout'
  end

  def show_query
    @search_query, proceed, message = SearchQuery.check_and_return_query(params[:id])
    redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed
    @appname = appname
    @view = "show_query_#{appname_downcase}"
  end

  def update
    @search_query = SearchQuery.new(search_params.delete_if { |_k, v| v.blank? })
    @search_query.session_id = request.session_options[:id]
    @chapman_codes = ChapmanCode::CODES
    render :new unless @search_query.save
    redirect_to search_query_path(@search_query)
  end

  def districts_of_selected_counties
    logger.warn(params)
    @selected_districts = params[:selected_districts]
    districts_names = DistrictToCounty.joins(:District).distinct.order( 'DistrictName ASC' )
    county_hash = ChapmanCode.add_parenthetical_codes(ChapmanCode.remove_codes(ChapmanCode::FREEBMD_CODES))
    selected_counties = params[:selected_counties]
    unless selected_counties == 'all'
      selected_counties = selected_counties.split(',').compact unless selected_counties.kind_of?(Array)
      selected_counties = selected_counties.collect(&:strip).reject{|c| c.empty? }
    end
    logger.warn(selected_counties)
    whole_england = ChapmanCode::ALL_ENGLAND.values.flatten
    whole_wales = ChapmanCode::ALL_WALES.values.flatten
    #check_whole_england = whole_england - selected_counties
    #check_whole_wales = whole_wales - selected_counties
    logger.warn("selected_countiesss: #{selected_counties}")
    codes = params[:county_code]
    unless codes.present?
      county_codes = []
      if selected_counties.present?
        county_hash.each {|country, counties|
          selected_counties.each{|c|
            county_codes << county_hash.dig(country).fetch(c) if county_hash.dig(country).keys.include?c
          }
        }
      else
        england_codes = county_hash.dig('England').fetch('All England')
        wales_codes = county_hash.dig('Wales').fetch('All Wales')
        county_codes = england_codes + wales_codes
      end
    else
      unless selected_counties == 'all'
        county_codes = selected_counties
        logger.warn("county codesss: #{county_codes}")
      else
        england_codes = county_hash.dig('England').fetch('All England')
        wales_codes = county_hash.dig('Wales').fetch('All Wales')
        county_codes = england_codes + wales_codes
      end
    end
    @districts = Hash.new
    county_codes.flatten.uniq.reject { |c| c.to_s.empty? }.each { |c|
      @districts[c] = districts_names.where(County: [c]).pluck(:DistrictName, :DistrictNumber)
    }
    @districts
    # rbl 22.1.2025: removed this line to allow 'All England' and 'All Wales' to generate results in the District selection list:
    # @districts = {} if selected_counties.include?("All England") || selected_counties.include?("All Wales") || check_whole_england.empty? || check_whole_wales.empty?
  end

  def districts_of_selected_counties_old
    @selected_districts = params[:selected_districts]
    districts_names = DistrictToCounty.joins(:District).distinct.order( 'DistrictName ASC' )
    county_hash = ChapmanCode.add_parenthetical_codes(ChapmanCode.remove_codes(ChapmanCode::FREEBMD_CODES))
    selected_counties = params[:selected_counties]
    selected_counties = selected_counties.split(',').compact unless selected_counties.kind_of?(Array)
    selected_counties = selected_counties.collect(&:strip).reject{|c| c.empty? }
    whole_england = ChapmanCode::ALL_ENGLAND.values.flatten
    whole_wales = ChapmanCode::ALL_WALES.values.flatten
    check_whole_england = whole_england - selected_counties
    check_whole_wales = whole_wales - selected_counties
    codes = params[:county_code]
    unless codes.present?
      county_codes = []
      county_hash.each {|country, counties|
        selected_counties.each{|c|
          county_codes << county_hash.dig(country).fetch(c) if county_hash.dig(country).keys.include?c
        }
      }
    else
      county_codes = selected_counties
    end
    @districts = Hash.new
    county_codes.flatten.uniq.reject { |c| c.to_s.empty? }.each { |c|
      @districts[c] = districts_names.where(County: [c]).pluck(:DistrictName, :DistrictNumber)
    }
    @districts
    # rbl 22.1.2025: removed this line to allow 'All England' and 'All Wales' to generate results in the District selection list:
    # @districts = {} if selected_counties.include?("All England") || selected_counties.include?("All Wales") || check_whole_england.empty? || check_whole_wales.empty?
  end

  def end_year_val
    @end_year = params[:year]
  end

  def wildcard_options_dropdown
    field = params[:field]
    @options = params[:option] if params[:option].present?
    array = Constant::OPTIONS_HASH[params[:field]]
    middle_name_option = array
    @middle_name_option = middle_name_option
  end

  def download_as_csv
    search_id = params[:id]
    @search_query = SearchQuery.find_by(id: search_id)
    page_number = params[:page]
    results_per_page = params[:results_per_page]
    sorted_results = @search_query.sorted_and_paged_searched_records
    results_per_page.to_i > 50 ? results_per_page = 50 : results_per_page = results_per_page
    paginated_array = @search_query.paginate_results(sorted_results,page_number,results_per_page)
    send_data search_results_csv(paginated_array), filename: "search_results-#{Date.today}.csv"
  end

  def download_as_gedcom
    search_id = params[:id]
    @search_query = SearchQuery.find_by(id: search_id)
    page_number = params[:page]
    results_per_page = params[:results_per_page]
    sorted_results = @search_query.sorted_and_paged_searched_records
    paginated_array = @search_query.paginate_results(sorted_results,page_number,results_per_page)
    send_data @search_query.search_results_gedcom(paginated_array,@user).join("\n"), filename: "search_results-#{Date.today}.ged"
  end

  def compare_search
    #raise params.inspect
    get_user_info_from_userid
    @search_query, proceed, message = SearchQuery.check_and_return_query(params[:id])
    redirect_back(fallback_location: new_search_query_path) && return if @search_query.result_count.blank?
    @save_search_id = params[:saved_search_id]
    @saved_search = @user.saved_searches.find(@save_search_id)
    @saved_search_result_hash = @saved_search.saved_search_result.records.keys
    saved_search_response, saved_search_results, @ucf_save_results, @save_result_count = @saved_search.get_bmd_saved_search_results
    @save_search_results = @search_query.sort_results(saved_search_results)
    response, @search_results, @ucf_results, @result_count = @search_query.get_bmd_search_results
    if params[:filter_option].present?
      @filter_condition = params[:filter_option]
      @search_results = filtered_search_results #if filtered_search_results.present?
      @save_search_results = filter_saved_search_results #if filter_saved_search_results.present?
    end
  end

  def filtered_results
    @search_results.select{ |r|  r["RecordTypeID"] == @filter_condition.to_i }
  end

  def filtered_search_results
    filter_cond = @filter_condition.to_i
    if RecordType::BMD_RECORD_TYPE_ID.include?(filter_cond)
      records = filter(@search_results)
    elsif filter_cond == 4
      select_hash = @search_query.search_result.records.keys - @saved_search_result_hash
      result = @search_query.search_result.records.select{|k,v| select_hash.include?(k)}
      records = result.values.map{|h| BestGuess.new(h)}
    else filter_cond == 5
      records = nil
    end
    records
  end

  def filter_saved_search_results
    filter_cond = @filter_condition.to_i
    if RecordType::BMD_RECORD_TYPE_ID.include?(filter_cond)
      records = filter(@save_search_results)
    elsif filter_cond == 4
      records = nil
    else filter_cond == 5
      select_hash = @saved_search_result_hash - @search_query.search_result.records.keys
      result = @saved_search.saved_search_result.records.select{|k,v| select_hash.include?(k)}
      records = result.values.map{|h| BestGuess.new(h)}#BestGuess.get_best_guess_records(select_hash)
    end
    records
  end

  def select_counties
    prefix = params[:prefix].split(',').pop.strip.downcase
    @counties_group = ChapmanCode.add_parenthetical_codes(ChapmanCode.remove_codes(ChapmanCode::FREEBMD_CODES))
    county_keys = []
    counties_array = @counties_group.each{|ctry, county| county_keys << county.keys }
    if (params[:prefix].strip.include?'All England') || (params[:prefix].strip.include?'All Wales')
      county_keys = ['All England', 'All Wales']
    end
    @counties = county_keys.flatten.select { |s| s.downcase.include?(prefix) }
    respond_to do |format|
      format.html
      format.json {
        render json: @counties
      }
    end
  end

  private

  def search_params
    params.require(:search_query).permit!
  end

  def filter(results)
    results.select{|r| r["RecordTypeID"] == @filter_condition.to_i }
  end

end
