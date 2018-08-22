class TransregUsersController < ApplicationController
  skip_before_action :require_login
  def new
    user = get_user
    logger.warn "FREEREG::USER Entered transreg session #{session[:userid_detail_id]}  cookie #{user.id}"
    user = get_user
    if session[:userid_detail_id].nil? && user.blank?
      render(:text => { "result" => "failure", "message" => "You are not authorised to use these facilities"}.to_xml({:root => 'login'}))
      return
    end
    @user = UseridDetail.id(session[:userid_detail_id]).first unless session[:userid_detail_id].nil?
    @user = user if session[:userid_detail_id].nil?

    render(:text => { "result" => "Logged in", :userid_detail => @user.attributes}.to_xml({:dasherize => false, :root => 'login'}))

  end

  def index
  end

  def computer
    @computer_id = params[:computerid]
    logger.warn "FREEREG::COMPUTER logging in with #{@computer_id}   #{params[:computeridpassword]}"
    #temp kludge as it appears that there are 2 package passwords
    params[:computeridpassword] = 'temppasshoppe' if params[:computeridpassword] == 'temppasshope'  
    @computer_password =  Devise::Encryptable::Encryptors::Freereg.digest(params[:computeridpassword],nil,nil,nil)
    @computer = UseridDetail.userid(@computer_id).first
    unless @computer.present? && @computer_id == "transreg" && @computer_password == @computer.password
      logger.warn "FREEREG::COMPUTER failed to enter transreg  with #{@scomputer_id}   #{@computer_password }"
      render(:text => { "result" => "failure", "message" => "You are not authorised to use these facilities"}.to_xml({:root => 'login'}))
      return
    end
    logger.warn "FREEREG::COMPUTER logged in with #{@computer_id}   #{params[:computeridpassword]}"
    session[:userid_detail_id] = @computer.id
    @transcriber_id = params[:transcriberid]
    @transcriber_password = Devise::Encryptable::Encryptors::Freereg.digest(params[:transcriberpassword],nil,nil,nil)
    @user = UseridDetail.where(:userid => @transcriber_id).first
    
    #this is a cludge as it seems that WinFreeReg cannot currently handle the replies
    
    @user.userid_feedback_replies = Hash.new
    logger.warn "FREEREG::COMPUTER for user #{@transcriber_id}   #{@transcriber_password }"
    if @user.nil? then
      render(:text => { "result" => "unknown_user" }.to_xml({:root => 'authentication'}))
    else
      if @transcriber_password == @user.password then
        render(:text => {"result" => "success", :userid_detail => @user}.to_xml({:dasherize => false, :root => 'authentication'}))
      else
        render(:text => { "result" => "no_match" }.to_xml({:root => 'authentication'}))
      end
    end
  end

  def refreshuser
    @transcriber_id = params[:transcriberid]
    @user = UseridDetail.where(:userid => @transcriber_id).first
    #this is a cludge as it seems that WinFreeReg cannot currently handle the replies
    
    @user.userid_feedback_replies = Hash.new
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
    #this is a cludge as it seems that WinFreeReg cannot currently handle the replies
    
    @user.userid_feedback_replies = Hash.new
    if @user.nil? then
      render(:text => { "result" => "unknown_user" }.to_xml({:root => 'authentication'}))
    else
      if @transcriber_password == @user.password then
        render(:text => {"result" => "success", :userid_detail => @user}.to_xml({:dasherize => false, :root => 'authentication'}))
      else
        render(:text => { "result" => "no_match" }.to_xml({:root => 'authentication'}))
      end
    end
  end

end
