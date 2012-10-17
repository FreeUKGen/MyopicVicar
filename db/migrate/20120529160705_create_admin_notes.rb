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
class CreateAdminNotes < ActiveRecord::Migration
  def self.up
    create_table :admin_notes do |t|
      t.string :resource_id, :null => false
      t.string :resource_type, :null => false
      t.references :admin_user, :polymorphic => true
      t.text :body
      t.timestamps
    end
    add_index :admin_notes, [:resource_type, :resource_id]
    add_index :admin_notes, [:admin_user_type, :admin_user_id]
  end

  def self.down
    drop_table :admin_notes
  end
end
