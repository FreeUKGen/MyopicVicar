class TransregPlacesController < ApplicationController

  def list
    if session[:userid_detail_id].nil?
      render(:text => { "result" => "failure", "message" => "You are not authorised to use these facilities"}.to_xml({:root => 'list'}))
      return
    end

    @user = UseridDetail.id(session[:userid_detail_id]).first
    @county = ChapmanCode.has_key(params[:county])

    @places = Place.chapman_code(params[:county]).not_disabled.all.order_by( place_name: 1)

    respond_to do |format|
      format.html
      format.xml
    end
  end

end
