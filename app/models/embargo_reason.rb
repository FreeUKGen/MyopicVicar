# A collection of Annotations makes up a Transcription
class EmbargoRule
  include Mongoid::Document
  include Mongoid::Timestamps

  field :reason, type: String
  index({ reason: 1 })

end
