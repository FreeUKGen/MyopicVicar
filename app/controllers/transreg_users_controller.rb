class TransregUsersController < ApplicationController
  skip_before_filter :require_login, only: [:new]
  def new
    logger.warn "FREEREG::USER Entered transreg session #{session[:userid]} or @@userid #{@@userid}"
    if session[:userid].nil? && @@userid.nil?
      render(:text => { "result" => "failure", "message" => "You are not authorised to use these facilities"}.to_xml({:root => 'login'}))
      return
    end
    if @@userid.present?
      @user = UseridDetail.id(@@userid).first
    else
      @user = UseridDetail.where(:userid => session[:userid]).first
    end
    session[:userid] = @user.userid
    get_userid_from_current_authentication_devise_user
    @first_name = @user.person_forename
    render(:text => { "result" => "Logged in", :userid_detail => @user.attributes}.to_xml({:dasherize => false, :root => 'login'}))
  end

  def index
  end

  def refreshuser
    @transcriber_id = params[:transcriberid]
    @user = UseridDetail.where(:userid => @transcriber_id).first
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
    @transcriber_password = params[:transcriberpassword]

    if session[:userid].nil?
      render(:text => { "result" => "failure", "message" => "You are not authorised to use these facilities"}.to_xml({:root => 'authentication'}))
      return
    end

    @user = UseridDetail.where(:userid => @transcriber_id).first

    if @user.nil? then
      p "Unknown User"
      render(:text => { "result" => "unknown_user" }.to_xml({:root => 'authentication'}))
    else
      p "Known Transcriber"
      password = Devise::Encryptable::Encryptors::Freereg.digest(@transcriber_password,nil,nil,nil)
      if password == @user.password then
        p "Password matches"
        render(:text => {"result" => "success", :userid_detail => @user}.to_xml({:dasherize => false, :root => 'authentication'}))
      else
        p "No match on Password"
        render(:text => { "result" => "no_match" }.to_xml({:root => 'authentication'}))
      end
    end
  end

end
