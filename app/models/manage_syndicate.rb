class ManageSyndicate
  include Mongoid::Document
  field :syndicate, type: String
  field :action, type: Array
  field :userid, type: String
  field :email_address, type: String

  class << self

    def get_not_processed_files_for_syndicate(syndicate)
      userids = Syndicate.get_userids_for_syndicate(syndicate)
      batches = PhysicalFile.in(userid: userids).uploaded_into_base.not_processed.all.order_by("userid ASC, base_uploaded_date DESC")
      batches
    end

    def get_waiting_files_for_syndicate(syndicate)
      userids = Syndicate.get_userids_for_syndicate(syndicate)
      batches = PhysicalFile.in(userid: userids).waiting.all.order_by("userid ASC, waiting_date DESC")
      batches
    end
  end
end
