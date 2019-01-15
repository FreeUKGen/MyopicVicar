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
  skip_before_action :require_login
  def index
    @emendation_rules = EmendationRule.sort_by_initial_letter(EmendationRule.distinct('replacement'))
    @alphabet_keys = @emendation_rules.keys
  end

end
