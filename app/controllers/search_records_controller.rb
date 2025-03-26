# Copyright 2012 Trustees of FreeBMD
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
#
class SearchRecordsController < ApplicationController
  before_action :viewed
  skip_before_action :require_login
  require 'csv'
  rescue_from Mongo::Error::OperationFailure, with: :catch_error

  def catch_error
    logger.warn("#{appname_upcase}::RECORD: Record encountered a problem #{params}")
    flash[:notice] = 'We are sorry but the record you requested no longer exists; possibly as a result of some data being edited. You will need to redo the search with the original criteria to obtain the updated version.'
    redirect_back(fallback_location: new_search_query_path)
  end

  def index
    flash[:notice] = 'That action does not exist'
    redirect_back(fallback_location: new_search_query_path) && return
  end

  def show
    proceed, @search_query, @search_record, message = SearchRecord.check_show_parameters(session[:query], params)
    redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed

    @show_navigation = @search_query.present? && (params[:friendly].present? || params[:dwel].present?) ? true : false
    @appname = appname_downcase
    @page_number = params[:page_number].to_i
    if @appname == 'freebmd'
      show_freebmd
    elsif @appname == 'freecen' && @search_record.freecen_csv_entry_id.present?
      show_freecen_csv
      render '/freecen_csv_entries/show'
    elsif @appname == 'freecen' && @search_record.freecen_csv_entry_id.blank?
      show_freecen
    elsif @appname == 'freereg'
      @display_date = false
      show_freereg
    end
  end

  def show_freebmd
    # common code for the three show versions show print and citation
  end

  def show_freecen
    # common code for the three show versions show print and citation
    @individual = FreecenIndividual.find_by(_id: @search_record.freecen_individual_id)
    @dwelling = @individual.freecen_dwelling if @individual
    @cen_year = ' '
    @cen_piece = ' '
    @cen_chapman_code = ' '
    if @dwelling && @dwelling.freecen_piece
      @dwelling_offset = 0
      @dwelling_number = @dwelling.dwelling_number
      if !params[:dwel].nil?
        @dwelling = @dwelling.freecen_piece.freecen_dwellings.where(_id: params[:dwel]).first
        if @dwelling.nil?
          redirect_to new_search_query_path
          return
        end
        @dwelling_offset = @dwelling.dwelling_number - @dwelling_number
        @dwelling_number = @dwelling.dwelling_number
      end
      @cen_year = @dwelling.freecen_piece.year
      @cen_piece = @dwelling.freecen_piece.piece_number.to_s
      @cen_chapman_code = @dwelling.freecen_piece.chapman_code
      prev_next_dwellings = @dwelling.prev_next_dwelling_ids
      @cen_prev_dwelling = prev_next_dwellings[0]
      @cen_next_dwelling = prev_next_dwellings[1]
      @dweling_values = @dwelling.dwelling_display_values(@cen_year, @cen_chapman_code)
    end
    @response, @next_record, @previous_record = @search_query.next_and_previous_records(params[:id]) unless @search_query.blank? || @search_query.is_a?(String)
    add_head
    add_evidence_explained_values
    add_address_for_citation
    add_series_code
    add_viewed
  end

  def add_head
    @searched_user_name = @search_record.transcript_names.first['first_name'] + ' ' + @search_record.transcript_names.first['last_name']
    @is_family_head = false
    @family_head_name = nil
    #checks whether the head of the house is the same person searched for
    if @individual.relationship == 'Head'
      @is_family_head = true
    elsif @dwelling.freecen_individuals.present?
      @family_head_name = @dwelling.freecen_individuals.asc(:sequence_in_household).first['forenames'] + ' ' + @dwelling.freecen_individuals.asc(:sequence_in_household).first['surname']
    end
  end

  def add_head_csv
    @searched_user_name = @search_record.transcript_names.first['first_name'] + ' ' + @search_record.transcript_names.first['last_name']
    @is_family_head = false
    @family_head_name = nil
    #checks whether the head of the house is the same person searched for
    if @freecen_csv_entry.relationship == 'Head'
      @is_family_head = true
    else
      entry = FreecenCsvEntry.where(freecen_csv_file_id: @freecen_csv_file_id, dwelling_number: @dwel, sequence_in_household: 1).first
      @family_head_name = entry.forenames + ' ' + entry.surname unless entry.blank?
    end
  end

  def add_evidence_explained_values
    @piece = @cen_piece
    @place = @dwelling.place if @place.present?
    @place = @dwelling.freecen2_place if @place.blank?
    @place = @place.place_name if @place.present?
    @enumeration_district = @dwelling.enumeration_district
    @civil_parish = @dwelling.civil_parish
    @ecclesiastical_parish = @dwelling.ecclesiastical_parish
    @folio = @dwelling.folio_number
    @page = @dwelling.page_number
    @schedule = @dwelling.schedule_number
    @ee_address = @dwelling.house_or_street_name
  end

  def add_address_for_citation
    @user_address = ''
    @user_address += @dwelling.house_number + ', ' unless @dwelling.house_number == '-' || @dwelling.house_number.blank?
    @user_address += @dwelling.house_or_street_name + ', ' unless @dwelling.house_or_street_name == '-' || @dwelling.house_or_street_name.blank?
    @county = ChapmanCode.name_from_code(@cen_chapman_code)
    @user_address += @county + ', ' unless @county == '-' || @county.blank?
    add_country
    @user_address += @country
  end

  def add_country
    if ChapmanCode::CODES['Scotland'].values.member?(@cen_chapman_code)
      @country = 'Scotland'
    elsif ChapmanCode::CODES['Ireland'].values.member?(@cen_chapman_code)
      @country = 'Ireland'
    elsif ChapmanCode::CODES['Wales'].values.member?(@cen_chapman_code)
      @country = 'Wales'
    else
      @country = 'England'
    end
  end

  def add_evidence_explained_values_csv
    @place = @piece.freecen2_place.place_name
    split_number = @cen_piece.split('_')
    @piece = split_number[1]
    @enumeration_district = @freecen_csv_entry.enumeration_district
    @civil_parish = @freecen_csv_entry.civil_parish
    @ecclesiastical_parish = @freecen_csv_entry.ecclesiastical_parish
    @folio = @freecen_csv_entry.folio_number
    @page = @freecen_csv_entry.page_number
    @schedule = @freecen_csv_entry.schedule_number
    @ee_address = @freecen_csv_entry.house_or_street_name
  end

  def add_address_for_citation_csv
    @user_address = ''
    @user_address += @freecen_csv_entry.house_number + ', ' unless @freecen_csv_entry.house_number == '-' || @freecen_csv_entry.house_number.blank?
    @user_address += @freecen_csv_entry.house_or_street_name + ', ' unless @freecen_csv_entry.house_or_street_name == '-' || @freecen_csv_entry.house_or_street_name.blank?
    @county = ChapmanCode.name_from_code(@cen_chapman_code)
    @user_address += @county + ', ' unless @county == '-' || @county.blank?
    add_country
    @user_address += @country
  end

  def add_uninhabited
    if @individuals.count == 1 && @individuals.first.uninhabited_flag.present?
      @uninhabited = @individuals.first.uninhabited_flag
      case @uninhabited
      when 'b'
        message = 'Building in progress'
      when 'u'
        message = 'Unoccupied'
      when 'v'
        message = 'Family away or visiting'
      when 'n'
        message = 'Schedule was not used'
      end
      message += ' : ' + @individuals.first.notes if @individuals.first.notes.present?
      @uninhabited = message
      @uninhabited
    end
  end

  def add_viewed
    if @search_query.present?
      @search_result = @search_query.search_result
      @viewed_records = @search_result.viewed_records
      @viewed_records << params[:id] unless @viewed_records.include?(params[:id])
      @search_result.update_attribute(:viewed_records, @viewed_records)
    end
  end
  def add_series_code
    # Adds the department and series codes based on the citation year
    case @cen_year
    when '1841' || '1851'
      @dep_series_code = 'HO 107'
    when '1861'
      @dep_series_code = 'RG 9'
    when '1871'
      @dep_series_code = 'RG 10'
    when '1881'
      @dep_series_code = 'RG 11'
    when '1891'
      @dep_series_code = 'RG 12'
    when '1901'
      @dep_series_code = 'RG 13'
    when '1911'
      @dep_series_code = 'RG 14'
    when '1921'
      @dep_series_code = 'RG 15'
    else
      @dep_series_code = nil
    end
    #census database description
    if ChapmanCode::CODES['Scotland'].values.member?(@cen_chapman_code)
      @census_database = "Scottish General Register Office: #{@cen_year} Census Returns database"
    elsif ChapmanCode::CODES['Ireland'].values.member?(@cen_chapman_code)
      @census_database = "Northern Ireland General Register Office: #{@cen_year} Census Returns database"
    else
      @census_database = "General Register Office: #{@cen_year} Census Returns database"
    end
    @viewed_date = Date.today.strftime("%e %b %Y")
    @viewed_year = Date.today.strftime("%Y")
  end

  def show_freereg
    # common code for the three show versions show print and citation
    @entry = @search_record.freereg1_csv_entry
    @record_name = @search_record.get_record_names
    @entry.display_fields(@search_record)
    proceed, @place_id, @church_id, @register_id, extended_def = @entry.location_ids
    message = 'There is an issue with the linkages for this records. Please contact us using the Website Problem option to report this message'
    redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed

    @annotations = Annotation.find(@search_record[:annotation_ids]) if @search_record[:annotation_ids]
    @image_id = @entry.get_the_image_id(@church, @user, session[:manage_user_origin], session[:image_server_group_id], session[:chapman_code])
    @order, @array_of_entries, @json_of_entries = @entry.order_fields_for_record_type(@search_record[:record_type], @entry.freereg1_csv_file.def, current_authentication_devise_user.present?)
    @embargoed = @search_record[:embargoed]
    if @search_query.present?
      @search_result = @search_query.search_result
      @viewed_records = @search_result.viewed_records
      @viewed_records << params[:id] unless @viewed_records.include?(params[:id])
      @search_result.update_attribute(:viewed_records, @viewed_records)
      @response, @next_record, @previous_record = @search_query.next_and_previous_records(params[:id]) if params[:ucf].blank?
    end
  end

  def show_print_version
    proceed, @search_query, @search_record, message = SearchRecord.check_show_parameters(session[:query], params)
    redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed

    @show_navigation = false
    @appname = appname_downcase
    if @appname == 'freebmd'
      show_freebmd
    elsif @appname == 'freecen' && @search_record.freecen_csv_entry_id.present?
      show_freecen_csv
      render '/freecen_csv_entries/show', layout: false
    elsif @appname == 'freecen' && @search_record.freecen_csv_entry_id.blank?
      show_freecen
      @display_date = true
      render '_search_records_freecen_print', layout: false
    elsif @appname == 'freereg'
      @display_date = false
      show_freereg
      @display_date = false
      @printable_format = true
      @display_date = true
      @all_data = true
      show_freereg
      respond_to do |format|
        format.html { render 'show', layout: false }
        format.json do
          file_name = "search-record-#{@entry.id}.json"
          send_data @json_of_entries.to_json, type: 'application/json; header=present', disposition: "attachment; filename=\"#{file_name}\""
        end
        format.csv do
          header_line = CSV.generate_line(@order, options = { row_sep: "\r\n" })
          data_line = CSV.generate_line(@array_of_entries, options = { row_sep: "\r\n", force_quotes: true })
          file_name = "search-record-#{@entry.id}.csv"
          send_data (header_line + data_line), type: 'text/csv', disposition: "attachment; filename=\"#{file_name}\""
        end
      end
    end
  end

  def show_freecen_csv
    @freecen_csv_entry = @search_record.freecen_csv_entry.blank? ? session[:freecen_csv_entry_id] : @search_record.freecen_csv_entry

    session[:freecen_csv_entry_id] = @freecen_csv_entry._id
    @individual = @freecen_csv_entry
    @freecen_csv_file = @freecen_csv_entry.blank? ? FreecenCsvFile.find(session[:freecen_csv_file_id]) : @freecen_csv_entry.freecen_csv_file
    @freecen_csv_file_id, @freecen_csv_file_name, @file_owner = @freecen_csv_file.display_for_csv_show
    @piece = @freecen_csv_file.freecen2_piece
    @year, @chapman_code, @place_name, @cen_piece = @piece.display_for_csv_show
    @csv = true
    if params[:dwel].present?
      @dwel = params[:dwel].to_i
      @dwelling_offset = session[:dwel].present? ?  @dwel - session[:dwel] : @dwel
      @individuals = FreecenCsvEntry.where(freecen_csv_file_id: @freecen_csv_file_id, dwelling_number: @dwel).order_by(sequence_in_household: 1) unless @dwel.zero?
      @freecen_csv_entry = @individuals.first unless @dwel.zero?
    else
      @dwelling_offset = 0
      @dwel = @freecen_csv_entry.dwelling_number
      @individuals = FreecenCsvEntry.where(freecen_csv_file_id: @freecen_csv_file_id, dwelling_number: @dwel).order_by(sequence_in_household: 1)
      session[:dwel] = @dwel
    end
    add_uninhabited
    @type = session[:cen_index_type]
    @freecen_csv_entry.add_address(@freecen_csv_file_id, @dwel)
    @response, @next_record, @previous_record = @search_query.next_and_previous_records(params[:id]) unless @search_query.is_a?(String)
    @cen_chapman_code = @chapman_code
    @cen_year = @year
    @cen_prev_dwelling = @dwel == 1 ? nil : @dwel - 1
    @cen_next_dwelling = @freecen_csv_file.next_dwelling(@dwel)
    add_evidence_explained_values_csv
    add_address_for_citation_csv
    add_series_code
    add_viewed
    add_head_csv
  end

  # implementation of the citation generator
  def show_citation
    proceed, @search_query, @search_record, message = SearchRecord.check_show_parameters(session[:query], params)
    redirect_back(fallback_location: new_search_query_path, notice: message) && return unless proceed

    @show_navigation = @search_query.present? && (params[:friendly].present? || params[:dwel].present?) ? true : false
    @appname = appname_downcase
    case @appname
    when 'freebmd'
      show_freebmd
    when 'freecen'
      @display_date = true
      show_freecen
    when 'freereg'
      @display_date = false
      @printable_format = true
      @display_date = true
      @all_data = true
      show_freereg
    end
    respond_to do |format|
      @viewed_date = Date.today.strftime("%e %b %Y")
      @viewed_year = Date.today.strftime("%Y")
      @type = params[:citation_type]
      format.html { render :citation, layout: false }
    end

  end

  def viewed
    session[:viewed] ||= []
  end
end
