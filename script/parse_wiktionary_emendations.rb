#!/usr/bin/env ruby
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
file = ARGV[0]
name = ARGV[1]

print "et = EmendationType.create!(:name => '#{name}', :target_field => :first_name)\n"

`grep " || " #{file}`.each_line do |line|
  if matchdata = /\|(?<text>\S+) \|\| \[\[(?<emendation>\w+)/.match(line)
#    p matchdata[:text]
#    p matchdata[:emendation]
    text = matchdata[:text].downcase
    text.gsub!(/<\/?sup>/, '')
    text.gsub!(/\./, '')
    emendation = matchdata[:emendation].downcase
    print "EmendationRule.create!(:source => '#{text}', :target => '#{emendation}', :emendation_type => et)\n"    
  end
end

#grep -v '|-' latin.ws.txt | sed -e "s/^|/{ :text => '/" | sed -e "s/\s*||\s*\[\[/', :emendation => '/" | sed -e "s/\]\].*/' }/"
