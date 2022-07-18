module SharedSearchMethods
  extend ActiveSupport::Concern

  BMD_INDEXES_HINT = {
    'PRIMARY' => ['RecordNumber'],
    'SURNAME' => ['Surname', 'GivenName', 'QuarterNumber'],
  }

  CEN_CHAPMAN_INDEXES = {
    'county_ln_rt_sd' => ['chapman_code', 'search_names.last_name', 'record_type', 'search_date'],
    'county_ln_fn_rt_sd' => ['chapman_code', 'search_names.last_name', 'search_names.first_name', 'record_type', 'search_date'],
    'county_lnsdx_rt_sd' => ['chapman_code', 'search_soundex.last_name', 'record_type', 'search_date'],
    'county_lnsdx_fnsdx_rt_sd' => ['chapman_code', 'search_soundex.last_name', 'search_soundex.first_name', 'record_type', 'search_date'],
    'birth_chapman_code_names_date' => ['birth_chapman_code', 'search_names.last_name', 'search_names.first_name', 'record_type', 'search_date'],
    'birth_chapman_code_last_name_date' => ['birth_chapman_code', 'search_names.last_name', 'record_type', 'search_date'],
    'birth_chapman_code_soundex_names_date' => ['birth_chapman_code', 'search_soundex.last_name', 'search_soundex.first_name', 'record_type', 'search_date'],
    'birth_chapman_code_soundex_last_name_date' => ['birth_chapman_code', 'search_soundex.last_name', 'record_type', 'search_date']
  }.freeze
  CEN_PLACE_INDEXES = {
    'place_ln_rt_sd' => ['place_id', 'search_names.last_name', 'record_type', 'search_date'],
    'place_ln_fn_rt_sd' => ['place_id', 'search_names.last_name', 'search_names.first_name', 'record_type', 'search_date'],
    'place_lnsdx_rt_sd' => ['place_id', 'search_soundex.last_name', 'record_type', 'search_date'],
    'place_lnsdx_fnsdx_rt_sd' => ['place_id', 'search_soundex.last_name', 'search_soundex.first_name', 'record_type', 'search_date'],
    'place_fn_rt_sd' => ['place_id', 'search_names.first_name', 'record_type', 'search_date'],
    'place_fnsdx_rt_sd' => ['place_id', 'search_soundex.first_name', 'record_type', 'search_date'],
    'place_rt_sd' => ['place_id', 'record_type', 'search_date']
  }.freeze

  CEN2_PLACE_INDEXES = {
    'place2_ln_rt_sd' => ['freecen2_place_id', 'search_names.last_name', 'record_type', 'search_date'],
    'place2_ln_fn_rt_sd' => ['freecen2_place_id', 'search_names.last_name', 'search_names.first_name', 'record_type', 'search_date'],
    'place2_lnsdx_rt_sd' => ['freecen2_place_id', 'search_soundex.last_name', 'record_type', 'search_date'],
    'place2_lnsdx_fnsdx_rt_sd' => ['freecen2_place_id', 'search_soundex.last_name', 'search_soundex.first_name', 'record_type', 'search_date'],
    'place2_fn_rt_sd' => ['freecen2_place_id', 'search_names.first_name', 'record_type', 'search_date'],
    'place_2fnsdx_rt_sd' => ['freecen2_place_id', 'search_soundex.first_name', 'record_type', 'search_date'],
    'place2_rt_sd' => ['freecen2_place_id', 'record_type', 'search_date']
  }.freeze

  CEN_BASIC_INDEXES = {
    'ln_rt_sd' => ['search_names.last_name', 'record_type', 'search_date'],
    'ln_fn_rt_sd' => ['search_names.last_name', 'search_names.first_name', 'record_type', 'search_date'],
    'lnsdx_rt_sd' => ['search_soundex.last_name', 'record_type', 'search_date'],
    'lnsdx_fnsdx_rt_sd' => ['search_soundex.last_name', 'search_soundex.first_name', 'record_type', 'search_date']
  }.freeze


  REG_CHAPMAN_INDEXES = {
    'county_ln_rt_sd_ssd' => ['chapman_code', 'search_names.last_name', 'record_type', 'search_date', 'secondary_search_date'],
    'county_fn_ln_rt_sd_ssd' => ['chapman_code', 'search_names.first_name', 'search_names.last_name', 'record_type', 'search_date', 'secondary_search_date'],
    'county_lnsdx_rt_sd_ssd' => ['chapman_code', 'search_soundex.last_name', 'record_type', 'search_date', 'secondary_search_date'],
    'county_fnsdx_lnsdx_rt_sd_ssd' => ['chapman_code', 'search_soundex.first_name', 'search_soundex.last_name', 'record_type', 'search_date', 'secondary_search_date']
  }.freeze

  REG_PLACE_INDEXES = {
    'place_fn_rt_sd_ssd' => ['place_id', 'search_names.first_name', 'record_type', 'search_date', 'secondary_search_date'],
    'place_ln_rt_sd_ssd' => ['place_id', 'search_names.last_name', 'record_type', 'search_date', 'secondary_search_date'],
    'place_ln_fn_rt_sd_ssd' => ['place_id', 'search_names.last_name', 'search_names.first_name', 'record_type', 'search_date', 'secondary_search_date'],
    'place_fnsdx_rt_sd_ssd' => ['place_id', 'search_soundex.first_name', 'record_type', 'search_date', 'secondary_search_date'],
    'place_lnsdx_fnsdx_rt_sd_ssd' => ['place_id', 'search_soundex.last_name', 'search_soundex.first_name', 'record_type', 'search_date', 'secondary_search_date'],
    'place_lnsdx_rt_sd_ssd' => ['place_id', 'search_soundex.last_name', 'record_type', 'search_date', 'secondary_search_date']
  }.freeze

  REG_BASIC_INDEXES = {
    'ln_fn_rt_sd_ssd' => ['search_names.last_name', 'search_names.first_name', 'record_type', 'search_date', 'secondary_search_date'],
    'lnsdx_fnsdx_rt_sd_ssd' => ['search_soundex.last_name', 'search_soundex.first_name', 'record_type', 'search_date', 'secondary_search_date'],
    'ln_rt_sd_ssd' => ['search_names.last_name', 'record_type', 'search_date', 'secondary_search_date'],
    'lnsdx_rt_sd_ssd' => ['search_soundex.last_name', 'record_type', 'search_date', 'secondary_search_date']
  }.freeze

  BMD_INDEXES = {
    'chapman_code_search_date' => ['chapman_code', 'search_date'],
    'ln_rt_ssd' => ['chapman_code', 'search_date', 'search_names.last_name', 'record_type', 'secondary_search_date'],
    'ln_fn_rt_ssd' => ['chapman_code', 'search_date', 'search_names.last_name', 'search_names.first_name', 'record_type', 'secondary_search_date'],
    'lnsdx_fnsdx_rt_ssd' => ['chapman_code', 'search_date', 'search_soundex.last_name', 'search_soundex.first_name', 'record_type', 'secondary_search_date'],
    'lnsdx_rt_ssd' => ['chapman_code', 'search_date', 'search_soundex.last_name', 'record_type', 'secondary_search_date'],
    'ln_fn_rt_sd_ssd' => ['search_names.last_name', 'search_names.first_name', 'record_type', 'search_date', 'secondary_search_date'],
    'lnsdx_fnsdx_rt_sd_ssd' => ['search_soundex.last_name', 'search_soundex.first_name', 'record_type', 'search_date', 'secondary_search_date'],
    'ln_place_rt_sd_ssd' => ['search_names.last_name', 'place_id', 'record_type', 'search_date', 'secondary_search_date'],
    'ln_county_rt' => ['search_names.last_name', 'chapman_code', 'record_type'],
    'ln_fn_county_rt' => ['search_names.last_name', 'search_names.first_name', 'chapman_code', 'record_type'],
    'lnsdx_county_rt' => ['search_soundex.last_name', 'chapman_code', 'record_type'],
    'lnsdx_fnsdx_county_rt' => ['search_soundex.last_name', 'search_soundex.first_name', 'chapman_code', 'record_type'],
    'ln_fn_place_rt_sd_ssd' => ['search_names.last_name', 'search_names.first_name', 'place_id', 'record_type', 'search_date', 'secondary_search_date'],
    'lnsdx_place_rt_sd_ssd' => ['search_soundex.last_name', 'place_id', 'record_type', 'search_date', 'secondary_search_date'],
    'lnsdx_fnsdx_place_rt_sd_ssd' => ['search_soundex.last_name', 'search_soundex.first_name', 'place_id', 'record_type', 'search_date', 'secondary_search_date'],
    'fn_place_rt_sd_ssd' => ['search_names.first_name', 'place_id', 'record_type', 'search_date', 'secondary_search_date'],
    'fnsdx_place_rt_sd_ssd' => ['search_soundex.first_name', 'place_id', 'record_type', 'search_date', 'secondary_search_date'],
    'place_rt_sd_ssd' => ['place_id', 'record_type', 'search_date', 'secondary_search_date']

  }.freeze

  def apply_index
    case app_template
    when 'freebmd'
      index = BMD_INDEXES_HINT
    when 'freecen'
      index = NEW_INDEXES
    when 'freereg'
      index = MERGED_INDEXES
    end
    index
  end

  def index_score(index_name, search_fields, index_component)
      fields = index_component[index_name]
      best_score = -1
      fields.each do |field|
        if search_fields.any? { |param| param == field }
          increment = field == 'birth_chapman_code' ? 2 : 1
          best_score = best_score + 1
        else
          return best_score
          # bail since search field hasn't been found
        end
      end
      best_score
    end
    
  def index_hint(search_params)
    candidates = apply_index.keys
    search_fields = fields_from_params(search_params)
    case App.name_downcase
    when 'freebmd'
      candidates = BMD_INDEXES.keys
      index_component = BMD_INDEXES
    when 'freecen'
      if search_fields.include?('place_id')
        p 'place_id'
        candidates = CEN_PLACE_INDEXES.keys
        index_component = CEN_PLACE_INDEXES
      elsif search_fields.include?('freecen2_place_id')
        p 'freecen2_place_id'
        candidates = CEN2_PLACE_INDEXES.keys
        index_component = CEN2_PLACE_INDEXES
      elsif search_fields.include?('chapman_code')
        candidates = CEN_CHAPMAN_INDEXES.keys
        index_component = CEN_CHAPMAN_INDEXES
      elsif search_fields.include?('birth_chapman_code')
        candidates = CEN_CHAPMAN_INDEXES.keys
        index_component = CEN_CHAPMAN_INDEXES
      else
        candidates = CEN_BASIC_INDEXES.keys
        index_component = CEN_BASIC_INDEXES
      end
    when 'freereg'
      if search_fields.include?('place_id')
        candidates = REG_PLACE_INDEXES.keys
        index_component = REG_PLACE_INDEXES
      elsif search_fields.include?('chapman_code')
        candidates = REG_CHAPMAN_INDEXES.keys
        index_component = REG_CHAPMAN_INDEXES
      else
        candidates = REG_BASIC_INDEXES.keys
        index_component = REG_BASIC_INDEXES
      end
    end
    scores = {}
    candidates.each { |name| scores[name] = index_score(name, search_fields, index_component) }
    best = scores.max_by { |_k, v| v}
    best[0]
  end

  def fields_from_params(search_params)
    fields = []
    search_params.each_pair do |key, value|
      extract_fields(fields, value, key.to_s)
    end
    fields.uniq
    fields
  end

  def extract_fields(fields, params, current_field)
    if params.is_a?(Hash)
      # walk down the syntax tree
      params.each_pair do |key, value|
        #ignore operators
        if key.to_s =~ /\$/
          new_field = String.new(current_field)
        else
          new_field = String.new(current_field + '.' + key.to_s)
        end
        extract_fields(fields, value, new_field)
      end
    else
      # terminate
      if indexable_value?(params)
        fields << current_field
      end
    end
  end

  def indexable_value?(param)
    if param.is_a? Regexp
      # does this begin with a wildcard?
      param.inspect.match(/^\/\^/) # this regex looks a bit like a cheerful owl
    else
      true
    end
  end

  def get_search_table
    MyopicVicar::Application.config.search_table.constantize
  end

  def app_template
    MyopicVicar::Application.config.template_set
  end

  def sort_results(results)
    # next reorder in memory
   # raise SearchOrder::SURNAME.inspect
    if results.present?
      case order_field
      when *selected_sort_fields
        order = order_field.to_sym
        results.each do |rec|
        end
        results.sort! do |x, y|
          if order_asc
            (x[order] || '') <=> (y[order] || '')
          else
            (y[order] || '') <=> (x[order] || '')
          end
        end
      when SearchOrder::DATE
        if order_asc
          results.sort! { |x, y| (x[:search_date] || '') <=> (y[:search_date] || '') }
        else
          results.sort! { |x, y| (y[:search_date] || '') <=> (x[:search_date] || '') }
        end
      when SearchOrder::LOCATION
        if order_asc
          results.sort! do |x, y|
            compare_location(x, y)
          end
        else
          results.sort! do |x, y|
            compare_location(y, x) # note the reverse order
          end
        end
      when SearchOrder::NAME
        if order_asc
          results.sort! do |x, y|
            compare_name(x, y)
          end
        else
          results.sort! do |x, y|
            compare_name(y, x) # note the reverse order
          end
        end
      when SearchOrder::SURNAME
        if self.order_asc
          results.sort! do |x, y|
            compare_name_bmd(y, x, 'Surname','GivenName')
          end
        else
          results.sort! do |x, y|
             compare_name_bmd(x,y, 'Surname','GivenName')
          end
        end
      when SearchOrder::FIRSTNAME
        if self.order_asc
          results.sort! do |x, y|
            compare_name_bmd(y, x, 'GivenName','Surname')
          end
        else
          results.sort! do |x, y|
             compare_name_bmd(x,y, 'GivenName','Surname')
          end
        end
      when SearchOrder::BMD_RECORD_TYPE
        if self.order_asc
          results.sort! do |x, y|
            compare_name_bmd(y, x, 'RecordTypeID')
          end
        else
          results.sort! do |x, y|
             compare_name_bmd(x,y, 'RecordTypeID')
          end
        end
       when SearchOrder::BMD_DATE
        if self.order_asc
          results.sort! do |x, y|
            compare_name_bmd(y, x, 'QuarterNumber')
          end
        else
          results.sort! do |x, y|
             compare_name_bmd(x,y, 'QuarterNumber')
          end
        end
      end
    end
    results
  end
end