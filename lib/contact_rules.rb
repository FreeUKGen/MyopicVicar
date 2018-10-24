class ContactRules
  attr_reader :user, :result_sets

  COUNTY_COUNTRY_COORDINATORS = [
    "county_coordinator", "country_coordinator"
  ]

  def initialize user
    @user = user
    @result_sets = []
  end

  def result(achived,sort_order)
    get_contacts_for_roles(achived,sort_order)
  end

  private

  # Get the user primary role => has one
  def primary_role
    return nil if user.person_role.blank?
    user.person_role
  end

  # Get the user secondary roles => array
  def secondary_roles
    user.secondary_role
  end

  # Merge the user primary and secondary roles and remove duplicates
  def merge_roles
    combined_roles = secondary_roles << primary_role
    combined_roles.uniq
  end

  # Get the contacts for each role
  def get_contacts_for_roles(achived,sort_order)
    return all_contacts(achived,sort_order) unless roles_in_contact_types?

    unless county_and_country_coordinators?
      return county_and_country_contacts(achived,sort_order)
    end

    return user_role_contacts(achived,sort_order)
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

  # All contacts
  def all_contacts(achived,sort_order)
    Contact.archived(achived).order_by(sort_order)
  end

   # Get county and country co-ordinator contacts
  def county_and_country_contacts(achived,sort_order)
    results = Contact.where(county: { '$in': county_groups }).archived(achived).all.order_by(sort_order)
    results
  end

  # Get contacts for the user roles
  def user_role_contacts(achived,sort_order)
    remaining_roles = []
    merge_roles = remove_county_or_country_roles

    merge_roles.each do |role|
      remaining_roles << contact_types[role]
    end

    remaining_roles = remaining_roles.flatten
    contacts = Contact.where(contact_type: { '$in': remaining_roles }).archived(achived).all.order_by(sort_order)
    contacts
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

  def county_groups
    user.county_groups
  end

end
