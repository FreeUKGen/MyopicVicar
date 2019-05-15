class FreecenUtility #collection can be used to store FreeCEN estra utilies
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  field :description, type: String
  field :value, default: nil
  CURRENT_TIME = Time.now
  FC_UPDATE_DESC = 'Database updated on'
  
  scope :freecen_update_document, -> { where(description: FC_UPDATE_DESC) }

  class << self
    def document_db_update
      get_freecen_update_doc.update(value: CURRENT_TIME)
    end

    def display_date_and_time
      return nil if freecen_update_document.blank?
      formatted_date_and_time
    end

    private

    def formatted_date_and_time
     get_update_date.to_formatted_s(:long_ordinal)
    end

    def get_update_date
      freecen_update_document.first.value
    end

    def get_freecen_update_doc
      freecen_update_document.first_or_create
    end
  end
end
