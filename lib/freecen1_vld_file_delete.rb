class Freecen1VldFileDelete
  def self.run(vld_id, userid)
    new(vld_id, userid).run
  end

  def initialize(vld_id, userid)
    @vld_id = vld_id
    @userid = userid
    @start_time = Time.current
    @success = false
    @message = ''
    @file_name = ''
  end

  def run
    vldfile = Freecen1VldFile.where(_id: @vld_id).first
    unless vldfile
      @message = "VLD file id #{@vld_id} was not found (it may already have been deleted)."
      deliver_email
      return
    end

    @file_name = vldfile.file_name
    unless vldfile.dir_name.present? && vldfile.file_name.present?
      @message = "VLD file #{@file_name} is missing dir_name or file_name; deletion aborted."
      deliver_email
      return
    end

    dir_name = vldfile.dir_name
    file_name = vldfile.file_name
    loaded_date = vldfile.action.present? ? vldfile.u_at : ''
    freecen2_piece_id = nil

    logger.warn("FREECEN:VLD_DELETE: Starting delete for #{file_name} in #{dir_name} (id #{@vld_id})")
    Freecen1VldFile.delete_associated_records_for_vld_file!(vldfile)
    Freecen1VldFile.save_to_attic(dir_name, file_name)

    piece = vldfile.freecen_piece
    if piece.present?
      piece.update_attributes(num_dwellings: 0, num_individuals: 0, num_entries: 0, freecen1_filename: '', status: '', status_date: '')
      piece.freecen1_vld_files.delete(vldfile)
      freecen2_piece = piece.freecen2_piece
      freecen2_piece_id = freecen2_piece.id if freecen2_piece.present?
      freecen2_piece.freecen1_vld_files.delete(vldfile) if freecen2_piece.present?
      freecen2_piece.update_parts_status_on_file_deletion(vldfile, piece) if freecen2_piece.present?
      freecen2_place = vldfile.freecen2_place
      if freecen2_place.present?
        freecen2_place.freecen1_vld_files.delete(vldfile)
        freecen2_district = vldfile.freecen2_district
        freecen2_district.freecen1_vld_files.delete(vldfile) if freecen2_district.present?
        freecen2_place.update_data_present_after_vld_delete(freecen2_piece)
        Freecen2PlaceCache.refresh(freecen2_place.chapman_code)
      end
    end

    Freecen1VldFile.create_audit_record(vldfile, @userid, loaded_date, freecen2_piece_id)
    vldfile.delete

    elapsed = (Time.current - @start_time).round(2)
    @success = true
    @message = "The VLD file #{file_name} has been deleted successfully (#{elapsed} seconds)."
    logger.warn("FREECEN:VLD_DELETE: Completed #{file_name} in #{elapsed} seconds")
  rescue => e
    @message = "Deletion of VLD file #{@file_name.presence || @vld_id} failed: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}"
    logger.warn("FREECEN:VLD_DELETE: Failed #{@file_name}: #{e.message}")
    logger.warn(e.backtrace.inspect)
  ensure
    deliver_email
  end

  private

  def logger
    Rails.logger
  end

  def deliver_email
    user = UseridDetail.where(userid: @userid).first
    unless user
      logger.warn("FREECEN:VLD_DELETE: No email sent; userid #{@userid} not found")
      return
    end

    friendly_email = "#{user.person_forename} #{user.person_surname} <#{user.email_address}>"
    subject = if @success
                'FreeCEN: VLD file deletion completed'
              else
                'FreeCEN: VLD file deletion failed'
              end
    UserMailer.freecen_processing_report(friendly_email, subject, @message).deliver_now
  end
end
