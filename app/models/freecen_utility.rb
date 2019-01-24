class FreecenUtility
  include Mongoid::Document
  include Mongoid::Timestamps::Short
  field :db_updated_at, type: DateTime, default: nil
  field :description, type: String
  CURRENT_TIME = Time.now
  FC_UPDATE_DESC = 'Database updated on'
  
  scope :freecen_update_document, -> { where(description: FC_UPDATE_DESC) }

  class << self
    def document_db_update
      freecen_update_document.first_or_create.update(db_updated_at: CURRENT_TIME)
    end

    def display_date_and_time
      return nil if freecen_update_document.blank?

      formatted_date_and_time
    end

    private

    def formatted_date_and_time
      database_updated_at = freecen_update_document.first.db_updated_at
      database_updated_at.to_formatted_s(:long_ordinal)
    end
  end
end
