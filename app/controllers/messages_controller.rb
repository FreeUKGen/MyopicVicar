class MessagesController < ApplicationController

  require 'freereg_options_constants'
  require 'userid_role'
  require 'reply_userid_role'
  
  skip_before_filter :require_login, only: [:show]

  def create
    @message = Message.new(message_params)
    @message.file_name = @message.attachment_identifier
    case params[:commit]
    when "Submit"
      if @message.save
        flash[:notice] = "Message created"
        redirect_to :action => 'index'
        return
      else
        redirect_to  :new
        return
      end
    when "Save & Send"
      if @message.save
        flash[:notice] = "Reply created"
        params[:id] = @message.id if @message
        send_message
        redirect_to send_message_messages_path(@message.id) and return
      else
        redirect_to reply_messages_path(@message.source_message_id) and return
      end
    when "Reply Feedback"
      if @message.save
        reply_for_feedback; return if performed?
      end
    when "Reply Contact"
      if @message.save
        flash[:notice] = "Reply for Contact is created and sent"
        reply_for_contact; return if performed?
      end
    end
  end

  def destroy
    @message = Message.id(params[:id]).first
    if @message.present?
      @message.destroy
      flash.notice = "Message destroyed"
      redirect_to list_feedback_reply_message_path and return if @message.source_feedback_id.present?
      redirect_to list_contact_reply_message_path and return if @message.source_contact_id.present?
      redirect_to :action => 'index'
      return
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


  def index
    get_user_info_from_userid
    @links = true
    @messages = Message.non_feedback_contact_reply_messages.all.order_by(message_time: -1)
  end


  def list_by_name
    get_user_info_from_userid
    @messages = Message.list_messages(params[:action])
    render :index
  end

  def list_feedback_reply_message
    get_user_info_from_userid
    @messages = Message.list_messages(params[:action])
    render :index
  end

  def list_contact_reply_message
    get_user_info_from_userid
    @messages = Message.list_messages(params[:action])
    render :index
  end

  def list_by_identifier
    get_user_info_from_userid
    @messages = Message.list_messages(params[:action])
    render :index
  end

  def list_by_date
    get_user_info_from_userid
    @messages = Message.list_messages(params[:action])
    render :index
  end

  def list_unsent_messages
    get_user_info_from_userid
    @messages = Message.list_messages(params[:action])
    render :index
  end

  def new
    get_user_info_from_userid
    @message = Message.new
    @message.message_time = Time.now
    @message.userid = @user.userid
    @respond_to_message = Message.id(params[:id]).first
    @reply_messages = Message.fetch_replies(params[:id])
    @sent_replies = Message.sent_messages(@reply_messages)
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

  def reply_for_contact
    sender = UseridDetail.where(userid: @message.userid).first
    @contact = Contact.id(@message.source_contact_id).first
    if sender.present? && @contact.present?
      @contact.communicate_contact_reply(@message, sender.userid)
      redirect_to reply_contact_path(@message.source_contact_id) and return
    else
      #need to add error handling
    end
    redirect_to reply_contact_path(@message.source_contact_id)
  end

  def reply_for_feedback
    sender = UseridDetail.where(userid: @message.userid).first
    @feedback = Feedback.id(@message.source_feedback_id).first
    if sender.present? && @feedback.present?
      @feedback.communicate_feedback_reply(@message, sender.userid)
      redirect_to reply_feedback_path(@message.source_feedback_id) and return
    else
      #need to add error handling
    end
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

  def send_message
    get_user_info_from_userid
    @message = Message.id(params[:id]).first
    @syndicate = session[:syndicate]
    if @message.present?
      @options = UseridRole::VALUES
      @sent_message = SentMessage.new(:message_id => @message.id,:sender => @user_userid)
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

  def send_contact_message
    get_user_info_from_userid
    if @message.present?
      @sent_message = SentMessage.new(:message_id => @message.id,:sender => @user_userid, recipients: [params[:email]])
      @message.sent_messages <<  [ @sent_message ]
      @sent_message.save
    end
  end

  def show
    #get_user_info_from_userid
    @message = Message.id(params[:id]).first
    @reply_messages = Message.fetch_replies(params[:id])
    @sent_replies = Message.sent_messages(@reply_messages)
    if @message.blank?
      go_back("message",params[:id])
    end
    @sent =   @message.sent_messages.order_by(sent_time: 1)
  end

  def show_reply_messages
    get_user_info_from_userid
    @user_messages = UseridDetail.id(@user.id).first.userid_messages
    @reply_messages = Message.fetch_replies(params[:id])
    @messages = Message.sent_messages(@reply_messages)
    @main_message = Message.id(params[:id]).first
  end

  def show_waitlist_msg
    get_user_info_from_userid
    @message = Message.id(params[:id]).first
    @reply_messages = Message.fetch_replies(params[:id])
    @sent_replies = Message.sent_messages(@reply_messages)
    @user = get_user
    if @message.blank?
      go_back("message",params[:id])
    end
    @sent =   @message.sent_messages.order_by(sent_time: 1)
  end

  def user_reply_messages
    get_user_info_from_userid
    @main_message = Message.id(params[:id]).first
    @reply_messages = Message.fetch_replies(params[:id])
    @user_replies = @reply_messages.where(userid: @user.userid).all
    @messages = Message.sent_messages(@user_replies)
  end

  def userid_messages
    get_user_info_from_userid
    @user.reload
    @main_messages = Message.in(id: @user.userid_messages, source_message_id: nil).all.order_by(message_sent_time: -1)
    @messages = @main_messages
    if session[:syndicate].present?
      @syndicate_messages = @main_messages.reject do |msg|
        msg.sent_messages.syndicate_messages(session[:syndicate]).blank?
      end
      @messages = @syndicate_messages
    end
  end

  def userid_reply_messages
    get_user_info_from_userid
    @user.reload
    @reply_messages = Message.in(id: @user.userid_messages).where(:source_message_id.ne => nil).all.order_by(message_sent_time: -1)
    @messages = @reply_messages
    if session[:syndicate].present?
      @syndicate_reply_messages = @reply_messages.reject do |reply_msg|
        reply_msg.sent_messages.syndicate_messages(session[:syndicate]).blank?
      end
      @messages = @syndicate_reply_messages
    end
  end

  def update
    @message = Message.id(params[:id]).first
    if @message.present?
      case params[:commit]
      when "Submit"
        @message.update_attributes(message_params)
      when "Send"
        @respond_to_message = Message.id(@message.source_message_id).first
        if params[:recipients].nil?
          flash[:notice] = "You did not select any recipients"
          redirect_to :back and return
        else
          @syndicate = session[:syndicate] if params[:recipients].include?("Members of Syndicate")
          sender = params[:sender]
          @sent_message = @message.sent_messages.id(params[:message][:action]).first
          reasons = Array.new
          #params[:inactive_reasons].blank?  ? reasons << 'temporary' : reasons =  params[:inactive_reasons]
          @sent_message.update_attributes(:recipients => params[:recipients], :active => params[:active], :inactive_reason => reasons, :sender => sender, open_data_status: params[:open_data_status], syndicate: @syndicate)
          if @sent_message.recipients.nil? || @sent_message.open_data_status.nil?
            flash[:notice] = "Invalid Send: Please select Recipients and Open Data Status"
            redirect_to action:'send_message' and return
          else
            @message.communicate(params[:recipients],  params[:active], reasons,sender, params[:open_data_status], @syndicate)
            @sent_message.update_attributes(sent_time: Time.now)
            @message.update_attributes(message_sent_time: Time.now)
            flash[:notice] = @message.reciever_notice(params)
          end
        end
      end
      redirect_to :action => 'show'
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
