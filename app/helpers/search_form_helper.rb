# Search Form Helper
# Provides helper methods for the search form to improve maintainability

module SearchFormHelper
  # Note: set_value, set_value_or_default, set_checkbox_checked_value, 
  # set_county_value, and set_district methods are already defined in SearchQueriesHelper


  # Generate form field attributes with security considerations
  def form_field_attributes(field_name, options = {})
    {
      class: 'text-input',
      id: field_name,
      maxlength: options[:maxlength] || 100,
      autocomplete: options[:autocomplete] || 'off',
      'aria-describedby' => "#{field_name}-help",
      tabindex: options[:tabindex] || '0'
    }.merge(options.except(:maxlength, :autocomplete, :tabindex))
  end

  # Generate safe select options
  def safe_select_options(options, selected_value = nil)
    return [] if options.blank?
    
    options.map do |option|
      if option.is_a?(Array)
        [sanitize(option[0]), option[1]]
      else
        [sanitize(option), option]
      end
    end
  end

  # Generate form validation rules
  def form_validation_rules
    {
      'search_query[first_name]' => {
        minlength: 2,
        maxlength: 100
      },
      'search_query[last_name]' => {
        minlength: 2,
        maxlength: 50
      },
      'search_query[start_year]' => {
        min: 1837,
        max: 1999,
        number: true
      },
      'search_query[end_year]' => {
        min: 1837,
        max: 1999,
        number: true
      }
    }
  end

  # Generate form validation messages
  def form_validation_messages
    {
      'search_query[first_name]' => {
        minlength: 'First name must be at least 2 characters',
        maxlength: 'First name must be no more than 100 characters'
      },
      'search_query[last_name]' => {
        minlength: 'Last name must be at least 2 characters',
        maxlength: 'Last name must be no more than 50 characters'
      },
      'search_query[start_year]' => {
        min: 'Start year must be 1837 or later',
        max: 'Start year must be 1999 or earlier',
        number: 'Start year must be a valid number'
      },
      'search_query[end_year]' => {
        min: 'End year must be 1837 or later',
        max: 'End year must be 1999 or earlier',
        number: 'End year must be a valid number'
      }
    }
  end

  # Generate safe error messages
  def safe_error_message(message)
    return '' if message.blank?
    sanitize(message.to_s)
  end

  # Generate form field help text
  def field_help_text(field_name, text)
    content_tag(:div, 
      content_tag(:small, text), 
      id: "#{field_name}-help", 
      class: 'help-text'
    )
  end

  # Generate accessible form labels
  def accessible_label(field_name, text, options = {})
    label_tag(field_name, text, {
      class: options[:class],
      id: options[:id],
      'aria-label' => options[:aria_label] || text
    })
  end

  # Generate form field containers
  def form_field_container(field_name, label_text, field_html, options = {})
    content_tag(:li, class: options[:container_class]) do
      content_tag(:div, class: 'labels push-half--bottom') do
        accessible_label(field_name, label_text, options[:label_options] || {})
      end +
      field_html +
      (options[:help_text] ? field_help_text(field_name, options[:help_text]) : '')
    end
  end

  # Generate safe JSON data for JavaScript
  def safe_json_data(data)
    return '{}' if data.blank?
    data.to_json.html_safe
  end

  # Generate form submission data
  def form_submission_data
    {
      chapman_codes: safe_json_data(@search_query&.chapman_codes),
      districts: safe_json_data(@search_query&.districts),
      wildcard_option: j(@search_query&.wildcard_option || '')
    }
  end
end
