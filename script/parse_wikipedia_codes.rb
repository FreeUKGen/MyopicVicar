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
#!/usr/bin/env ruby
File.foreach(ARGV[0]) do |line|
  if line =~ /\*(\w\w\w) \[\[(.+)\]\]/
#    print "code=\1, title=\2\n"
    captures = $~.captures
    code=captures[0]
    text=captures[1]
    if text =~ /(.+)\|(.+)/
      captures = $~.captures
      # check for wikipedia pipe syntax
      text=captures[1]      
    end
    print "'#{text}' => '#{code}',\n"
  end
end