module SharedSearchMethods
  extend ActiveSupport::Concern

  BMD_INDEXES_HINT = {
    'PRIMARY' => ['RecordNumber'],
    'SURNAME' => ['Surname', 'GivenName', 'QuarterNumber'],
  }

  
  NEW_INDEXES = {
    'ln_county_rt_sd_ssd' => ['search_names.last_name', 'chapman_code', 'record_type', 'search_date', 'secondary_search_date'],
    'ln_fn_county_rt_sd_ssd' => ['search_names.last_name', 'search_names.first_name', 'chapman_code', 'record_type', 'search_date', 'secondary_search_date'],
    'lnsdx_county_rt_sd_ssd' => ['search_soundex.last_name', 'chapman_code', 'record_type', 'search_date', 'secondary_search_date'],
    'lnsdx_fnsdx_county_rt_sd_ssd' => ['search_soundex.last_name', 'search_soundex.first_name', 'chapman_code', 'record_type', 'search_date', 'secondary_search_date'],
    'ln_place_rt_sd_ssd' => ['search_names.last_name', 'place_id', 'record_type', 'search_date', 'secondary_search_date'],
    'ln_fn_place_rt_sd_ssd' => ['search_names.last_name', 'search_names.first_name', 'place_id', 'record_type', 'search_date', 'secondary_search_date'],
    'lnsdx_place_rt_sd_ssd' => ['search_soundex.last_name', 'place_id', 'record_type', 'search_date', 'secondary_search_date'],
    'lnsdx_fnsdx_place_rt_sd_ssd' => ['search_soundex.last_name', 'search_soundex.first_name', 'place_id', 'record_type', 'search_date', 'secondary_search_date'],
    'fn_place_rt_sd_ssd' => ['search_names.first_name', 'place_id', 'record_type', 'search_date', 'secondary_search_date'],
    'fnsdx_place_rt_sd_ssd' => ['search_soundex.first_name', 'place_id', 'record_type', 'search_date', 'secondary_search_date'],
    'place_rt_sd_ssd' => ['place_id', 'record_type', 'search_date', 'secondary_search_date'],
    'birth_chapman_code_names_date' => ['birth_chapman_code', 'search_names.last_name', 'search_names.first_name', 'search_date']
  }

  SHARDED_INDEXES = {
    'search_date_chapman_code' => ['search_date', 'chapman_code'],
    'ln_rt_ssd' => ['search_date', 'chapman_code', 'search_names.last_name', 'record_type', 'secondary_search_date'],
    'ln_fn_rt_ssd' => ['search_date', 'chapman_code', 'search_names.last_name', 'search_names.first_name', 'record_type', 'secondary_search_date'],
    'lnsdx_fnsdx_rt_ssd' => ['search_date', 'chapman_code', 'search_soundex.last_name', 'search_soundex.first_name', 'record_type', 'secondary_search_date'],
    'lnsdx_rt_ssd' => ['search_date', 'chapman_code', 'search_soundex.last_name', 'record_type', 'secondary_search_date'],
    'pl_ln_rt_ssd' => ['search_date', 'chapman_code', 'place_id', 'search_names.last_name', 'record_type', 'secondary_search_date'],
    'pl_lnsdx_rt_ssd' => ['search_date', 'chapman_code', 'place_id', 'search_soundex.last_name', 'record_type', 'secondary_search_date'],
    'pl_lnsdx_fnsdx_rt_ssd' => ['search_date', 'chapman_code', 'place_id', 'search_soundex.last_name', ' search_soundex.first_name', 'record_type', 'secondary_search_date'],
    'pl_ln_fn_rt_ssd' => ['search_date', 'chapman_code', 'place_id', 'search_names.last_name', ' search_names.first_name', 'record_type', 'secondary_search_date'],
    'pl_fn_rt_ssd' => ['search_date', 'chapman_code', 'place_id', 'search_names.first_name', 'record_type', 'secondary_search_date'],
    'pl_fnsdx_rt_ssd' => ['search_date', 'chapman_code', 'place_id', 'search_soundex.first_name', 'record_type', 'secondary_search_date'],
    'pl_rt_ssd' => ['search_date', 'chapman_code', 'place_id', 'record_type', 'secondary_search_date']
  }


  MERGED_INDEXES = {
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

  }

  def apply_index
    case app_template
    when 'freebmd'
      BMD_INDEXES_HINT
    when 'freecen'
      NEW_INDEXES
    when 'freereg'
      MERGED_INDEXES
    end
  end

  def index_score(index_name, search_fields)
    # raise (NEW_INDEXES[ln_county_rt_sd_ssd]).inspect
    fields = apply_index[index_name]
    # raise fields.inspect
    best_score = -1
    fields.each do |field|
      if search_fields.any? { |param| param == field }
        best_score = best_score + 1
      else
        return best_score
        # bail since search field hasn't been found
      end
    end
    return best_score
  end
    
  def index_hint(search_params)
    candidates = apply_index.keys
    scores = {}
    search_fields = fields_from_params(search_params)
    candidates.each { |name| scores[name] = index_score(name, search_fields) }
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
end