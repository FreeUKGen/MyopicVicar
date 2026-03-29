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
class EmendationRulesController < ApplicationController
  before_action :require_login, except: [:forename_abbreviations]
  before_action :set_emendation_rule, only: [:show, :edit, :update, :destroy]

  def index
    # Fetch rules, optionally filtered by type if passed in params
    if params[:emendation_type_id].present?
      rules = EmendationRule.where(emendation_type_id: params[:emendation_type_id])
    else
      rules = EmendationRule.all
    end

    # Sort and group logic for the A-Z view
    replacement_array = rules.distinct('replacement')
    @emendation_rules_grouped = EmendationRule.sort_by_initial_letter(replacement_array)
    @alphabet_keys = @emendation_rules_grouped.keys

    # Pre-fetch rules into a hash to avoid N+1 queries in the view
    @rules_by_replacement = rules.group_by(&:replacement)
  end

  def new
    @emendation_rule = EmendationRule.new
    @emendation_rule.emendation_type_id = params[:emendation_type_id] if params[:emendation_type_id]
  end

  def create
    @emendation_rule = EmendationRule.new(emendation_rule_params)
    if @emendation_rule.save
      redirect_to emendation_rules_path(anchor: @emendation_rule.replacement[0]), notice: 'Emendation rule was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @emendation_rule.update(emendation_rule_params)
      redirect_to emendation_rules_path(anchor: @emendation_rule.replacement[0]), notice: 'Emendation rule was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @emendation_rule.destroy
    redirect_to emendation_rules_path, notice: 'Emendation rule was successfully destroyed.'
  end

  # Public view mapping replacement names back to original abbreviations
  def forename_abbreviations
    # Address Inconsistency: optionally filter by emendation_type_id if provided
    base_query = params[:emendation_type_id].present? ? EmendationRule.where(emendation_type_id: params[:emendation_type_id]) : EmendationRule.all

    # Pluck only required fields to save memory (replacement and original)
    all_rules = base_query.pluck(:replacement, :original)

    # We build a Hash of Hashes: { "A" => { "Aaron" => ["Aron", "Aronus"], "Abel" => ["Abell"] } }
    grouped_rules = Hash.new { |hash, key| hash[key] = Hash.new { |h, k| h[k] = [] } }

    all_rules.each do |(replacement, original)|
      next if replacement.blank?
      initial_letter = replacement[0].upcase
      grouped_rules[initial_letter][replacement] << original
    end

    # Sort the outer hash (by letter), then sort the inner hashes (by replacement name)
    @emendation_rules = grouped_rules.sort.to_h.transform_values do |replacements_hash|
      replacements_hash.sort.to_h
    end

    @alphabet_keys = @emendation_rules.keys
  end

  private

  def set_emendation_rule
    @emendation_rule = EmendationRule.find(params[:id])
  end

  def emendation_rule_params
    params.require(:emendation_rule).permit(:original, :replacement, :gender, :emendation_type_id)
  end

end
