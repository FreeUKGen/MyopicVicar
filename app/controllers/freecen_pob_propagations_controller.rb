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
class FreecenPobPropagationsController < ApplicationController

  def destroy
    @pob_propagation = FreecenPobPropagation.find(params[:id])
    redirect_back(fallback_location: { action: 'index' }, notice: 'The pob propagation was not found ') && return if @pob_propagation.blank?

    @pob_propagation.delete
    flash[:notice] = 'The destruction of the pob propagation was successful'
    redirect_to action: 'index'
  end

  def index
    get_user_info_from_userid
    if params[:county].present?
      @county = params[:county]
      @chapman_code = ChapmanCode.code_from_name(@county)
    else
      @chapman_code = session[:chapman_code]
      @county = session[:county]
    end
    @chapman_code_manage = session[:chapman_code]
    @county_manage = session[:county]

    if params[:commit] == 'Refresh'
      @index_chapman_code = params[:pob_propagations_index][:pob_index_county]
      @chapman_code = @index_chapman_code unless @index_chapman_code == 'index_county'
      @county = ChapmanCode.name_from_code(@chapman_code)
    end

    params[:sorted_by] = 'Most Recent Creation Date' if params[:sorted_by].blank?
    @sorted_by = params[:sorted_by]
    case @sorted_by
    when 'Most Recent Creation Date'
      @pob_propagations = FreecenPobPropagation.where(match_verbatim_birth_county: @chapman_code).order_by(c_at: -1)
    when 'Verbatim Birth Place'
      @pob_propagations = FreecenPobPropagation.where(match_verbatim_birth_county: @chapman_code).order_by(match_verbatim_birth_county: 1)
    end
  end

  def show
    @pob_propagation = FreecenPobPropagation.find(params[:id])
    redirect_back(fallback_location: { action: 'index' }, notice: 'The pob propagation was not found ') && return if @pob_propagation.blank?

    get_user_info_from_userid
    @chapman_code = @pob_propagation.match_verbatim_birth_county
    @county = ChapmanCode.name_from_code(@chapman_code)
  end

  private

  def freecen_pob_propagation_params
    params.require(:freecen_pob_propagation).permit!
  end
end
