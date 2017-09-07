class MessagesController < ApplicationController
  
  require 'freereg_options_constants'
  require 'userid_role'
  def index
    get_user_info_from_userid
    @messages = Message.all.order_by(message_time: -1)
  end


  def userid_messages
    get_user_info_from_userid
    @user.reload
    @messages = []
    @user.userid_messages.each do |msg_id|
      @messages << Message.id(msg_id).first
    end
  end

  def remove_from_useriddetail_waitlist
    get_user_info_from_userid
    @user.remove_checked_messages(params[:id])
    if @user.userid_messages.length > 0
      redirect_to userid_messages_path
    else
      redirect_to new_manage_resource_path
    end
  end

  def show_waitlist_msg
    get_user_info_from_userid
    @message = Message.id(params[:id]).first
    @user = cookies.signed[:userid]
    if @message.blank?
      go_back("message",params[:id])
    end
    @sent =   @message.sent_messages.order_by(sent_time: 1)
  end

  def show
    get_user_info_from_userid

    @message = Message.id(params[:id]).first
    if @message.blank?
      go_back("message",params[:id])
    end
    @sent =   @message.sent_messages.order_by(sent_time: 1)
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
    @message = Message.new(message_params)
    @message.file_name = @message.attachment_identifier
    if @message.save
      flash[:notice] = "Message created"
      redirect_to :action => 'index'
      return
    else
      render  :new
      return
    end
  end

  def send_message
    get_user_info_from_userid
    @message = Message.id(params[:id]).first
    if @message.present?
      @options = UseridRole::VALUES
      @sent_message = SentMessage.new(:message_id => @message.id, :sent_time => Time.now,:sender => @userid)
      @message.sent_messages <<  [ @sent_message ]
      @sent_message.save
      @sent_message.active = true
      @message.action =  @sent_message.id
      @inactive_reasons = Array.new
      UseridRole::REASONS_FOR_INACTIVATING.each_pair do |key,value|
        @inactive_reasons << value
      end
      @open_data_status = SentMessage::ALL_STATUS_MESSAGES
      @senders = Array.new
      @senders << ''
      UseridDetail.active(true).all.order_by(userid_lower_case: 1).each do |sender|
        @senders << sender.userid
      end
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
        @message.update_attributes(message_params)
      when "Send"
        sender = params[:sender]
        @sent_message = @message.sent_messages.id(params[:message][:action]).first
        reasons = Array.new
        #params[:inactive_reasons].blank?  ? reasons << 'temporary' : reasons =  params[:inactive_reasons]
        @sent_message.update_attributes(:recipients => params[:recipients], :active => params[:active], :inactive_reason => reasons, :sender => sender, open_data_status: params[:open_data_status])
        if @sent_message.recipients.nil? || @sent_message.open_data_status.nil?
          flash[:notice] = "Invalid Send: Please select Recipients and Open Data Status"
          redirect_to action:'send_message' and return
        else
         @message.communicate(params[:recipients],  params[:active], reasons,sender, params[:open_data_status])
         flash[:notice] = @message.reciever_notice(params)
        end
      end
      redirect_to :action => 'show'
      return
    else
      go_back("message",params[:id])
    end
  end

  def destroy
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
  private
  def message_params
    params.require(:message).permit!
  end
end
