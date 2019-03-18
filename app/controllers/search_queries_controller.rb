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
  rescue_from Mongo::Error::OperationFailure, with: :search_taking_too_long
  rescue_from Mongoid::Errors::DocumentNotFound, with: :missing_document
  rescue_from ActionController::UnknownFormat, with: :github_camo
  rescue_from ActionView::Template::Error, with: :missing_template
  rescue_from Timeout::Error, with: :search_taking_too_long
  RECORDS_PER_PAGE = 100

  def about
    @page_number = params[:page_number].present? ? params[:page_number].to_i : 0
    @search_query, proceed, message = SearchQuery.check_and_return_query(params[:id])
    redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed
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
    @search_query.save
    @search_results = @search_query.search
    redirect_to search_query_path(@search_query.id)
  end

  def create
    # binding.pry
    condition = true if params[:search_query].present? && params[:search_query][:region].blank?
    redirect_back(fallback_location: new_search_query_path, notice: 'Invalid Search') && return unless condition

    do_not_proceed, message = SearchQuery.invalid_integer(params[:search_query])
    redirect_back(fallback_location: new_search_query_path, notice: message) && return if do_not_proceed

    @search_query = SearchQuery.new(search_params.delete_if { |k, v| v.blank? })
    @search_query['first_name'] = @search_query['first_name'].strip if @search_query['first_name'].present?
    @search_query['last_name'] = @search_query['last_name'].strip if @search_query['last_name'].present?
    @search_query['chapman_codes'] = ['', 'ERY', 'NRY', 'WRY'] if @search_query['chapman_codes'][1].eql?('YKS')
    @search_query['birth_chapman_codes'] = ['', 'ERY', 'NRY', 'WRY'] if @search_query['birth_chapman_codes'][1].eql?('YKS')
    @search_query['chapman_codes'] = ['', 'ALD', 'GSY', 'JSY', 'SRK'] if @search_query['chapman_codes'][1].eql?('CHI')
    @search_query['birth_chapman_codes'] = ['', 'ALD', 'GSY', 'JSY', 'SRK'] if @search_query['birth_chapman_codes'][1].eql?('CHI')
    @search_query.session_id = request.session_options[:id]
    if @search_query.save
      session[:query] = @search_query.id
      @search_results = @search_query.search
      redirect_to search_query_path(@search_query)
    else
      render :new
    end
  end

  def edit
    @search_query, proceed, message = SearchQuery.check_and_return_query(params[:id])
    redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed
  end

  def github_camo
    logger.warn("FREEREG:SEARCH: Search encountered an UnknownFormat #{params}")
    flash[:notice] = 'We encountered an UnknownFormat'
    redirect_to new_search_query_path
  end

  def index
    redirect_to action: :new
  end

  def missing_document
    appname = MyopicVicar::Application.config.freexxx_display_name.upcase
    logger.warn("#{appname}:SEARCH: Search encountered a missing document #{params}")
    flash[:notice] = 'We encountered a problem executing your request. You need to restart your query. If the problem continues please contact us explaining what you were doing that led to the failure.'
    redirect_to new_search_query_path
  end

  def missing_template
    appname = MyopicVicar::Application.config.freexxx_display_name.upcase
    logger.warn("#{appname}:SEARCH: Search encountered a missing template #{params}")
    flash[:notice] = 'We encountered a problem executing your request. You need to restart your query. If the problem continues please contact us explaining what you were doing that led to the failure.'
    redirect_to new_search_query_path
  end

  def narrow
    old_query, proceed, message = SearchQuery.check_and_return_query(params[:id])
    redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed

    new_parameters = old_query.reduce_attributes
    @search_query = SearchQuery.new(new_parameters)
    @search_query.radius_factor = @search_query.radius_factor / 2
    @search_query.save
    @search_results = @search_query.search
    redirect_to search_query_path(@search_query.id)
  end

  def new
    @page = session[:message] == 'load' ? Refinery::Page.where(slug: 'message').first.parts.first.body.html_safe : nil

    session.delete(:search_controller)
    @search_query = SearchQuery.new
    old_query = SearchQuery.search_id(params[:search_id]).first if params[:search_id]

    old_query.search_result.records = {} if old_query.present? && old_query.search_result.present?
    @search_query = SearchQuery.new(old_query.attributes) if old_query.present?
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
    appname = MyopicVicar::Application.config.freexxx_display_name.upcase
    if message.to_s =~ /operation exceeded time limit/ || message.to_s =~ /to receive data/
      @search_query = SearchQuery.find(session[:query])
      runtime = Rails.application.config.max_search_time
      @search_query.update_attributes(runtime: runtime, day: Time.now.strftime('%F'))
      logger.warn("#{appname}:SEARCH: Search #{@search_query.id} took too long #{Rails.application.config.max_search_time} ms")
      session[:query] = nil
      flash[:notice] = 'Your search was running too long. Please review your search criteria. Advice is contained in the Help pages.'
    else
      logger.warn("#{appname}:SEARCH: Search #{@search_query.id} had a problem #{message}") if @search_query.present? && @search_query.id.present?
      logger.warn("#{appname}:SEARCH: Search #{message}") unless @search_query.present? && @search_query.id.present?
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
    appname = MyopicVicar::Application.config.freexxx_display_name.upcase
    @search_query, proceed, message = SearchQuery.check_and_return_query(params[:id])
    redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed

    flash[:notice] = 'Your search results are not available. Please repeat your search' if @search_query.result_count.blank?
    redirect_back(fallback_location: new_search_query_path) && return if @search_query.result_count.blank?

    if @search_query.result_count > FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS
      @result_count = @search_query.result_count
      @search_results = []
      @ucf_results = []
    else
      response, @search_results, @ucf_results, @result_count = @search_query.get_and_sort_results_for_display
      if !response || @search_results.nil? || @search_query.result_count.nil?
        logger.warn("#{appname}:SEARCH_ERROR:search results no longer present for #{@search_query.id}")
        flash[:notice] = 'Your search results are not available. Please repeat your search'
        redirect_to(new_search_query_path(search_id: @search_query)) && return
      end
    end
  end

  def show_print_version
    appname = MyopicVicar::Application.config.freexxx_display_name.upcase
    @search_query, proceed, message = SearchQuery.check_and_return_query(params[:id])
    redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed

    flash[:notice] = 'Your search results are not available. Please repeat your search' if @search_query.result_count.blank?
    redirect_back(fallback_location: new_search_query_path) && return if @search_query.result_count.blank?

    @printable_format = true
    if @search_query.result_count > FreeregOptionsConstants::MAXIMUM_NUMBER_OF_RESULTS
      @result_count = @search_query.result_count
      @search_results = []
      @ucf_results = []
    else
      response, @search_results, @ucf_results, @result_count = @search_query.get_and_sort_results_for_display
      if !response || @search_results.nil? || @search_query.result_count.nil?
        logger.warn("#{appname}:SEARCH_ERROR:search results no longer present for #{@search_query.id}")
        flash[:notice] = 'Your search results are not available. Please repeat your search'
        redirect_to(new_search_query_path(search_id: @search_query)) && return
      end
    end
    render 'show', layout: false
  end

  def show_query
    @search_query, proceed, message = SearchQuery.check_and_return_query(params[:id])
    redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed
  end

  def update
    @search_query = SearchQuery.new(search_params.delete_if { |k, v| v.blank? })
    @search_query.session_id = request.session_options[:id]
    if @search_query.save
      redirect_to search_query_path(@search_query)
    else
      render :edit
    end
  end

  private

  def search_params
    params.require(:search_query).permit!
  end
end
