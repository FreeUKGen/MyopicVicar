class EmbargoRulesController < ApplicationController

  def create
    redirect_back(fallback_location: { action: 'index', county: session[:county], place: session[:place], church: session[:church], register: session[:register] },
                  otice: 'You must enter a field ') && return if params[:embargo_rule].blank?

    @rule = EmbargoRule.new(embargo_rule_params)
    @rule.save
    if @rule.errors.any?
      flash[:notice] = "The creation of the new rule was unsuccessful because #{@rule.errors.messages}"
      redirect_to action: 'new', county: session[:county], place: session[:place], church: session[:church], register: session[:register]
    else

      flash[:notice] = 'The creation of the new rule was successful'
      redirect_to action: 'index', county: session[:county], place: session[:place], church: session[:church], register: session[:register]
    end
  end

  def destroy
    @rule = EmbargoRule.find(params[:id])
    redirect_back(fallback_location: { action: 'index', county: session[:county], place: session[:place], church: session[:church], register: session[:register] },
                  notice: 'The embargo rule was not found ') && return if @rule.blank?
    extract_location_from_params(params)
    get_user_info_from_userid
    reject_access(@user, 'Embargo Reason') unless @user.person_role == 'system_administrator' || @user.person_role == 'executive_director'

    @rule.destroy
    flash[:notice] = 'The destruction of the embargo rule was successful'
    redirect_to action: 'index', county: session[:county], place: session[:place], church: session[:church], register: session[:register]
  end

  def edit
    extract_location_from_params(params)
    @rule = EmbargoRule.find(params[:id])
    redirect_back(fallback_location: { action: 'index', county: session[:county], place: session[:place], church: session[:church], register: session[:register] },
                  notice: 'The embargo rule was not found ') && return if @rule.blank?
    @types = RecordType.all_types
    @options = EmbargoRule::EmbargoRuleOptions::ALL_OPTIONS
    get_user_info_from_userid
    reject_access(@user, 'Embargo Reason') unless @user.person_role == 'system_administrator' || @user.person_role == 'executive_director'
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
    reject_access(@user, 'Embargo Reason') unless @user.person_role == 'system_administrator' || @user.person_role == 'executive_director'
    @types = RecordType.all_types
    @options = EmbargoRule::EmbargoRuleOptions::ALL_OPTIONS
    @rule = EmbargoRule.new
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
    proceed = @rule.update_attributes(embargo_rule_params)
    if proceed
      flash[:notice] = 'The update of the embargo rule was successful'
      redirect_to action: 'index', county: session[:county], place: session[:place], church: session[:church], register: session[:register]
    else
      flash[:notice] =  "The embargo rule update was unsuccessful; #{@rule.errors.messages}"
      redirect_to action: 'new', county: session[:county], place: session[:place], church: session[:church], register: session[:register]
    end
  end

  private

  def embargo_rule_params
    params.require(:embargo_rule).permit!
  end
end
