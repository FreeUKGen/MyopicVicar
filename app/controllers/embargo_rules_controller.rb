class EmbargoRulesController < ApplicationController
  def create
    redirect_back(fallback_location: { action: 'index', county: session[:county], place: session[:place], church: session[:church], register: session[:register] },
                  notice: 'You must enter a complete set of fields') && return if params[:embargo_rule].blank?

    params[:embargo_rule][:period_type] = params[:embargo_rule][:rule] == 'Embargoed until the end of ' ? 'end' : 'period'
    @rule = EmbargoRule.new(embargo_rule_params)
    if @rule.save
      flash[:notice] = 'The creation of the new rule was successful'
      redirect_to action: 'index', county: session[:county], place: session[:place], church: session[:church], register: session[:register]
    else
      flash[:notice] = "The creation of the new rule was unsuccessful because #{@rule.errors.messages}"
      redirect_to action: 'new', county: session[:county], place: session[:place], church: session[:church], register: session[:register]
    end
  end

  def destroy
    @rule = EmbargoRule.find(params[:id])
    redirect_back(fallback_location: { action: 'index', county: session[:county], place: session[:place], church: session[:church], register: session[:register] },
                  notice: 'The embargo rule was not found ') && return if @rule.blank?
    extract_location_from_params(params)
    get_user_info_from_userid
    reject_access(@user, 'Embargo Reason') unless session[:role] == 'system_administrator' || session[:role] == 'executive_director'

    @rule.destroy
    flash[:notice] = 'The destruction of the embargo rule was successful'
    redirect_to action: 'index', county: session[:county], place: session[:place], church: session[:church], register: session[:register]
  end

  def edit
    extract_location_from_params(params)
    @rule = EmbargoRule.find(params[:id])
    redirect_back(fallback_location: { action: 'index', county: session[:county], place: session[:place], church: session[:church], register: session[:register] },
                  notice: 'The embargo rule was not found ') && return if @rule.blank?
    @types = RecordType::ALL_FREEREG_TYPES
    @options = EmbargoRule::EmbargoRuleOptions::ALL_OPTIONS
    @edit = true
    get_user_info_from_userid
    reject_access(@user, 'Embargo Reason') unless ['system_administrator', 'executive_director', 'county_coordinator', 'data_manager', 'country_coordinator'].include?(session[:role])
  end

  def extract_location_from_params(param)
    @county = param[:county]
    @place = Place.find(param[:place])
    @church = Church.find(param[:church])
    @register = Register.find(param[:register])
    session[:county] = param[:county]
    session[:place] = param[:place]
    session[:church] = param[:church]
    session[:register] = param[:register]
    @register_type = @register.register_type
    @church_name = @church.church_name
    @place_name = @place.place_name
  end

  def index
    get_user_info_from_userid
    extract_location_from_params(params)
    @rules = EmbargoRule.where(register_id: @register.id).all.order_by(rule: 1)
  end

  def new
    extract_location_from_params(params)
    get_user_info_from_userid
    reject_access(@user, 'Embargo Reason') unless ['system_administrator', 'executive_director', 'county_coordinator', 'data_manager', 'country_coordinator'].include?(session[:role])

    @options = EmbargoRule::EmbargoRuleOptions::ALL_OPTIONS
    rules = []
    EmbargoRule.where(register_id: @register.id).all.order_by(rule: 1).all.each do |rule|
      rules << rule.record_type
    end
    @types = RecordType.all_types - rules
    @rule = EmbargoRule.new
    @edit = false
  end

  def show
    @rule = EmbargoRule.find(params[:id])
    redirect_back(fallback_location: { action: 'index', county: session[:county], place: session[:place], church: session[:church], register: session[:register] },
                  notice: 'The embargo rule was not found ') && return if @rule.blank?

    extract_location_from_params(params)
    get_user_info_from_userid
  end

  def update
    @rule = EmbargoRule.find(params[:id])
    redirect_back(fallback_location: { action: 'index', county: session[:county], place: session[:place], church: session[:church], register: session[:register] },
                  notice: 'The embargo rule was not found ') && return if @rule.blank?

    get_user_info_from_userid
    proceed = @rule.update(period: params[:embargo_rule][:period], authority: params[:embargo_rule][:authority], reason: params[:embargo_rule][:reason])
    if proceed
      flash[:notice] = 'The update of the embargo rule was successful'
      redirect_to action: 'index', county: session[:county], place: session[:place], church: session[:church], register: session[:register]
    else
      flash[:notice] =  "The embargo rule update was unsuccessful; #{@rule.errors.messages}"
      redirect_to action: 'edit', county: session[:county], place: session[:place], church: session[:church], register: session[:register]
    end
  end

  def process_embargo_rule
    get_user_info_from_userid
    @rule = EmbargoRule.find(params[:id])
    process = @rule.process_embargo_records(@user.email_address)
    if process.success?
      flash[:notice] =  process.message
    else
      flash[:notice] =  process.error
    end
    redirect_to action: 'index', county: session[:county], place: session[:place], church: session[:church], register: session[:register]
  end

  private

  def embargo_rule_params
    params.require(:embargo_rule).permit!
  end
end
