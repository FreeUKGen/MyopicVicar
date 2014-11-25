class Syndicate
  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

  field :syndicate_code, type: String
  field :previous_syndicate_code, type: String
  field :syndicate_coordinator, type: String
  field :syndicate_coordinator_lower_case, type: String
  field :previous_syndicate_coordinator, type: String
  field :syndicate_description, type: String
  field :syndicate_notes, type: String
  field :accepting_transcribers, type: Boolean, default: true
  field :changing_name, type: Boolean, default: false
  before_save :add_lower_case_and_change_userid_fields
  after_save :propagate_change_in_code
  validate :syndicate_code_does_not_exist_on_change, on: :update
  index ({ syndicate_code: 1, syndicate_coordinator: 1 })
  index ({ syndicate_coordinator: 1 })
  index ({ previous_syndicate_coordinator: 1 })

  def  add_lower_case_and_change_userid_fields
    self.syndicate_coordinator_lower_case = self.syndicate_coordinator.downcase

  end
  def update_fields_before_applying(parameters)
    unless self.syndicate_code ==  parameters[:syndicate_code]
     parameters[:changing_name] = true
     parameters[:previous_syndicate_code] = self.syndicate_code
     end
    previous_syndicate_coordinator = self.syndicate_coordinator
    parameters[:previous_syndicate_coordinator] = previous_syndicate_coordinator  unless self.syndicate_coordinator == parameters[:syndicate_coordinator]
    unless self.syndicate_coordinator == parameters[:syndicate_coordinator] #no change in coordinator
      #change coordinators and roles
       if UseridDetail.where(:userid => previous_syndicate_coordinator).exists? then #make sure that there is a previous coordinator to downgrade
         @old_userid = UseridDetail.where(:userid => previous_syndicate_coordinator).first 
         if @old_userid.syndicate_groups.length == 1 then
           @old_userid.person_role = 'transcriber'  unless (@old_userid.person_role == 'county_coordinator' || @old_userid.person_role == 'country_coordinator' || @old_userid.person_role == 'system_adminstrator' || 
                                                        @old_userid.person_role == 'volunteer_coordinator' || @old_userid.person_role == 'technical' || @old_userid.person_role == 'data_manager' )
          end #length
         @old_userid.syndicate_groups.delete_if {|code| code == self.syndicate_code}
         @old_userid.save(:validate => false)  unless @old_userid.nil?
       end #exists
       if UseridDetail.where(:userid => parameters[:syndicate_coordinator]).exists? then # make sure there is a new coordinator to upgrade
         @new_userid = UseridDetail.where(:userid => parameters[:syndicate_coordinator]).first 
         if   @new_userid.syndicate_groups.nil? || @new_userid.syndicate_groups.length == 0 then
            @new_userid.person_role = 'syndicate_coordinator' if (@new_userid.person_role == 'transcriber' || @new_userid.person_role == 'researcher')
            end #new role
         @new_userid.syndicate_groups = Array.new if  @new_userid.syndicate_groups.nil? || @new_userid.syndicate_groups.empty?
         @new_userid.syndicate_groups << self.syndicate_code
          @new_userid.syndicate_groups =  @new_userid.syndicate_groups.compact
          @new_userid.save(:validate => false)  unless @new_userid.nil?
        end #new exists
   end#change of coordinator
   parameters  
end
def propagate_change_in_code
  if self.changing_name
    UseridDetail.where(:syndicate => self.previous_syndicate_code).each do |user|
      user.update_attributes(:syndicate => self.syndicate_code)
    end
  end
end
def syndicate_code_does_not_exist_on_change
  errors.add(:syndicate_code, "Syndicate Already exits") if (Syndicate.where(:syndicate_code => self.syndicate_code).exists? && self.changing_name)
end

def self.get_syndicates_open_for_transcription
  @syndicates = Array.new
  syndicates = Syndicate.where(:accepting_transcribers.ne => false).all.order_by(syndicate_code: 1)
  syndicates.each do |syn|
   @syndicates << syn.syndicate_code
 end
 return @syndicates
end
def self.get_syndicates
 synd = Syndicate.all.order_by(syndicate_code: 1)
 @syndicates = Array.new
 synd.each do |syn|
  @syndicates << syn.syndicate_code
end 
return @syndicates
end

end
