module MasterOnlyRedirect
  extend ActiveSupport::Concern

  included do
    class_attribute :master_only_actions, default: []
  end

  class_methods do
    def redirect_to_master_only(*actions)
      self.master_only_actions = actions.map(&:to_s)
    end
  end

  def redirect_to_master_unless_master
    return if master?
    return if master_url.blank?

    # Preserve full path and query; use 307 so POST is replayed on master
    url = "#{master_redirect_base_url}#{request.fullpath}"
    redirect_to url, status: :temporary_redirect, allow_other_host: true
  end

  # Redirects to master when Postems are only stored there. Replicas MUST have
  # freebmd_master_url set; otherwise master? is true and no redirect occurs.
  def redirect_to_master_for_postem_display_if_not_master
    return if master?
    return if master_url.blank?

    redirect_to "#{master_redirect_base_url}#{request.fullpath}", allow_other_host: true
  end


  def master_redirect_base_url
    @master_redirect_base_url ||= begin
      uri = URI.parse(master_url)
      uri.user = nil
      uri.password = nil
      uri.to_s.chomp('@').chomp('/')
    end
  rescue URI::InvalidURIError
    master_url.to_s.chomp('/')
  end

  # Returns true if the record has Postems (via record_flag & POSTEM). Use when deciding whether to redirect to master.
  def record_has_postems?(record)
    return false unless record
    return false unless record.respond_to?(:record_flag)
    record_flag = record.record_flag
    return false unless record_flag.respond_to?(:nonzero?)
    (record_flag & ::Constant::POSTEM).nonzero?
  end

  def master?
    master_flag = Rails.application.config.respond_to?(:master) ? Rails.application.config.master : ENV['MASTER']
    return true if master_flag.present? && master_flag.to_s == '1'
    return true if master_url.blank? # no config => single server

    my_host = request.host
    master_host = URI.parse(master_url).host rescue nil
    return true if master_host.blank?

    my_host == master_host
  end

  def master_url
    @master_url ||= (
      Rails.application.config.respond_to?(:freebmd_master_url) ? Rails.application.config.freebmd_master_url : nil
    ).presence || ENV['FREEBMD_MASTER_URL'].presence
  end
end
