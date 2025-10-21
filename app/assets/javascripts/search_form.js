// Search Form JavaScript
// Extracted from _form_freebmd.html.erb for better maintainability

class SearchForm {
  constructor() {
    this.form = $('#new_search_query');
    this.autocompleteInitialized = false;
    this.initializeEventHandlers();
    this.initializeFormState();
    this.initializeAutocomplete();
  }

  initializeEventHandlers() {
    // Checkbox handlers
    $('.checkAll').on('change', this.handleCheckAll.bind(this));
    $('.checkboxtag').on('change', this.handleCheckboxChange.bind(this));
    
    // Form submission
    $('#search_form_submit, #search_form_submit_mobile').on('click', this.handleFormSubmit.bind(this));
    
    // Clear form
    $('.clear_forms').on('click', this.handleClearForm.bind(this));
    
    // Year synchronization
    $('#from_year').on('change', this.syncYearFields.bind(this));
    
    // Record type changes
    $('.checkboxtag, .checkAll').on('change', this.handleRecordTypeChange.bind(this));
    
    // Death age selection
    $('#death_select_box').on('change', this.handleDeathAgeChange.bind(this));
    
    // County changes
    $('#search_query_chapman_codes').on('change', this.handleCountyChange.bind(this));
    
    // District changes
    $('#search_query_districts').on('change', this.handleDistrictChange.bind(this));
    
    // Wildcard field changes
    $('#wildcard_field').on('change', this.handleWildcardChange.bind(this));
    
    // Exact match and fuzzy search
    $('#search_query_first_name_exact_match, #search_query_fuzzy').on('change', this.handleSearchOptionsChange.bind(this));
  }

  initializeAutocomplete() {
    // Check if jQuery UI is loaded
    if (typeof $.ui === 'undefined' || !$.ui.autocomplete) {
      console.warn('jQuery UI Autocomplete not loaded, retrying in 100ms...');
      setTimeout(() => this.initializeAutocomplete(), 100);
      return;
    }

    // Check if form elements exist
    if ($('#first_name').length === 0) {
      console.warn('Form elements not found, retrying in 100ms...');
      setTimeout(() => this.initializeAutocomplete(), 100);
      return;
    }

    if (this.autocompleteInitialized) {
      console.log('Autocomplete already initialized, skipping...');
      return;
    }

    console.log('Initializing autocomplete...');

    try {
      // First name autocomplete
      $('#first_name').autocomplete({
        source: (request, response) => {
          $.ajax({
            url: '/unique_forenames/',
            dataType: 'json',
            data: { term: request.term },
            success: (data) => {
              console.log('First name autocomplete response:', data);
              response(data || []);
            },
            error: (xhr, status, error) => {
              console.error('First name autocomplete error:', error, xhr.responseText);
              response([]);
            }
          });
        },
        minLength: 2,
        delay: 300,
        focus: () => false,
        select: (event, ui) => {
          event.target.value = ui.item.value;
          return false;
        }
      });

      // Last name autocomplete
      $('#last_name').autocomplete({
        source: (request, response) => {
          $.ajax({
            url: '/unique_surnames/',
            dataType: 'json',
            data: { term: request.term },
            success: (data) => {
              console.log('Last name autocomplete response:', data);
              response(data || []);
            },
            error: (xhr, status, error) => {
              console.error('Last name autocomplete error:', error, xhr.responseText);
              response([]);
            }
          });
        },
        minLength: 2,
        delay: 300,
        focus: () => false,
        select: (event, ui) => {
          event.target.value = ui.item.value;
          return false;
        }
      });

      // Counties autocomplete
      $('#search_query_chapman_codes').autocomplete({
        source: (request, response) => {
          $.ajax({
            url: '/search_queries/select_counties/',
            dataType: 'json',
            data: { prefix: request.term },
            success: (data) => {
              response(data || []);
            },
            error: (xhr, status, error) => {
              console.error('County autocomplete error:', error);
              response([]);
            }
          });
        },
        minLength: 1,
        delay: 300,
        focus: () => false,
        select: (event, ui) => {
          const terms = this.splitValue(event.target.value);
          terms.pop();
          terms.push(ui.item.value);
          terms.push('');
          event.target.value = terms.join(', ');
          return false;
        }
      });

      // Districts autocomplete
      $('#search_query_districts').autocomplete({
        source: (request, response) => {
          $.ajax({
            url: '/search_queries/districts_of_selected_counties/',
            dataType: 'json',
            data: {
              selected_counties: $('#search_query_chapman_codes').val(),
              term: request.term
            },
            success: (data) => {
              const transformedData = (data || []).map(item => ({
                label: item[0],
                value: item[0],
                id: item[1]
              }));
              response(transformedData);
            },
            error: (xhr, status, error) => {
              console.error('District autocomplete error:', error);
              response([]);
            }
          });
        },
        minLength: 1,
        delay: 300,
        focus: () => false,
        select: (event, ui) => {
          const terms = this.splitValue(event.target.value);
          terms.pop();
          terms.push(ui.item.value);
          terms.push('');
          event.target.value = terms.join(', ');
          
          // Store display names
          let displayNames = event.target.getAttribute('data-display-names') || '';
          displayNames = displayNames ? displayNames.split(',') : [];
          displayNames.push(ui.item.label);
          event.target.setAttribute('data-display-names', displayNames.join(','));
          
          return false;
        }
      });

      this.autocompleteInitialized = true;
      console.log('Autocomplete initialized successfully');
    } catch (error) {
      console.error('Error initializing autocomplete:', error);
    }
  }

  initializeFormState() {
    // Initialize death age options
    this.hideAllDeathOptions();
    this.updateDeathAgeDisplay();
    
    // Initialize record type state
    this.updateRecordTypeState();
    
    // Load existing county/district data
    this.loadExistingData();
  }

  handleCheckAll(e) {
    const $inputs = $('.checkboxtag');
    if (e.originalEvent === undefined) {
      const allChecked = $inputs.toArray().every(input => input.checked);
      this.checked = allChecked;
    } else {
      $inputs.prop('checked', this.checked);
    }
  }

  handleCheckboxChange() {
    $('.checkAll').trigger('change');
  }

  handleFormSubmit(e) {
    e.preventDefault();
    
    const l = Ladda.create(document.querySelector('.ladda-button'));
    l.stop();
    
    if (this.form.valid()) {
      l.start();
      this.form.submit();
    }
  }

  handleClearForm() {
    // Reset form using native reset method
    this.form[0].reset();
    
    // Clear all inputs
    this.form.find('input[type="text"], input[type="number"]').val('');
    this.form.find('select').val('');
    this.form.find('input[type="checkbox"]').prop('checked', false);
    
    // Reset specific fields to defaults
    $('#from_year').val('1837');
    $('#to_year').val('1999');
    $('#from_quarter').val('1');
    $('#to_quarter').val('4');
    
    // Clear districts
    $('#search_query_districts').empty();
    
    // Reset form state
    this.hideAllDeathOptions();
    $('#death_select_box').val([]).prop('disabled', 'disabled');
    
    // Hide conditional fields
    $('#spouse_firstnames_div, #spouse_or_mother_surname_div, #age_at_death_or_date_of_birth_div').hide();
    $('#spouse_first_name, #spouses_mother_surname').val('');
    
    // Reset labels
    $('.spouse_or_mother_surname_label').text("Spouse/Mothers surname");
    
    // Show advanced search
    $('#advanced_search').show();
    
    // Clear validation errors
    this.form.find('.error').removeClass('error');
    this.form.find('.validation-list').hide();
    
    // Reset autocomplete fields
    $('#first_name, #last_name, #search_query_chapman_codes').val('');
    
    // Trigger change events
    $('.checkboxtag, .checkAll').trigger('change');
  }

  syncYearFields() {
    const year = $('#from_year').val();
    $('#to_year').val(year).attr('min', year);
  }

  handleRecordTypeChange() {
    this.hideAllDeathOptions();
    $('#spouses_mother_surname, #spouse_first_name').removeAttr('value').prop('name', '');
    
    const birthChecked = $('.birth').is(':checked');
    const marriageChecked = $('.marriage').is(':checked');
    const deathChecked = $('.death').is(':checked');
    const allChecked = $('.checkAll').is(':checked');
    
    if (birthChecked && !deathChecked && !marriageChecked && !allChecked) {
      this.showBirthFields();
    } else if (marriageChecked && !birthChecked && !deathChecked && !allChecked) {
      this.showMarriageFields();
    } else if (deathChecked && !birthChecked && !marriageChecked && !allChecked) {
      this.showDeathFields();
    } else {
      this.hideAllConditionalFields();
    }
  }

  handleDeathAgeChange() {
    this.hideAllDeathOptions();
    this.updateDeathAgeDisplay();
  }

  handleCountyChange() {
    const counties = $('#search_query_chapman_codes').val();
    this.loadDistrictsForCounties(counties);
  }

  handleDistrictChange() {
    // Handle district-specific logic if needed
  }

  handleWildcardChange() {
    const field = $('#wildcard_field').val();
    if (field) {
      this.loadWildcardOptions(field);
    } else {
      $('#wildcard_options_dropdown').find('option').remove().end().append('<option value="">None</option>');
    }
  }

  handleSearchOptionsChange() {
    const exactMatch = $('#search_query_first_name_exact_match').is(':checked');
    const fuzzy = $('#search_query_fuzzy').is(':checked');
    
    if (exactMatch || fuzzy) {
      $('#advanced_search').hide();
      $('#wildcard_field, #wildcard_options_dropdown').val('');
    } else {
      $('#advanced_search').show();
    }
  }

  showBirthFields() {
    $('#spouses_mother_surname')
      .prop('disabled', false)
      .prop('name', 'search_query[mother_last_name]');
    $('.spouse_or_mother_surname_label')
      .attr('tabindex', '0')
      .text("Mother's Maiden Name");
    $('#death_select_box').prop('disabled', 'disabled').val([]);
    this.updateDeathAgeDisplay();
    $('#spouse_or_mother_surname_div').show();
    $('#age_at_death_or_date_of_birth_div').hide();
  }

  showMarriageFields() {
    $('#spouse_or_mother_surname_div, #spouse_firstnames_div').show();
    $('#spouse_first_name').prop('disabled', false);
    $('#spouses_mother_surname')
      .prop('disabled', false)
      .prop('name', 'search_query[spouses_mother_surname]');
    $('.spouse_or_mother_surname_label').text("Spouse's Surname");
    $('#death_select_box').prop('disabled', 'disabled').val([]);
    this.updateDeathAgeDisplay();
    $('#age_at_death_or_date_of_birth_div').hide();
  }

  showDeathFields() {
    $('#age_at_death_or_date_of_birth_div').show();
    $('#death_select_box').prop('disabled', false);
    this.updateDeathAgeDisplay();
  }

  hideAllConditionalFields() {
    $('#spouse_firstnames_div, #spouse_or_mother_surname_div, #age_at_death_or_date_of_birth_div').hide();
    $('#spouse_first_name').val('');
    $('#spouses_mother_surname').val('');
    $('#death_select_box').prop('disabled', 'disabled').val([]);
    this.updateDeathAgeDisplay();
  }

  hideAllDeathOptions() {
    $('#death_age_and_dob').css('display', 'block');
    $('#search_query_age_at_death, #search_query_min_age_at_death, #search_query_max_age_at_death, #search_query_dob_at_death, #search_query_min_dob_at_death, #search_query_max_dob_at_death').hide();
  }

  updateDeathAgeDisplay() {
    const value = $('#death_select_box').val();
    this.hideAllDeathOptions();
    
    switch (value) {
      case '1':
        $('#search_query_age_at_death').show();
        this.clearDeathFields(['min_age_at_death', 'max_age_at_death', 'dob_at_death', 'min_dob_at_death', 'max_dob_at_death']);
        break;
      case '2':
        $('#search_query_min_age_at_death, #search_query_max_age_at_death').show();
        this.clearDeathFields(['age_at_death', 'dob_at_death', 'min_dob_at_death', 'max_dob_at_death']);
        break;
      case '3':
        $('#search_query_dob_at_death').show();
        this.clearDeathFields(['age_at_death', 'min_age_at_death', 'max_age_at_death', 'min_dob_at_death', 'max_dob_at_death']);
        break;
      case '4':
        $('#search_query_min_dob_at_death, #search_query_max_dob_at_death').show();
        this.clearDeathFields(['age_at_death', 'min_age_at_death', 'max_age_at_death', 'dob_at_death']);
        break;
      default:
        this.clearDeathFields(['age_at_death', 'min_age_at_death', 'max_age_at_death', 'dob_at_death', 'min_dob_at_death', 'max_dob_at_death']);
    }
  }

  clearDeathFields(fields) {
    fields.forEach(field => {
      $(`#search_query_${field}`).val('');
    });
  }

  loadDistrictsForCounties(counties) {
    $.ajax({
      url: '/search_queries/districts_of_selected_counties',
      type: 'GET',
      data: { selected_counties: counties },
      error: (xhr, status, error) => {
        console.error('Error loading districts:', error);
      }
    });
  }

  loadWildcardOptions(field) {
    $.ajax({
      url: '/search_queries/wildcard_options_dropdown',
      type: 'GET',
      data: { field: field },
      error: (xhr, status, error) => {
        console.error('Error loading wildcard options:', error);
      }
    });
  }

  loadExistingData() {
    const chapmanCodes = window.searchQueryData?.chapman_codes;
    if (chapmanCodes && chapmanCodes.length > 0) {
      this.loadDistrictsForCounties(chapmanCodes);
    } else {
      this.loadDistrictsForCounties('all');
    }
  }

  splitValue(val) {
    return val.split(/,\s*/);
  }

  // Manual method to reinitialize autocomplete if needed
  reinitializeAutocomplete() {
    this.autocompleteInitialized = false;
    this.initializeAutocomplete();
  }
}

// Global function to manually initialize autocomplete if needed
window.initializeSearchFormAutocomplete = function() {
  if (window.searchFormInstance) {
    window.searchFormInstance.reinitializeAutocomplete();
  }
};

// Initialize form when document is ready
$(document).ready(function() {
  // Wait for jQuery UI to be loaded
  function waitForJQueryUI(callback) {
    if (typeof $.ui !== 'undefined' && $.ui.autocomplete) {
      callback();
    } else {
      setTimeout(() => waitForJQueryUI(callback), 50);
    }
  }

  // Initialize form validation
  $('#new_search_query').validate({
    rules: {
      'search_query[first_name]': {
        minlength: 2
      },
      'search_query[last_name]': {
        minlength: 2
      },
      'search_query[start_year]': {
        min: 1837,
        max: 1999
      },
      'search_query[end_year]': {
        min: 1837,
        max: 1999
      }
    },
    messages: {
      'search_query[first_name]': {
        minlength: 'First name must be at least 2 characters'
      },
      'search_query[last_name]': {
        minlength: 'Last name must be at least 2 characters'
      },
      'search_query[start_year]': {
        min: 'Start year must be 1837 or later',
        max: 'Start year must be 1999 or earlier'
      },
      'search_query[end_year]': {
        min: 'End year must be 1837 or later',
        max: 'End year must be 1999 or earlier'
      }
    },
    errorClass: 'error',
    validClass: 'valid',
    errorElement: 'span'
  });

  // Wait for jQuery UI and then initialize search form
  waitForJQueryUI(() => {
    console.log('jQuery UI loaded, initializing SearchForm...');
    window.searchFormInstance = new SearchForm();
  });
});
