desc 'Merge duplicate registers (same church and register type). Dry run unless mode is apply, e.g. rake merge_duplicate_registers[apply,SOM,10]'
task :merge_duplicate_registers, [:mode, :chapman_code, :limit] => [:environment] do |_t, args|
  apply = args.mode == 'apply'
  p "Starting duplicate register #{apply ? 'merge' : 'dry run'}"
  report = DuplicateRegisterMerger.new(apply: apply, chapman_code: args.chapman_code.presence, limit: args.limit).run
  p "Finished; report written to #{report}"
end
