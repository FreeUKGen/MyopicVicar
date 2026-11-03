require 'yaml'

# Loads our own (trusted) YAML config files the same way on every Ruby version.
# Ruby 3.1+ (psych 4) made YAML.load/load_file safe by default, which rejects the aliases
# (<<: *default) and symbols these files use; the unsafe_ variants keep the old behaviour
# but don't exist on older Rubies.
module ConfigYaml
  def self.load_file(path)
    YAML.respond_to?(:unsafe_load_file) ? YAML.unsafe_load_file(path) : YAML.load_file(path)
  end

  def self.load(content)
    YAML.respond_to?(:unsafe_load) ? YAML.unsafe_load(content) : YAML.load(content)
  end
end
