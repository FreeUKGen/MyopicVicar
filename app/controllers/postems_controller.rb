class PostemsController < ApplicationController
  skip_before_action :require_login

  def create
  	@postem = Postem.new(postem_params.delete_if { |_k, v| v.blank? })
  	@record = BestGuessHash.where(Hash: postem_params[:Hash]).first.best_guess
  	@postem.QuarterNumberEvent = (@record.QuarterNumber * 3) + @record.RecordTypeID
  	@postem.RecordInfo = "#{@record.Surname}|#{@record.GivenName}|#{@record.AgeAtDeath}#{@record.AssociateName}|#{@record.District}|#{@record.Volume}|#{@record.Page}"
  	@postem.SourceInfo = request.remote_ip
  	if @postem.save
  		flash[:notice] = "Added Postem successfully"
  		redirect_to :back
  	else
  		flash[:notice] = "Unsuccessful. Please Retry"
  		redirect_to :back
  	end
  end
  private

  def postem_params
    params.require(:postem).permit!
  end
end