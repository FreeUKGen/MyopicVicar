desc "Apply the emendation rules"
task :apply_emendations, [:range, :verbose, :pretend] => :environment do |t,args|
  unless args.range
    print "Usage: rake apply_emendations[range,verbose,pretend]

    \trange can be 'all', or a numeric range of rules, e.g. '0-10'
    \tverbose can be blank or non-blank, which will print debugging information
    \tpretend will not actually transform records for non-blank values\n"
    exit
  end
  args.with_defaults(:range => nil, :verbose => nil, :pretend => nil)
  print "args[:range]=#{args[:range]}\targs[:verbose]=#{args[:verbose]}\targs[:pretend]=#{args[:pretend]}\n" if args[:verbose]
  
  rules = EmendationRule.all.asc(:original).to_a
  
  print "There are #{rules.count} emendation rules in total\n"
  
  if args[:range]
    # prune appropriately
    range_string = args[:range]
    range_array = range_string.split('-')
    rules = rules[range_array[0].to_i .. range_array[1].to_i]
  end
  rules.each do |rule|
    Emendor.apply_emendation(rule,args[:verbose],args[:pretend])    
  end 
 
end
