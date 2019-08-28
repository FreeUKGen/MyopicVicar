class Freecen1FixedDatFilesController < ApplicationController
  def show
    if params[:id].present?
      @freecen1_fixed_dat_file = Freecen1FixedDatFile.find(params[:id])
    else
      redirect_back(fallback_location: new_manage_resource_path, notice: 'The linkages were incorrect') && return if @freecen1_fixed_dat_entry.blank?
    end
  end
end
