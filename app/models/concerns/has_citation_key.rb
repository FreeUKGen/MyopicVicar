# frozen_string_literal: true

module HasCitationKey
  extend ActiveSupport::Concern

  included do
    field :citation_key, type: String
    index({ citation_key: 1 }, { unique: true, sparse: true })
    before_validation :assign_citation_key_if_blank
  end

  class_methods do
    def generate_unique_citation_key
      loop do
        key = "#{citation_key_prefix}#{SecureRandom.alphanumeric(10)}"
        return key unless where(citation_key: key).exists?
      end
    end
  end

  def ensure_citation_key!
    assign_citation_key_if_blank
  end

  private

  def assign_citation_key_if_blank
    return if citation_key.present?

    self.citation_key = self.class.generate_unique_citation_key
  end
end
