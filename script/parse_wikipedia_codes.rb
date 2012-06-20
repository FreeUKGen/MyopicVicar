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