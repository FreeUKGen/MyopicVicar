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

# describes the role a name place in a record
module NameRole
  FATHER='f'
  MOTHER='m'
  HUSBAND='h'
  WIFE='w'
  GROOM='g'
  BRIDE='b'
  BRIDE_FATHER='bf'
  BRIDE_MOTHER='bm'
  GROOM_FATHER='gf'
  GROOM_MOTHER='gm'
  
  OPTIONS = {
    'Father' => FATHER,
    'Mother' => MOTHER,
    'Husband' => HUSBAND,
    'Wife' => WIFE,
    'Groom' => GROOM,
    'Bride' => BRIDE
  }    
  
  ALL_ROLES = [FATHER, MOTHER, HUSBAND, WIFE, GROOM, BRIDE, BRIDE_FATHER, BRIDE_MOTHER, GROOM_FATHER, GROOM_MOTHER]
end
