class TransregPlacesController < ApplicationController

  def list
  	if session[:userid].nil?
      render(:text => { "result" => "failure", "message" => "You are not authorised to use these facilities"}.to_xml({:root => 'list'}))
      return
  	end

  	@user = UseridDetail.where(:userid => session[:userid]).first
    @county = ChapmanCode.has_key(params[:county])

    @places = Place.where( :chapman_code => params[:county]).all.order_by( place_name: 1)

  	respond_to do |format|
  		format.html
  		format.xml
  	end
  end

end
