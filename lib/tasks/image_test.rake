namespace :image_test do
  require 'freereg_aids'


  desc "load the image file names from a listing created by rsync from the image server."
  # rake image:load_pages[limit,county,file_name] --trace
  # limit is the number of pages to be retrieved
  # county is the chapman_code for the county to be processed. ALL is all counties
  # file is the name of the file containing the image file_names
  task :load_pages, [:county,:file] => [:environment] do |t, args|
    file_for_output = "#{Rails.root}/log/loading_pages.log"
    file_for_warning_messages = "#{Rails.root}/log/warning_loading_pages.log"
    file_for_report = "#{Rails.root}/log/report_loading_pages.log"

    FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
    FileUtils.mkdir_p(File.dirname(file_for_report))
    FileUtils.mkdir_p(File.dirname(file_for_output))

    warning_file = File.new(file_for_warning_messages, "w")
    output_file = File.new(file_for_output, "w")
    report_file = File.new(file_for_report, "w")
    input_file = File.join(Rails.root,'test_data','image_dirs',args.file)

    counties = Array.new
    args.county == "ALL" ? counties = ChapmanCode.merge_counties : counties[0] = args.county

    report_file.puts "Starting load of pages for #{args.county} from #{counties}"
    lines, sources, sources_processed = 0
    county_part,place_part,final_message = ''
    @folder = Hash.new
    message = {}
    email_message = "SUMMARY OF CHECK PLACE BETWEEEN DATA ON IS AND FR\r\n\r\n\r\n"

    File.open(input_file, "r") do |f|
      all_files = []
      f.each_line do |line|
        line_parts = line.strip.split("/")
        county_part = line_parts[0] unless line_parts[0].nil?
        place_part = line_parts[1] unless line_parts[1].nil?

        case line_parts.count
          when 1
#            puts "line_parts_count=1: "+line
          when 2
            if counties.include?(county_part)
              place,church,register_type,notes = ''
              place,church,register_type,notes = FreeregAids.extract_location(place_part)
              @folder[county_part[place_part]] = 0

              place,church,register,final_message,final_success = FreeregAids.check_and_get_location(county_part,place,church,register_type)
              @folder[county_part[place_part]] = final_success ? 1 : 0
              if final_message.present?
                final_message.each do |k1,v1|
                  if k1.present? && v1.present?
                    v1.each do |k2,v2|
                      if k2.present? && v2.present?
                        v2.each do |k3,v3|
                          if message[k1].nil?
                            message[k1] = final_message[k1]
                          else 
                            if message[k1][k2].nil?
                              message[k1][k2] = final_message[k1][k2]
                            else
                              message[k1][k2] = message[k1][k2].merge({k3 => v3}) unless v3.nil? || k3.nil?
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          when 3
=begin
            if counties.include?(county_part) 
              sources = sources + 1
              case @folder[county_part[place_part]]
                when 0
                  return
                else
                  if @folder[county_part][place_part].nil?
                    place,church,register_type,notes = ''
                    place,church,register_type,notes = FreeregAids.extract_location(place_part)
                    folder[county_part][place_part] = 0
              
#                    output_file.puts "#{county_part},#{place},#{church},#{register_type},#{notes}"
#                    report_file.puts "#{county_part},#{place},#{church},#{register_type},#{notes}"
              
                    place,church,register,final_message,final_success = FreeregAids.check_and_get_location(county_part,place,church,register_type)
                    folder[county_part][place_part] = final_success ? 1 : 0
             
                    email_message = email_message.to_s + final_message.to_s unless final_message.nil?
#                    output_file.puts "finish location check"
#                    output_file.puts "#{place.inspect}, #{church.inspect}, #{register.inspect}"
#                    output_file.puts final_message
#                    report_file.puts final_message
             
                    return if @folder[county_part[place_part]] == 0
                  end

                  file_name = line_parts[2].scan(/^[\D]*/).join('')
                  if all_files.nil?
                    all_files << file_name 
                  else
                    if all_files.include?(file_name) == false
                      all_files << file_name.to_s
                      email_message = email_message.to_s + county_part+"/"+place_part+"/"+file_name+"======="+all_files.size.to_s+"\r\n"
                    end
                  end
                  sources_processed = sources_processed + 1
                else
              end
            end
=end            
          else 
            lines = lines + 1
            # we have a page for a known place church and register
            #we could now store the image location in page_image
            # p line
            output_file.puts line
        end
      end
    end
#   email_message = email_message.to_s + final_message.to_s unless final_message.nil?
    if message.present?
      x = Hash[ message.sort_by{|k,v| k}]
      x.each do |k1,v1|
        v1.each do |k2,v2|
          v2.each do |k3,v3|
p "k1="+k1.to_s+"  k2="+k2.to_s+"  k3="+k3.to_s           
              email_message = email_message.to_s + v3.to_s unless v3.nil?
          end
        end
      end
    end
    UserMailer.send_IS_error(email_message,'test1298test@gmail.com').deliver_now
    report_file.puts email_message
    report_file.puts "Total sources #{sources} with #{sources_processed} processed"
  end
end
