class UserActivity
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

    # Activity types
  module ActivityType
    LOGIN = 'login'
    LOGOUT = 'logout'
    SEARCH = 'search'
    VIEW = 'view'
    CREATE = 'create'
    UPDATE = 'update'
    DELETE = 'delete'
    DOWNLOAD = 'download'
    UPLOAD = 'upload'
    NAVIGATE = 'navigate'
    ERROR = 'error'
    OTHER = 'other'

    ALL_TYPES = [
      LOGIN, LOGOUT, SEARCH, VIEW, CREATE, UPDATE, DELETE, 
      DOWNLOAD, UPLOAD, NAVIGATE, ERROR, OTHER
    ].freeze
  end

  # Fields
  field :user_id, type: String
  field :userid, type: String
  field :activity_type, type: String
  field :action, type: String
  field :controller, type: String
  field :resource_type, type: String
  field :resource_id, type: String
  field :description, type: String
  field :ip_address, type: String
  field :user_agent, type: String
  field :referrer, type: String
  field :session_id, type: String
  field :params, type: Hash, default: {}
  field :metadata, type: Hash, default: {}
  field :success, type: Boolean, default: true
  field :error_message, type: String

  index({ user_id: 1, c_at: -1 })
  index({ userid: 1, c_at: -1 })
  index({ activity_type: 1, c_at: -1 })
  index({ controller: 1, action: 1, c_at: -1 })
  index({ c_at: -1 })
  validates_presence_of :user_id, :activity_type, :action
  validates_inclusion_of :activity_type, in: ActivityType::ALL_TYPES
  belongs_to :user, class_name: 'UseridDetail', foreign_key: 'user_id', optional: true

  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :by_type, ->(type) { where(activity_type: type) }
  scope :recent, ->(limit = 50) { order_by(c_at: -1).limit(limit) }
  scope :today, -> { where(c_at: Date.current.beginning_of_day..Date.current.end_of_day) }
  scope :this_week, -> { where(c_at: 1.week.ago..Time.current) }
  scope :this_month, -> { where(c_at: 1.month.ago..Time.current) }
  scope :successful, -> { where(success: true) }
  scope :failed, -> { where(success: false) }

  # Class methods
  def self.log_activity(user, activity_type, action, options = {})
    return unless user.present?

    activity = new(
      user_id: user.id.to_s,
      userid: user.userid,
      activity_type: activity_type,
      action: action,
      controller: options[:controller],
      resource_type: options[:resource_type],
      resource_id: options[:resource_id],
      description: options[:description],
      ip_address: options[:ip_address],
      user_agent: options[:user_agent],
      referrer: options[:referrer],
      session_id: options[:session_id],
      params: options[:params] || {},
      metadata: options[:metadata] || {},
      success: options[:success] != false,
      error_message: options[:error_message]
    )

    activity.save
    activity
  end

  def self.log_controller_action(user, controller, action, request, options = {})
    activity_type = action
    
    log_activity(
      user,
      activity_type,
      action,
      {
        controller: controller,
        resource_type: options[:resource_type],
        resource_id: options[:resource_id],
        description: options[:description] || "User #{user.userid} performed #{action} on #{controller}",
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        session_id: request.session.id,
        referrer: request.referer,
        params: request.params,
        metadata: options[:metadata] || {}
      }
    )
  end

  private

  
end