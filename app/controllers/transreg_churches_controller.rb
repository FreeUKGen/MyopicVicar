class TransregChurchesController < ApplicationController

  def list
  	if session[:userid].nil?
      render(:text => { "result" => "failure", "message" => "You are not authorised to use these facilities"}.to_xml({:root => 'list'}))
      return
  	end

  	@user = UseridDetail.where(:userid => session[:userid]).first
 
    @my_place = Place.where(:chapman_code => params[:county], :place_name => params[:place],:disabled => "false").first
    if @my_place
      @churches = @my_place.churches unless @my_place.blank?
    else
      @churches = nil
    end

  	respond_to do |format|
  		format.html
  		format.xml
  	end
  end

end
