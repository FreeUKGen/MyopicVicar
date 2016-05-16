class SearchQueriesController < ApplicationController
  skip_before_filter :require_login
  skip_before_filter :require_cookie_directive, :only => :new
  before_filter :check_for_mobile, :only => :show
  RECORDS_PER_PAGE = 100
  def index
    redirect_to :action => :new
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
    current_refinery_user.userid_detail.remember_search(@search_query)
    flash[:notice] = "This search has been added to your remembered searches"
    redirect_to search_query_path(@search_query)
  end

  def broaden
    old_query = SearchQuery.find(params[:id])
    @search_query = SearchQuery.new(old_query.attributes)
    @search_query.radius_factor = @search_query.radius_factor * 2
    @search_query.search_result = nil
    @search_query.save
    @search_results = @search_query.search
    redirect_to search_query_path(@search_query)
  end

  def narrow
    old_query = SearchQuery.find(params[:id])
    @search_query = SearchQuery.new(old_query.attributes)
    @search_query.radius_factor = @search_query.radius_factor / 2
    @search_query.search_result = nil
    @search_query.save
    @search_results = @search_query.search
    redirect_to search_query_path(@search_query)
  end

  def create
    if params[:search_query].present? && params[:search_query][:region].blank?
      @search_query = SearchQuery.new(params[:search_query].delete_if{|k,v| v.blank? })
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
        @search_results = @search_query.search
        redirect_to search_query_path(@search_query)
      else
        render :new
      end
    else
      render :new
    end
  end

  # default criteria:
  # today
  def report
    if params[:session_id]
      report_for_session
    else
      report_for_day
    end
  end

  def report_for_day
    if day_param = params[:day]
      @start_day = DateTime.parse(day_param)
    else
      @start_day = DateTime.now
    end
    unless order_param = params[:order]
      order_param = :runtime
    end
    @end_day = @start_day
    @start_time = @start_day.beginning_of_day.utc
    @end_time = @end_day.end_of_day.utc
    @search_queries = SearchQuery.where(:c_at.gte => @start_time, :c_at.lte => @end_time).desc(order_param)
  end

  def report_for_session
    @session_id = params[:session_id]
    @feedback = nil
    if params[:feedback_id]
      @feedback = Feedback.find(params[:feedback_id])
    end
    @search_queries = SearchQuery.where(:session_id => @session_id).asc(:c_at)
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

  def go_back
    flash[:notice] = "We encountered a problem completing your request. Please resubmit. If this situation continues please let us know through the Contact Us link at the foot of this page"
    redirect_to new_search_query_path
    return
  end


  def edit
    @search_query = SearchQuery.find(params[:id])

  end
  def update
    @search_query = SearchQuery.new(params[:search_query].delete_if{|k,v| v.blank? })
    @search_query.session_id = request.session_options[:id]

    if  @search_query.save
      redirect_to search_query_path(@search_query)
    else
      render :edit
    end

  end

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


end
