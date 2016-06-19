class TransregCountiesController < ApplicationController

  def list
  	if session[:userid].nil?
      render(:text => { "result" => "failure", "message" => "You are not authorised to use these facilities"}.to_xml({:root => 'list'}))
      return
  	end

  	@first_name = session[:first_name]
  	@user = UseridDetail.where(:userid => session[:userid]).first

  	@counties = County.all.order_by(chapman_code: 1)

  	respond_to do |format|
  		format.html
  		format.xml
  	end
  end

  def register_types
    if session[:userid].nil?
      render(:text => { "result" => "failure", "message" => "You are not authorised to use these facilities"}.to_xml({:root => 'register_types'}))
      return
    end

    @types = RegisterType::APPROVED_OPTIONS

    respond_to do |format|
      format.html
      format.xml
    end
  end

end
