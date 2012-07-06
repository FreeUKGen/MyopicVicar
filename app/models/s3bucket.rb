class S3bucket
  require 'set'
  
  include MongoMapper::Document     
  
  key :name, String
  key :prefixes, Array
  
  def directories
    # return the cached version
   return self.prefixes if self.prefixes && self.prefixes.size > 0
    
    # get the bucket
    c = Fog::Storage.new(:provider => 'AWS')
    
    set = Set.new

    # cycle through each key
    c.directories.get(self.name).files.all.each do |f|
      # add the stem to the set
      dir = File.dirname(f.key)
      set.add(dir)
    end
    # save the items
    self.prefixes = set.to_a
    # save the whole thing
    save!
    self.prefixes
  end
  
  private
  
  def self.dir_from_key(key) 
    File.join(File.dirname(key), '')
  end
  
end
