class County 

  include Mongoid::Document
  include Mongoid::Timestamps::Created::Short
  include Mongoid::Timestamps::Updated::Short

  field :chapman_code, type: String
  field :county_coordinator, type: String
  field :previous_county_coordinator, type: String
  field :county_coordinator_lower_case,  type: String
  field :county_description, type: String
  field :county_notes, type: String

   before_save :add_lower_case_and_change_userid_fields
 
  index ({ chapman_code: 1, county_coordinator: 1 })
   index ({ county_coordinator: 1 })
   index ({ previous_county_coordinator: 1 })
    index ({ county_coordinator_lower_case: 1})
    index ({ chapman_code: 1, county_coordinator_lower_case: 1 })
     index ({ chapman_code: 1, previous_county_coordinator: 1 })

  
   protected 

  def  add_lower_case_and_change_userid_fields
   self.county_coordinator_lower_case = self.county_coordinator.downcase
   p 'before' 
   p self
  @old_userid = UseridDetail.where(:userid => self.previous_county_coordinator).first 
  @new_userid = UseridDetail.where(:userid => self.county_coordinator).first
  p 'before'
  p  @old_userid.person_role
  
  p @old_userid.county_groups
  p  @new_userid.person_role
  p @new_userid.county_groups
  unless @old_userid.nil?
     if @old_userid.county_groups.length == 1
       @old_userid.person_role = 'transcriber'  unless (@old_userid.person_role == 'syndicate_coordinator' || @old_userid.person_role == 'country_coordinator' || @old_userid.person_role == 'system_adminstrator' || @old_userid.person_role == 'volunteer_coordinator')
     end 

     @old_userid.county_groups.delete_if {|code| code == self.chapman_code}
  end
    if @new_userid.county_groups.length == 0 then
     @new_userid.person_role = 'county_coordinator' if (@new_userid.person_role == 'transcriber' || @new_userid.person_role == 'syndicate_coordinator' || @new_userid.person_role == 'researcher')
    end 
   @new_userid.county_groups << self.chapman_code
   @old_userid.save!  unless @old_userid.nil?
   @new_userid.save!
    p 'after'
  p   @old_userid.person_role
  
  p @old_userid.county_groups
  p @new_userid.person_role
  p @new_userid.county_groups
 end

end
