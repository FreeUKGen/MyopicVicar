# frozen_string_literal: true

# Shared setup for FreeREG search record display (show / citation / print) used from
# SearchRecordsController and Freereg1CsvEntriesController (entry-based URLs).
module FreeregSearchRecordShow
  extend ActiveSupport::Concern

  private

  def assign_ivars_for_freereg_search_record_show!
    @entry = @search_record.freereg1_csv_entry
    @record_name = @search_record.get_record_names
    @entry.display_fields(@search_record)
    proceed, @place_id, @church_id, @register_id, _extended_def = @entry.location_ids
    message = 'There is an issue with the linkages for this records. Please contact us using the Website Problem option to report this message'
    unless proceed
      redirect_back(fallback_location: new_search_query_path, notice: message)
      return false
    end

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
    true
  end
end
