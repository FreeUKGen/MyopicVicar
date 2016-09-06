class TransregBatchesController < ApplicationController

  def list
    if session[:userid_detail_id].nil?
      render(:text => { "result" => "failure", "message" => "You are not authorised to use these facilities"}.to_xml({:root => 'list'}))
      return
    end

    @transcriber_id = params[:transcriber]
    @user = UseridDetail.where(:userid => @transcriber_id).first
    @batches = Freereg1CsvFile.where(:userid => @transcriber_id).all

    respond_to do |format|
      format.html
      format.xml
    end
  end

  def download
    @freereg1_csv_file = Freereg1CsvFile.id(params[:id]).first
    if  @freereg1_csv_file.present?
      ok_to_proceed = @freereg1_csv_file.check_file
      if !ok_to_proceed[0]
        render(:text => { "result" => "failure", "message" => "There is a problem with the file you are attempting to download. Contact a system administrator if you are concerned."}.to_xml({:root => 'download'}))
      else
        @freereg1_csv_file.backup_file
        my_file =  File.join(Rails.application.config.datafiles, @freereg1_csv_file.userid,@freereg1_csv_file.file_name)
        if File.file?(my_file)
          @freereg1_csv_file.update_attributes(:digest => Digest::MD5.file(my_file).hexdigest)
          @freereg1_csv_file.force_unlock
          send_file( my_file, :filename => @freereg1_csv_file.file_name,:x_sendfile=>true )
        end
      end
    else
      render(:text => { "result" => "failure", "message" => "The file has you are attempting to download does not exist"}.to_xml({:root => 'download'}))
    end
  end

end
