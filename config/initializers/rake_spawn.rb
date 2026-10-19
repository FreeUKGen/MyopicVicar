# lib/ is on $LOAD_PATH but not autoloaded, so make RakeSpawn available everywhere.
require Rails.root.join('lib', 'rake_spawn').to_s
