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
  rescue_from Mongo::Error::OperationFailure, :with => :catch_error

  def catch_error
    logger.warn("FREEREG:RECORD: Record encountered a problem #{params}")
    flash[:notice] = 'We are sorry but the record you requested no longer exists; possibly as a result of some data being edited. You will need to redo the search with the original criteria to obtain the updated version.'
    redirect_to new_search_query_path
  end

  def index
    flash[:notice] = "That action does not exist"
    redirect_to new_search_query_path
    return
  end

  def show
    proceed = show_value_check
    if !proceed
      redirect_to new_search_query_path
      return
    else
      @display_date = false
      @entry.display_fields(@search_record)
      @entry.acknowledge
      @place_id,@church_id,@register_id,extended_def = @entry.get_location_ids
      @annotations = Annotation.find(@search_record[:annotation_ids]) if @search_record[:annotation_ids]
      @search_result = @search_query.search_result
      @viewed_records = @search_result.viewed_records
      @viewed_records << params[:id] unless @viewed_records.include?(params[:id])
      @search_result.update_attribute(:viewed_records, @viewed_records)
      @image_id = @entry.get_the_image_id(@church,@user,session[:manage_user_origin],session[:image_server_group_id],session[:chapman_code])
      @order, @array_of_entries, @json_of_entries = @entry.order_fields_for_record_type(@search_record[:record_type],@entry.freereg1_csv_file.def,current_authentication_devise_user.present?)
      #session[:viewed] << params[:id] unless  session[:viewed].length >= 10
    end
  end

  def show_print_version
    proceed = show_value_check
    if !proceed
      redirect_to new_search_query_path
      return
    else
      @printable_format = true
      @display_date = true
      @all_data = true
      @entry.display_fields(@search_record)
      @entry.acknowledge
      @place_id,@church_id,@register_id,extended_def = @entry.get_location_ids
      @annotations = Annotation.find(@search_record[:annotation_ids]) if @search_record[:annotation_ids]
      @search_result = @search_query.search_result
      @all_data = true
      @order,@array_of_entries, @json_of_entries = @entry.order_fields_for_record_type(@search_record[:record_type],@entry.freereg1_csv_file.def,current_authentication_devise_user.present?)
      respond_to do |format|
        format.html {render "show", :layout => false}
        format.json do
          file_name = "search-record-#{@entry.id}.json"
          send_data @json_of_entries.to_json, :type => 'application/json; header=present', :disposition => "attachment; filename=\"#{file_name}\""
        end
        format.csv do
          header_line = CSV.generate_line(@order,options = {:row_sep => "\r\n"})
          data_line = CSV.generate_line(@array_of_entries, options = {:row_sep => "\r\n",:force_quotes => true})
          file_name = "search-record-#{@entry.id}.csv"
          send_data (header_line + data_line), :type => 'text/csv' , :disposition => "attachment; filename=\"#{file_name}\""
        end
      end
    end
  end

  def show_value_check
    proceed = true
    begin
      if params[:search_id].nil? || params[:id].nil?
        flash[:notice] = 'We are sorry but the record you requested no longer exists; possibly as a result of some data being edited. You will need to redo the search with the original criteria to obtain the updated version.'
        proceed = false
      else
        @search_query = SearchQuery.find(params[:search_id])
        if params[:ucf] == "true"
          @search_record = SearchRecord.find(params[:id])
        else
          response, @next_record, @previous_record = @search_query.next_and_previous_records(params[:id])
          response ? @search_record = @search_query.locate(params[:id]) : @search_record = nil
        end
        if @search_record.nil?
          flash[:notice] = 'We are sorry but the record you requested no longer exists; possibly as a result of some data being edited. You will need to redo the search with the original criteria to obtain the updated version.'
          proceed = false
        else
          if @search_record[:freereg1_csv_entry_id].present?
            @entry = Freereg1CsvEntry.find(@search_record[:freereg1_csv_entry_id])
          else
            log_missing_document("entry for search record",@search_record[:id], @search_query.id)
            flash[:notice] = 'We are sorry but the record you requested no longer exists; possibly as a result of some data being edited. You will need to redo the search with the original criteria to obtain the updated version.'
            proceed = false
          end
          if  @entry.nil?
            proceed = false
            log_missing_document("Missing entry for search record",@search_record[:id], @search_query.id)
            flash[:notice] = 'We are sorry but the record you requested no longer exists; possibly as a result of some data being edited. You will need to redo the search with the original criteria to obtain the updated version.'
          elsif !@entry.freereg1_csv_file.present?
            proceed = false
            log_missing_document("file missing for entry for search record",@search_record[:id], @search_query.id)
            flash[:notice] = 'We are sorry but the record you requested no longer exists; possibly as a result of some data being edited. You will need to redo the search with the original criteria to obtain the updated version.'
          end
        end
      end
    rescue Mongoid::Errors::DocumentNotFound
      log_possible_host_change
      flash[:notice] = 'We are sorry but the record you requested no longer exists; possibly as a result of some data being edited. You will need to redo the search with the original criteria to obtain the updated version.'
      proceed = false
    rescue Mongoid::Errors::InvalidFind
      log_missing_document("entry for search record", @search_record[:id])
      flash[:notice] = 'We are sorry but the record you requested no longer exists; possibly as a result of some data being edited. You will need to redo the search with the original criteria to obtain the updated version.'
      proceed = false
    ensure
      return proceed
    end
  end

  def viewed
    session[:viewed] ||= []
  end

  # implementation of the citation generator
  def show_citation
    proceed = show_value_check
    if !proceed
      redirect_to new_search_query_path
      return
    else
      @printable_format = true
      @display_date = true
      @all_data = true
      @entry.display_fields(@search_record)
      @entry.acknowledge
      @place_id,@church_id,@register_id = @entry.get_location_ids
      @annotations = Annotation.find(@search_record[:annotation_ids]) if @search_record[:annotation_ids]
      @search_result = @search_query.search_result

      respond_to do |format|
        if params[:citation_type] == "wikitree"
          @viewed_date = Date.today.strftime("%e %b %Y")
          format.html {render "_search_records_freecen_citation_wikitree", :layout => false}
        elsif params[:citation_type] == "familytreemaker"
          @viewed_date = Date.today.strftime("%e %B %Y")
          format.html {render "_search_records_freecen_citation_familytreemaker", :layout => false}
          format.html {render "_search_records_freecen_citation_wikitree", :layout => false}
        elsif params[:citation_type] == "legacyfamilytree"
          @viewed_date = Date.today.strftime("%e %b %Y")
          format.html {render "_search_records_freecen_citation_legacyfamilytree", :layout => false}
        elsif params[:citation_type] == "mla"
          @viewed_date = Date.today.strftime("%a. %e %B. %Y")
          format.html {render "_search_records_freecen_citation_mla", :layout => false}
        elsif params[:citation_type] == "chicago"
          @viewed_date = Date.today.strftime("%B %e, %Y")
          format.html {render "_search_records_freecen_citation_chicago", :layout => false}
        elsif params[:citation_type] == "wikipedia"
          @viewed_date = Date.today.strftime("%e %b %Y")
          format.html {render "_search_records_freecen_citation_wikipedia", :layout => false}
        elsif params[:citation_type] == "evidenceexplained"
          @viewed_date = Date.today.strftime("%e %B %Y")
          format.html {render "_search_records_freecen_citation_evidenceexplained", :layout => false}
        end
      end
    end
  end
end
