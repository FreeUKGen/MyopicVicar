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
class EmendationTypesController < ApplicationController

  before_action :set_emendation_type, only: [:show, :edit, :update, :destroy]

  def index
    @emendation_types = EmendationType.all
  end

  def new
    @emendation_type = EmendationType.new
  end

  def show
    # The before_action automatically loads @emendation_type
  end

  def create
    @emendation_type = EmendationType.new(emendation_type_params)
    if @emendation_type.save
      redirect_to emendation_types_path, notice: 'Emendation type was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @emendation_type.update(emendation_type_params)
      redirect_to emendation_types_path, notice: 'Emendation type was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @emendation_type.destroy
    redirect_to emendation_types_path, notice: 'Emendation type was successfully destroyed.'
  end

  private

  def set_emendation_type
    @emendation_type = EmendationType.find(params[:id])
  end

  def emendation_type_params
    params.require(:emendation_type).permit(:name, :target_field, :origin)
  end

end
