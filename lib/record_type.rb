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
# limitations under the License.
#
module RecordType

  BURIAL = 'bu'
  MARRIAGE = 'ma'
  BAPTISM = 'ba'

  CENSUS_1841 = '1841'
  CENSUS_1851 = '1851'
  CENSUS_1861 = '1861'
  CENSUS_1871 = '1871'
  CENSUS_1881 = '1881'
  CENSUS_1891 = '1891'
  CENSUS_1901 = '1901'
  CENSUS_1911 = '1911'

  PROBATE = 'Probate'
  ADMINISTRATION = 'Administration'
  CONFIRMATION = 'Confirmation'

  def self.all_types
    case MyopicVicar::Application.config.template_set
    when 'freereg'
      all_types = RecordType::ALL_FREEREG_TYPES
    when 'freecen'
      all_types = RecordType::ALL_FREECEN_TYPES
    when 'freebmd'
      all_types = RecordType::ALL_FREEREG_TYPES
    when 'freepro'
      all_types = RecordType::ALL_FREEPRO_TYPES
    end
    all_types
  end

  def self.options
    if MyopicVicar::Application.config.template_set == MyopicVicar::TemplateSet::FREEREG
      FREEREG_OPTIONS
    else
      FREECEN_OPTIONS
    end
  end

  def self.display_name(value)
    # binding.pry
    self.options.key(value)
  end

  ALL_FREEREG_TYPES = [BURIAL, MARRIAGE, BAPTISM].freeze
  ALL_FREECEN_TYPES = [CENSUS_1841, CENSUS_1851, CENSUS_1861, CENSUS_1871, CENSUS_1881, CENSUS_1891, CENSUS_1901, CENSUS_1911].freeze
  ALL_FREEPRO_TYPES = [PROBATE, ADMINISTRATION, CONFIRMATION].freeze

  private
  FREEREG_OPTIONS = {
    'Baptism' => BAPTISM,
    'Marriage' => MARRIAGE,
    'Burial' => BURIAL
  }

  FREECEN_OPTIONS = ALL_FREECEN_TYPES.inject({}) do |accum, value|
    accum[value] = value
    accum
  end

  FREEPRO_OPTIONS = {
    'Probate' => PROBATE,
    'Administration' => ADMINISTRATION,
    'Confirmation' => CONFIRMATION
  }
end
