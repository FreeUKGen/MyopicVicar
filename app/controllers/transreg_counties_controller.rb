class TransregCountiesController < ApplicationController

  def list
    if session[:userid_detail_id].nil?
      render(:text => { "result" => "failure", "message" => "You are not authorised to use these facilities"}.to_xml({:root => 'list'}))
      return
    end

    @user = cookies.signed[:userid]
    @first_name = @user.person_forename
    @counties = County.all.order_by(chapman_code: 1)

    respond_to do |format|
      format.html
      format.xml
    end
  end

  def register_types
    if session[:userid_detail_id].nil?
      render(:text => { "result" => "failure", "message" => "You are not authorised to use these facilities"}.to_xml({:root => 'register_types'}))
      return
    end

    @types = RegisterType::APPROVED_OPTIONS

    respond_to do |format|
      format.html
      format.xml
    end
  end
  def all_register_types
    if session[:userid_detail_id].nil?
      render(:text => { "result" => "failure", "message" => "You are not authorised to use these facilities"}.to_xml({:root => 'register_types'}))
      return
    end

    @types = RegisterType::OPTIONS

    respond_to do |format|
      format.html
      format.xml
    end
  end

end
