
require "csv"

desc "Extracts toponyms from a set of files"
task :extract_freereg_csv_toponyms, [:pattern] => [:environment] do |t, args| 
  ChurchName.delete_all
  filenames = Dir.glob(args[:pattern])
  filenames.each do |fn|
#    p "Extracting toponyms from #{fn}\n"
    # get the filename
    standalone_filename = File.basename(fn)
    # get the user ID represented by the containing directory
    full_dirname = File.dirname(fn)
    parent_dirname = File.dirname(full_dirname)
    user_dirname = full_dirname.sub(parent_dirname, '').gsub(File::SEPARATOR, '')
    print "#{user_dirname}\t#{standalone_filename}\n"
    # TODO convert character sets as in freereg_csv_processor
    charset = "iso-8859-1"
    file = File.new(fn, "r" , external_encoding:charset , internal_encoding:"UTF-8")
    record = nil
      
    # skip the first five-ish lines
    while line = file.gets
      begin
        data = CSV.parse(line)[0]
        if data.size > 10
          chapman_code = data[0]
          parish = data[1]
          church = data[2]
          church.sub!(/\s+[AaBb][Tt]'?[Ss]?\s*$/, '') if church

#          print "#{standalone_filename},#{user_dirname},#{data[0]},#{data[1]},#{data[2]}\n"
          # optimize for the common case
          if record
            if record.chapman_code == chapman_code && record.parish == parish && record.church == church
#              p 'found the right record'
              record.entry_count = record.entry_count + 1
              record.save!
              next            
            else
#              p 'found the wrong record'
              record.save!
            end
          end
          # look for an existing church name first
          record = ChurchName.where({ :chapman_code => chapman_code, :parish => parish, :church => church}).first
          # check for this file within that record
          if record
#            print "found #{record}\n"
            unless record.files.include?({ 'filename' => standalone_filename, 'user' => user_dirname })
              record.files << { :filename => standalone_filename, :user => user_dirname }
            end
            record.entry_count = record.entry_count + 1
          else
            record = ChurchName.new
            record.chapman_code = chapman_code
            record.parish = parish
            record.church = church
            record.entry_count = 1
#            print "creating #{record}\n"
            record.files << { :filename => standalone_filename, :user => user_dirname }
          end
 #         print "preparing to save #{record.inspect}\n"
          record.save!
          # p record
          # 
        end
      rescue Exception => e  
        puts e.message  
        puts e.backtrace.inspect  
      end
    end
    # CSV.parse(line) do |data|
      # print "#{standalone_filename},#{user_dirname},#{data[0]},#{data[1]},#{data[2]}\n"
    # end



    
#    p "#{user_dirname}  #{standalone_filename}\n"
  end
  
  
end
