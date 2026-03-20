# frozen_string_literal: true

# Automatically trims leading and trailing whitespace from string fields
# on create and update. Include in any model that needs this behavior.
#
# Usage:
#   include StripStringFields
#
# Optionally exclude specific fields by overriding strip_string_fields_except:
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
      stripped = value.strip
      self[key] = stripped if value != stripped
    end
  end
end
