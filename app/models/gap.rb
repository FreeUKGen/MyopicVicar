class Gap
  include Mongoid::Document
  field :file_id, type: String
  field :start_date, type: String
  field :end_date, type: String
  field :record_type, type: String
  validates_inclusion_of :record_type, in: RecordType::ALL_FREEREG_TYPES + ['All']
  field :reason, type: String
  field :note, type: String

  belongs_to :register, index: true
  index({ file_id: 1 }, name: 'file')

  class << self
    def id(id)
      where(_id: id)
    end

    def register(id)
      where(register_id: id)
    end

    def file(id)
      where(file_id: id)
    end

    def record_type(id)
      where(record_type: id)
    end
  end
end
