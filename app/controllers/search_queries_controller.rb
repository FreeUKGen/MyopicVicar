class SearchQueriesController < ApplicationController
  skip_before_action :require_login
  skip_before_action :require_cookie_directive, :only => :new
  skip_before_action :verify_authenticity_token
  before_action :check_for_mobile, :only => :show
  rescue_from Mongo::Error::OperationFailure, :with => :search_taking_too_long
  RECORDS_PER_PAGE = 100

  def about
    if params[:page_number]
      @page_number = params[:page_number].to_i
    else
      @page_number = 0
    end
    begin
      @search_query = SearchQuery.find(params[:id])
    rescue Mongoid::Errors::DocumentNotFound
      log_possible_host_change
      redirect_to new_search_query_path
    end
  end

  def analyze
    @search_query = SearchQuery.find(params[:id])
    begin
      @plan = @search_query.explain_plan
    rescue => ex
      @plan_error = ex.message
      @plan = @search_query.explain_plan_no_sort
    end
  end

  def broaden
    old_query = SearchQuery.find(params[:id])
    new_parameters = old_query.reduce_attributes
    @search_query = SearchQuery.new(new_parameters)
    @search_query.radius_factor = @search_query.radius_factor * 2
    @search_query.save
    @search_results = @search_query.search
    redirect_to search_query_path(@search_query.id)
  end

  def create
    if params[:search_query].present? && params[:search_query][:region].blank?
      @search_query = SearchQuery.new(search_params.delete_if{|k,v| v.blank? })
      @search_query["first_name"] = @search_query["first_name"].strip unless @search_query["first_name"].nil?
      @search_query["last_name"] = @search_query["last_name"].strip unless @search_query["last_name"].nil?
      if @search_query["chapman_codes"][1].eql?("YKS")
        @search_query["chapman_codes"] = ["", "ERY", "NRY", "WRY"]
      end
      if @search_query["chapman_codes"][1].eql?("CHI")
        @search_query["chapman_codes"] = ["", "ALD", "GSY", "JSY", "SRK"]
      end
      @search_query.session_id = request.session_options[:id]
      if  @search_query.save
        session[:query] = @search_query.id
        @search_results = @search_query.search
        redirect_to search_query_path(@search_query)
      else
        render :new
      end
    else
      render :new
    end
  end

  def edit
    @search_query = SearchQuery.find(params[:id])
  end

  def go_back
    flash[:notice] = "We encountered a problem completing your request. Please resubmit. If this situation continues please let us know through the Contact Us link at the foot of this page"
    redirect_to new_search_query_path
    return
  end

  def index
    redirect_to :action => :new
  end

  def narrow

    old_query = SearchQuery.find(params[:id])
    new_parameters = old_query.reduce_attributes
    @search_query = SearchQuery.new(new_parameters)
    @search_query.radius_factor = @search_query.radius_factor / 2
    @search_query.save
    @search_results = @search_query.search
    redirect_to search_query_path(@search_query.id)
  end

  def new
    if @page = Refinery::Page.where(:slug => 'message').exists?
      @page = Refinery::Page.where(:slug => 'message').first.parts.first.body.html_safe
    else
      @page = nil
    end
    if params[:search_id]
      old_query = SearchQuery.search_id(params[:search_id]).first
      if old_query.present?
        @search_query = SearchQuery.new(old_query.attributes)
      else
        @search_query = SearchQuery.new
      end
    else
      @search_query = SearchQuery.new
    end
  end

  def remember
    @search_query = SearchQuery.find(params[:id])
    get_user_info_from_userid
    @user.remember_search(@search_query)
    flash[:notice] = "This search has been added to your remembered searches"
    redirect_to search_query_path(@search_query)
  end

  def reorder
    old_query = SearchQuery.find(params[:id])
    order_field=params[:order_field]
    if order_field==old_query.order_field
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
      @start_day = DateTime.parse(day_param).strftime("%F")
    else
      @start_day = DateTime.now.strftime("%F")
    end
    unless order_param = params[:order]
      order_param = :runtime
    end
    @previous_day = (Date.parse(@start_day) - 1).strftime("%F")
    @next_day = (Date.parse(@start_day) + 1).strftime("%F")
    @search_queries = SearchQuery.where(:day => @start_day).desc(order_param).page(params[:page]).per(100)
  end

  def report_for_session
    @session_id = params[:session_id]
    @feedback = nil
    if params[:feedback_id]
      @feedback = Feedback.find(params[:feedback_id])
    end
    @search_queries = SearchQuery.where(:session_id => @session_id).asc(:c_at)
  end

  def search_taking_too_long
    @search_query = SearchQuery.find(session[:query])
    runtime = Rails.application.config.max_search_time
    @search_query.update_attributes(:runtime => runtime, :day => Time.now.strftime("%F"))
    logger.warn("FREEREG:SEARCH: Search #{@search_query.id} took too long #{Rails.application.config.max_search_time} ms")
    session[:query] = nil
    flash[:notice] = "Your search was running too long. Possibly as the result of including a date range. The search currently performs better using location criteria."
    redirect_to new_search_query_path(:search_id => @search_query)
  end

  def selection
    if day_param = params[:day]
      @start_day = DateTime.parse(day_param).strftime("%F")
    else
      @start_day = DateTime.now.strftime("%F")
    end
    @search_queries = SearchQuery.where(:day => @start_day).order_by("_id ASC")
    @searches = Hash.new
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
    if params[:id].present?
      @search_query = SearchQuery.where(:id => params[:id]).first
    else
      logger.warn("FREEREG:SEARCH_ERROR:nil parameter condition occurred")
      go_back
      return
    end
    if @search_query.present?
      @search_results =   @search_query.results
      @ucf_results = @search_query.ucf_results
    else
      logger.warn("FREEREG:SEARCH_ERROR:search query no longer present")
      go_back
      return
    end
    if @search_results.nil? || @search_query.result_count.nil?
      logger.warn("FREEREG:SEARCH_ERROR:search results no longer present")
      go_back
      return
    end
  end

  def show_print_version
    @printable_format = true;
    if params[:id].present?
      @search_query = SearchQuery.where(:id => params[:id]).first
    else
      logger.warn("FREEREG:SEARCH_ERROR:nil parameter condition occurred")
      go_back
      return
    end
    if @search_query.present?
      @search_results =   @search_query.results
    else
      logger.warn("FREEREG:SEARCH_ERROR:search query no longer present")
      go_back
      return
    end
    if @search_results.nil? || @search_query.result_count.nil?
      logger.warn("FREEREG:SEARCH_ERROR:search results no longer present")
      go_back
      return
    end
    render "show", :layout => false
  end

  def show_query
    if params[:id].present?
      @search_query = SearchQuery.where(:id => params[:id]).first
    else
      logger.warn("FREEREG:SEARCH_ERROR:nil parameter condition occurred")
      go_back
      return
    end
  end

  def update
    @search_query = SearchQuery.new(search_params.delete_if{|k,v| v.blank? })
    @search_query.session_id = request.session_options[:id]
    if  @search_query.save
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
