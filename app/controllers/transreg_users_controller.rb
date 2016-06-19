class TransregUsersController < ApplicationController

  def new
  	if session[:userid].nil?
      render(:text => { "result" => "failure", "message" => "You are not authorised to use these facilities"}.to_xml({:root => 'login'}))
      return
  	end

  	@first_name = session[:first_name]
  	@user = UseridDetail.where(:userid => session[:userid]).first
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
