class MessagesController < ApplicationController
  require 'freereg_options_constants'
 require 'userid_role'
  def index
    get_user_info_from_userid   
    @messages = Message.all.order_by(message_time: -1)  
  end

  def show
    @message = Message.id(params[:id]).first
    if @message.blank?
      go_back("message",params[:id])
    end 
    @sent =   @message.sent_messages
  end

  def list_by_name
    get_user_info_from_userid
    @messages = Message.all.order_by(userid: 1)
    render :index
  end

  def list_by_identifier
    get_user_info_from_userid
    @messages = Message.all.order_by(identifier: -1)
    render :index
  end


  def list_by_date
    get_user_info_from_userid
    @messages = Message.all.order_by(message_time: 1)
    render :index
  end

  def select_by_identifier
    get_user_info_from_userid
    @options = Hash.new
    @messages = Message.all.order_by(identifier: -1).each do |message|
      @options[message.identifier] = message.id
    end
    @message = Message.new
    @location = 'location.href= "/messages/" + this.value'
    @prompt = 'Select Identifier'
    render '_form_for_selection'
  end

  def new
    get_user_info_from_userid
    @message = Message.new
    @message.message_time = Time.now
    @message.userid = @user.userid
   
  end

  def create
    @message = Message.new(params[:message])
    @message.file_name = @message.attachment_identifier
    if @message.save
      p @message 
      flash[:notice] = "Message created"    
      redirect_to :action => 'index'
      return  
    else
      redirect_to  :new
      return
    end
  end

  def send_message
    @message = Message.id(params[:id]).first
    if @message.present?
      @options = UseridRole::VALUES
      @sent_message = SentMessage.new(:message_id => @message.id, :sent_time => Time.now)
      @message.sent_messages <<  [ @sent_message ]
      @sent_message.save
      @message.action =  @sent_message.id
    else
      go_back("message",params[:id])
    end 
   
  end

  def edit
    @message = Message.id(params[:id]).first
    if @message.blank? 
      go_back("message",params[:id])
    end   
  end
  
  def update
    @message = Message.id(params[:id]).first
    if @message.present?
     case params[:commit]
       when "Submit"
          @message.update_attributes(params[:message])
       when "Send"
         @sent_message = @message.sent_messages.id(params[:message][:action]).first
         @sent_message.update_attributes(:recipients => params[:recipients], :active => params[:message][:sent_message][:active])
         @message.communicate(params[:recipients],  params[:message][:sent_message][:active])
         flash[:notice] = "Message sent to #{params[:recipients]} #{ params[:message][:sent_message][:active]}"
      end
      redirect_to :action => 'show'
      return
    else
      go_back("message",params[:id])
    end  
  end

  def delete
   @message = Message.id(params[:id]).first
    if @message.present? 
      @message.destroy
      flash.notice = "Message destroyed"
      redirect_to :action => 'index'
      return
    else
      go_back("message",params[:id])
    end      
  end
end
