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
    redirect_back(fallback_location: new_search_query_path) && return unless show_value_check

    @appname = appname_downcase
    @page_number = params[:page_number].to_i
    if @appname == 'freecen'
      @search_record = SearchRecord.record_id(params[:id]).first
      @individual = @search_record.freecen_individual
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
        @dweling_values = @dwelling.dwelling_display_values(@cen_year,@cen_chapman_code)
        #   ------------------------ Fields required for citation generation ------------------------
        @user_address = ""
        unless @dweling_values[11] == "-" || @dweling_values[11].nil? || @dweling_values[11].empty?
          @user_address += @dweling_values[11]  + ", "
        end
        unless @dweling_values[2] == "-" || @dweling_values[2].nil? || @dweling_values[2].empty?
          @user_address += @dweling_values[2]  + ", "
        end
        @county = @dweling_values[1].slice(0..(@dweling_values[1].index(' ')-1))
        unless @county == "-" || @county.nil? || @county.empty?
          @user_address += @county  + ", "
        end
        @user_address += @search_record.place["country"]

        #evidence explained
        @piece = @dweling_values[5]
        @place = @dweling_values[2]
        @enumeration_district = @dweling_values[6]
        @civil_parish = @dweling_values[3]
        @ecclesiastical_parish = @dweling_values[4]
        @folio = @dweling_values[7]
        @page = @dweling_values[8]
        @schedule = @dweling_values[9]
        @ee_address = @dweling_values[11]

        #census database description
        @census_database = 'England, Scotland and Wales Census'

        @wikitree_database = 'General Register Office'

        if @search_record.place['country'] = 'Scotland'
          @wikitree_database = 'Scottish General Register Office'
        end

        @searched_user_name = @search_record.transcript_names.first['first_name'] + " " + @search_record.transcript_names.first['last_name']
        @viewed_date = Date.today.strftime("%e %b %Y")
        @viewed_year = Date.today.strftime("%Y")

        @is_family_head = false
        @family_head_name = nil

        #checks whether the head of the house is the same person searched for
        if @individual.individual_display_values(@cen_year,@cen_chapman_code)[2].eql? "Head"
          @is_family_head = true
        else
          @family_head_name = @dwelling.freecen_individuals.asc(:sequence_in_household).first['forenames'] + " " + @dwelling.freecen_individuals.asc(:sequence_in_household).first['surname']
        end

        #Adds the department and series codes based on the citation year
        case @cen_year
        when "1841" || "1851"
          @dep_series_code = "HO 107"
        when "1861"
          @dep_series_code = "RG 9"
        when "1871"
          @dep_series_code = "RG 10"
        when "1881"
          @dep_series_code = "RG 11"
        when "1891"
          @dep_series_code = "RG 12"
        when "1901"
          @dep_series_code = "RG 13"
        when "1911"
          @dep_series_code = "RG 14"
        else
          @dep_series_code = nil
        end
      end
    elsif @appname == 'freereg'
      @display_date = false
      @entry.display_fields(@search_record)
      @entry.acknowledge
      @place_id, @church_id, @register_id, extended_def = @entry.get_location_ids
      @annotations = Annotation.find(@search_record[:annotation_ids]) if @search_record[:annotation_ids]
      if @search_query.present?
        @search_result = @search_query.search_result
        @viewed_records = @search_result.viewed_records
        @viewed_records << params[:id] unless @viewed_records.include?(params[:id])
        @search_result.update_attribute(:viewed_records, @viewed_records)
      end
      @image_id = @entry.get_the_image_id(@church, @user, session[:manage_user_origin], session[:image_server_group_id], session[:chapman_code])
      @order, @array_of_entries, @json_of_entries = @entry.order_fields_for_record_type(@search_record[:record_type], @entry.freereg1_csv_file.def, current_authentication_devise_user.present?)

    end
  end

  def show_print_version
    redirect_back(fallback_location: new_search_query_path) && return unless show_value_check

    @appname = appname_downcase
    if @appname == 'freecen'
      @search_record = SearchRecord.record_id(params[:id]).first
      @individual = @search_record.freecen_individual
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

      end
      @display_date = true
      render "_search_records_freecen_print", :layout => false

    elsif @appname == 'freereg'
      @printable_format = true
      @display_date = true
      @all_data = true
      @entry.display_fields(@search_record)
      @entry.acknowledge
      @place_id, @church_id, @register_id, extended_def = @entry.get_location_ids
      @annotations = Annotation.find(@search_record[:annotation_ids]) if @search_record[:annotation_ids]
      @search_result = @search_query.search_result if @search_query.present?
      @all_data = true
      @order, @array_of_entries, @json_of_entries = @entry.order_fields_for_record_type(@search_record[:record_type], @entry.freereg1_csv_file.def, current_authentication_devise_user.present?)
      respond_to do |format|
        format.html { render 'show', layout: false }
        format.json do
          file_name = "search-record-#{@entry.id}.json"
          send_data @json_of_entries.to_json, :type => 'application/json; header=present', :disposition => "attachment; filename=\"#{file_name}\""
        end
        format.csv do
          header_line = CSV.generate_line(@order, options = { :row_sep => "\r\n" })
          data_line = CSV.generate_line(@array_of_entries, options = { :row_sep => "\r\n", :force_quotes => true })
          file_name = "search-record-#{@entry.id}.csv"
          send_data (header_line + data_line), :type => 'text/csv', :disposition => "attachment; filename=\"#{file_name}\""
        end
      end
    end
  end

  def show_value_check
    messagea = 'We are sorry but the record you requested no longer exists; possibly as a result of some data being edited. You will need to redo the search with the original criteria to obtain the updated version.'
    warning = "#{appname_upcase}::SEARCH::ERROR Missing entry for search record"
    warninga = "#{appname_upcase}::SEARCH::ERROR Missing parameter"
    if params[:id].blank?
      flash[:notice] = messagea
      logger.warn(warninga)
      logger.warn " #{params[:id]} no longer exists"
      flash.keep
      return false
    end
    @search_query = SearchQuery.find(session[:query]) if session[:query].present?

    if appname_downcase == 'freereg'
      if session[:query].blank? || params[:ucf] == 'true'
        @search_record = SearchRecord.find(params[:id])
      else
        response, @next_record, @previous_record = @search_query.next_and_previous_records(params[:id])

        @search_record = response ? @search_query.locate(params[:id]) : nil
        return false unless response
      end
      if @search_record.blank?
        flash[:notice] = messagea
        logger.warn(warning)
        logger.warn "#{@search_record} no longer exists"
        flash.keep
        return false
      end
      if @search_record[:freereg1_csv_entry_id].blank?
        logger.warn(warning)
        logger.warn "#{@search_record} no longer exists"
        flash[:notice] = messagea
        flash.keep
        return false
      end
      @entry = Freereg1CsvEntry.find(@search_record[:freereg1_csv_entry_id])
      if @entry.blank?
        logger.warn(warning)
        logger.warn "#{@search_record} no longer exists"
        flash[:notice] = messagea
        flash.keep
        return false
      end
      if @entry.freereg1_csv_file.blank?
        logger.warn(warning)
        logger.warn "#{@search_record} no longer exists"
        flash[:notice] = messagea
        flash.keep
        return false
      end
    end
    true
  end

  def viewed
    session[:viewed] ||= []
  end

  # implementation of the citation generator
  def show_citation
    redirect_back(fallback_location: new_search_query_path) && return unless show_value_check

    if appname_downcase == 'freecen'

      @search_record = SearchRecord.record_id(params[:id]).first
      @individual = @search_record.freecen_individual
      @dwelling = @individual.freecen_dwelling if @individual
      @cen_year = ' '
      @cen_chapman_code = ' '

      if @dwelling && @dwelling.freecen_piece
        if !params[:dwel].nil?
          @dwelling = @dwelling.freecen_piece.freecen_dwellings.where(_id: params[:dwel]).first
          if @dwelling.nil?
            redirect_to new_search_query_path
            return
          end
        end
        @cen_year = @dwelling.freecen_piece.year
        @cen_chapman_code = @dwelling.freecen_piece.chapman_code
        @dweling_values = @dwelling.dwelling_display_values(@cen_year,@cen_chapman_code)

        #   ------------------------ Fields required for citation generation ------------------------
        @user_address = ""
        unless @dweling_values[11] == "-" || @dweling_values[11].nil? || @dweling_values[11].empty?
          @user_address += @dweling_values[11]  + ", "
        end
        unless @dweling_values[2] == "-" || @dweling_values[2].nil? || @dweling_values[2].empty?
          @user_address += @dweling_values[2]  + ", "
        end
        @county = @dweling_values[1].slice(0..(@dweling_values[1].index(' ')-1))
        unless @county == "-" || @county.nil? || @county.empty?
          @user_address += @county  + ", "
        end
        @user_address += @search_record.place["country"]

        #evidence explained
        @piece = @dweling_values[5]
        @place = @dweling_values[2]
        @enumeration_district = @dweling_values[6]
        @civil_parish = @dweling_values[3]
        @ecclesiastical_parish = @dweling_values[4]
        @folio = @dweling_values[7]
        @page = @dweling_values[8]
        @schedule = @dweling_values[9]
        @ee_address = @dweling_values[11]

        #census database description
        @census_database = 'England, Scotland and Wales Census'

        @searched_user_name = @search_record.transcript_names.first['first_name'] + " " + @search_record.transcript_names.first['last_name']
        @viewed_date = Date.today.strftime("%e %b %Y")
        @viewed_year = Date.today.strftime("%Y")

        @is_family_head = false
        @family_head_name = nil

        #checks whether the head of the house is the same person searched for
        if @individual.individual_display_values(@cen_year,@cen_chapman_code)[2].eql? "Head"
          @is_family_head = true
        else
          @family_head_name = @dwelling.freecen_individuals.asc(:sequence_in_household).first['forenames'] + " " + @dwelling.freecen_individuals.asc(:sequence_in_household).first['surname']
        end

        #Adds the department and series codes based on the citation year
        case @cen_year
        when "1841" || "1851"
          @dep_series_code = "HO 107"
        when "1861"
          @dep_series_code = "RG 9"
        when "1871"
          @dep_series_code = "RG 10"
        when "1881"
          @dep_series_code = "RG 11"
        when "1891"
          @dep_series_code = "RG 12"
        when "1901"
          @dep_series_code = "RG 13"
        when "1911"
          @dep_series_code = "RG 14"
        else
          @dep_series_code = nil
        end

      end
      @display_date = true

    elsif appname_downcase == 'freereg'
      @printable_format = true
      @display_date = true
      @all_data = true
      @entry.display_fields(@search_record)
      @entry.acknowledge
      @place_id, @church_id, @register_id = @entry.get_location_ids
      @annotations = Annotation.find(@search_record[:annotation_ids]) if @search_record[:annotation_ids]
      #@search_result = @search_query.search_result
    end
    respond_to do |format|
      @viewed_date = Date.today.strftime("%e %b %Y")
      @viewed_year = Date.today.strftime("%Y")
      @type = params[:citation_type]
      format.html { render :citation, layout: false }
    end
  end
end
