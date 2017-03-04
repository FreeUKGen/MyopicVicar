class TransregUsersController < ApplicationController
  skip_before_action :require_login
  def new
    logger.warn "FREEREG::USER Entered transreg session #{session[:userid_detail_id]}  cookie #{cookies.signed[:userid].id}"
    if session[:userid_detail_id].nil? && cookies.signed[:userid].blank?
      render(:text => { "result" => "failure", "message" => "You are not authorised to use these facilities"}.to_xml({:root => 'login'}))
      return
    end
    @user = UseridDetail.id(session[:userid_detail_id]).first unless session[:userid_detail_id].nil?
    @user = cookies.signed[:userid] if session[:userid_detail_id].nil?

    render(:text => { "result" => "Logged in", :userid_detail => @user.attributes}.to_xml({:dasherize => false, :root => 'login'}))

  end

  def index
  end

  def computer
    @computer_id = params[:computerid]
    @computer_password =  Devise::Encryptable::Encryptors::Freereg.digest(params[:computeridpassword],nil,nil,nil)
    @computer = UseridDetail.userid(@computer_id).first
    unless @computer.present? && @computer_id == "transreg" && @computer_password == @computer.password
      logger.warn "FREEREG::COMPUTER failed to enter transreg  with #{@scomputer_id}   #{@computer_password }"
      render(:text => { "result" => "failure", "message" => "You are not authorised to use these facilities"}.to_xml({:root => 'login'}))
      return
    end
    logger.warn "FREEREG::COMPUTER logged in with #{@computer_id}   #{@computer_password }"
    session[:userid_detail_id] = @computer.id
    @transcriber_id = params[:transcriberid]
    @transcriber_password = Devise::Encryptable::Encryptors::Freereg.digest(params[:transcriberpassword],nil,nil,nil)
    @user = UseridDetail.where(:userid => @transcriber_id).first
    logger.warn "FREEREG::COMPUTER for user #{@transcriber_id}   #{@transcriber_password }"

    if @user.nil? then
      p "Unknown User"
      render(:text => { "result" => "unknown_user" }.to_xml({:root => 'authentication'}))
    else
      p "Known Transcriber"
      if @transcriber_password == @user.password then
        p "Password matches"
        render(:text => {"result" => "success", :userid_detail => @user}.to_xml({:dasherize => false, :root => 'authentication'}))
      else
        p "No match on Password"
        render(:text => { "result" => "no_match" }.to_xml({:root => 'authentication'}))
      end
    end
  end

  def refreshuser
    @transcriber_id = params[:transcriberid]
    @user = UseridDetail.where(:userid => @transcriber_id).first
    logger.warn "FREEREG::COMPUTER refreshed user #{@transcriber_id} "
    if @user.nil? then
      render(:text => { "result" => "failure", "message" => "Invalid transcriber id"}.to_xml({:root => 'refresh'}))
    else
      render(:text => {"result" => "success", :userid_detail => @user.attributes}.to_xml({:dasherize => false, :root => 'refresh'}))
    end
  end

  # AUTHENTICATE - Authenticates a subscriber's userid and password
  #
  def authenticate

    @transcriber_id = params[:transcriberid]
    @transcriber_password = Devise::Encryptable::Encryptors::Freereg.digest(params[:transcriberpassword],nil,nil,nil)
    @user = UseridDetail.where(:userid => @transcriber_id).first
    if @user.nil? then
      p "Unknown User"
      render(:text => { "result" => "unknown_user" }.to_xml({:root => 'authentication'}))
    else
      p "Known Transcriber"
      if @transcriber_password == @user.password then
        p "Password matches"
        render(:text => {"result" => "success", :userid_detail => @user}.to_xml({:dasherize => false, :root => 'authentication'}))
        p session[:userid_detail_id]
      else
        p "No match on Password"
        render(:text => { "result" => "no_match" }.to_xml({:root => 'authentication'}))
      end
    end
  end

end
