# frozen_string_literal: true

# Normalizes string fields before validation: trims ends and collapses
# internal runs of whitespace to a single space. Include in any model that
# needs this behavior.
#
# Usage:
#   include StripStringFields
#
# Optionally exclude specific fields by overriding strip_string_fields_except
# (those attributes are left unchanged — e.g. free-text notes):
#   include StripStringFields
#   def self.strip_string_fields_except
#     [:password, :raw_notes]
#   end
module StripStringFields
  extend ActiveSupport::Concern

  included do
    before_validation :strip_string_fields
  end

  def strip_string_fields
    attrs = respond_to?(:attributes) ? attributes : {}
    excluded = self.class.respond_to?(:strip_string_fields_except) ? self.class.strip_string_fields_except : []
    attrs.except(*excluded.map(&:to_s)).each do |key, value|
      next unless value.is_a?(String)
      normalized = value.strip.gsub(/\s+/, ' ')
      self[key] = normalized if value != normalized
    end
  end
end
