 #rules to list the contacts to user on the basis of their roles
class ContactRules
  attr_reader :user, :result_sets

  COUNTY_COUNTRY_COORDINATORS = [
    "county_coordinator", "country_coordinator"
  ]

  def initialize user
    @user = user
    @result_sets = []
  end

  def result(archived,sort_order)
    @contacts = Contact.archived(archived).order_by(sort_order)
    get_contacts_for_roles
  end

  private

  # Merge the user primary and secondary roles and remove duplicates
  def merge_roles
    user_roles = user.secondary_role << user.person_role
    user_roles.uniq
  end

  # Get the contacts for each role
  def get_contacts_for_roles
    roles_in_contact_types? ? user_role_contacts : @contacts
  end
  
  # Check user roles are not in contact types
  def roles_in_contact_types?
    (merge_roles - complete_contact_types.flatten).empty?
  end

  #Array of contact types
  def complete_contact_types
    contact_types.keys << COUNTY_COUNTRY_COORDINATORS
  end

  # remove role if county or country co ordinator
  def remove_county_or_country_roles
    merge_roles.reject { |role|
      COUNTY_COUNTRY_COORDINATORS.include? role
    }
  end

  # Get contacts for the user roles
  def user_role_contacts
    contacts = @contacts.or(
      { county: { '$in': county_contacts } },
      { contact_type: { '$in': remaining_contact_types.flatten } }
    )
    contacts.map{ |result| result }
  end

  def county_contacts
    county_and_country_coordinators? ? [nil] : county_groups
  end

  # Check the role has county or a country coordinator
  def county_and_country_coordinators?
    (merge_roles & COUNTY_COUNTRY_COORDINATORS).empty?
  end

  # Contacts by Roles
  def contact_types
    {
      "website_coordinator" => ["Website Problem", "Enhancement Suggestion"],
      "contacts_coordinator" => ["Data Question", "Data Problem"],
      "publicity_coordinator" => ["Thank you"],
      "genealogy_coordinator" => ["Genealogical Question"],
      "volunteer_coordinator" => ["Volunteering Question"],
      "general_communication_coordinator" => ["General Comment"]
    }
  end

  #user county groups
  def county_groups
    user.county_groups
  end

  # array of remaining contact types
  def remaining_contact_types
    remove_county_or_country_roles.map do |role|
      contact_types[role]
    end
  end
end
