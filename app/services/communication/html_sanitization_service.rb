# frozen_string_literal: true

module Communication
  class HtmlSanitizationService
    include ActionView::Helpers::SanitizeHelper

    # ---------------------------------------------------------------------------
    # Public API
    # ---------------------------------------------------------------------------
    def self.clean(html)
      new(html).clean
    end

    def initialize(html)
      @html = html.to_s
    end

    def clean
      sanitize(@html, tags: allowed_tags, attributes: allowed_attributes)
    end

    # ---------------------------------------------------------------------------
    # Internal configuration
    # ---------------------------------------------------------------------------
    private

    def allowed_tags
      %w[
        p br strong em b i u
        ul ol li
        table thead tbody tr th td
        span div
      ]
    end

    def allowed_attributes
      %w[
        style
        class
        colspan rowspan
      ]
    end
  end
end
