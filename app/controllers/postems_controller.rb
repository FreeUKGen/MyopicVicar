class PostemsController < ApplicationController
  skip_before_action :require_login
  require 'rails_autolink'

  def create

  	@postem = Postem.new(postem_params.delete_if { |_k, v| v.blank? })
  	@record = BestGuessHash.where(Hash: postem_params[:Hash]).first.best_guess
    @search_query = SearchQuery.where(id: params[:search_query]).first
  	@postem.QuarterNumberEvent = (@record.QuarterNumber * 3) + @record.RecordTypeID
  	@postem.RecordInfo = "#{@record.Surname}|#{@record.GivenName}|#{@record.AgeAtDeath}#{@record.AssociateName}|#{@record.District}|#{@record.Volume}|#{@record.Page}"
  	@postem.SourceInfo = request.remote_ip
    @postem.Created = Time.now.strftime('%s')
  	if @postem.save
  		flash[:notice] = "Added Postem successfully"
  	else
  		flash[:notice] = "Unsuccessful. Please Retry"
  		redirect_to :back
  	end
    redirect_to friendly_bmd_record_details_path(@search_query.id,@record.RecordNumber, @record.friendly_url)
  end

  private

  def postem_params
    params.require(:postem).permit!
  end

end