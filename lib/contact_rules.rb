class ContactRules
  attr_reader :user

  def initialize user
    @user = user
  end

  def secondary_role?
    user.secondary_role.any?
  end

  def primary_role?
    user.person_role
  end

  def primary_contacts
    contacts[]
  end

  def process_secondary_role_contacts
    secondary_contacts = []   
    return secondary_contacts unless secondary_role?

    user.secondary_role.each do |role|
      secondary_contacts << contacts[role]
    end
  end

  def result
    if contacts.has_key?(user_role)
      process_secondary_role_contacts
      contact_results = Contact.where(contact_field => { '$in': contacts[user_role]}).all.order_by(contact_time: -1)

    else
      contact_results = Contact.all.order_by(contact_time: -1)
    end

    contact_results
  end

  def contacts
    {
    "website_coordinator" => ["Website Problem", "Enhancement Suggestion"],
    "contacts_coordinator" => ["Data Question", "Data Problem"],
    "publicity_coordinator" => ["Thank you"],
    "genealogy_coordinator" => ["Genealogical Question"],
    "volunteer_coordinator" => ["Volunteering Question"],
    "general_communication_coordinator" => ["General Comment"],
    "county_coordinator" => county_contacts,
    "country_coordinator" => county_contacts
    }
  end

  def county_contacts
    user.county_groups
  end

  def contact_field
    if user_role == "county_coordinator" || user_role == "country_coordinator"
      "county"
    else
      "contact_type"
    end
  end

  def user_role
    @user.person_role
  end

  private

  def county_coordinator?
    #user.person_role == "county_coordinator" || check_secondary_role? "county_coordinator"
  end

  def check_secondary_role? role
    user.secondary_role.include? role
  end
end