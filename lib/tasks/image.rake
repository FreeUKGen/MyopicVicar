namespace :image do
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

    message = Hash.new
    all_files,all_seq = Array.new,Array.new
    sources,sources_processed = 0,0
    prev_county,prev_place,prev_file_name = '','',''
    county_part,place_part,final_message = '','',''
    start_date,end_date = '',''
    file_num,file_name = '',''
    f = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
    email_message,email_message2,email_message3 = '','',''
    report_file.puts "Starting load of IS_pages for #{args.county} from #{counties}"

    File.open(input_file, "r") do |l|

      l.each_line do |line|
        line_parts = line.strip.split("/")
        county_part = line_parts[0] unless line_parts[0].nil?
        place_part = line_parts[1] unless line_parts[1].nil?

        if counties.include?(county_part)
          case line_parts.count
            when 1
#              puts "line_parts_count=1: "+line
            when 2
              place,church,register_type,notes = ''
              place,church,register_type,notes = FreeregAids.extract_location(place_part)

              place,church,register,final_message,status,church_status,register_status = FreeregAids.check_and_get_location(county_part,place,church,register_type,place_part)

              if status == true
                f[county_part][place_part]['status'] = register_status == 'R4A' ? 'u' : 't'
              else 
                f[county_part][place_part]['status'] = 'e'
              end

              f[county_part][place_part]['church_status'] = church_status.present? ? church_status : ''
              f[county_part][place_part]['register_status'] = register_status.present? ? register_status : ''
              f[county_part][place_part]['place'] = place
              f[county_part][place_part]['church'] = church
              f[county_part][place_part]['register'] = register
              f[county_part][place_part]['notes'] = notes
            when 3
              sources = sources.to_i + 1

              ind = line.rindex(/[^\d]+([\d]+[a-zA-Z]*)[\.]/)
              if ind.blank?
                next
              else
                file_seq = $1
                file_name = line.slice(0...ind).split('/')[2]

                if f[county_part][place_part]['status'] != 'e'
                  if all_files.include?(file_name) == false
                    f[county_part][place_part]['file_name'] = file_name
                    all_files << file_name.to_s

                    prev_start_date = start_date
                    prev_end_date = end_date
                    if prev_file_name.empty?
                      prev_file_name = file_name 
                      prev_county = county_part
                      prev_place = place_part
                    end

                    range_ind = file_name.rindex(/(-\d{4}-\d{4})/)
                    start_date = range_ind.present? ? file_name.slice((range_ind+1)..(range_ind+4)) : ''
                    end_date = range_ind.present? ? file_name.slice((range_ind+6)..(range_ind+9)) : ''
                  end
                end

                if prev_file_name == file_name
                  if all_seq.any? {|h| h[:seq] == file_seq} == false
                    all_seq << {:seq => file_seq, :status => 'reserved'}
                  end
                else
                  if ['u','t'].include?(f[prev_county][prev_place]['status'])
p "status1="+f[prev_county][prev_place]['status'].to_s+" church="+f[prev_county][prev_place]['church_status'].to_s+" register="+f[prev_county][prev_place]['register_status'].to_s+" place="+f[prev_county][prev_place]['place'].place_name.to_s+" church="+f[prev_county][prev_place]['church'].church_name.to_s+" register="+f[prev_county][prev_place]['register'].register_type.to_s+" file="+prev_file_name.to_s

                    update_collection(f[prev_county][prev_place],prev_file_name,prev_start_date,prev_end_date,all_seq) 
                  end

                  prev_county = county_part.to_s
                  prev_place = place_part.to_s
                  prev_file_name = file_name.to_s
                  all_seq = [{:seq => file_seq, :status => 'reserved'}]
                end
                sources_processed = sources_processed.to_i + 1
              end
            else 
              # we have a page for a known place church and register
              #we could now store the image location in page_image
              # p line
          end
        end
      end
    end

    if ['u','t'].include?(f[county_part][place_part]['status'])
p "status3="+f[county_part][place_part]['status'].to_s+" church="+f[county_part][place_part]['church_status'].to_s+" register="+f[county_part][place_part]['register_status'].to_s+" place="+f[county_part][place_part]['place'].place_name.to_s+" church="+f[county_part][place_part]['church'].church_name.to_s+" register="+f[county_part][place_part]['register'].register_type.to_s+" file="+file_name.to_s

      update_collection(f[county_part][place_part],file_name,start_date,end_date,all_seq)
    end

    report_file.puts email_message
    report_file.puts "Total sources #{sources} with #{sources_processed} processed"
  end

  def self.update_collection(f,group_name,start_date,end_date,all_seq)
    source = Source.where(:register_id=>f['register'].id, :source_name=>'Image Server').first
    source = create_source(f['register'],f['notes']) if source.nil?

    is_group = create_image_server_group(source,group_name,f['status'],start_date,end_date,f['church_status'],f['register_status'])
    
    update_image_server_image(is_group,group_name,start_date,end_date,all_seq)
  end

  def self.create_source(register,notes)
    source = Source.new(:register_id=>register.id)
    source.source_name = "Image Server"
    source.notes = notes
    source.start_date = source.register.datemin
    source.end_date = source.register.datemax

    source.save
    register.sources << source
    register.save

    source
  end

  def self.create_image_server_group(source,group_name,status,start_date,end_date,church_status,register_status)
    image_server_group = ImageServerGroup.where(:source_id=>source.id, :group_name=>group_name).first

    if image_server_group.nil?
      image_server_group = ImageServerGroup.new(:source_id=>source.id)
      image_server_group.group_name = group_name
      image_server_group.status = status
      image_server_group.start_date = start_date
      image_server_group.end_date = end_date
      image_server_group.church_status = church_status
      image_server_group.register_status = register_status
      image_server_group.consistency = true if church_status == 'GOOD' && register_status == 'GOOD'

      image_server_group.save
      source.image_server_groups << image_server_group
      source.save
    else
#      add image_server_group.update here
    end

    image_server_group
  end

  def self.update_image_server_image(is_group,image_set,start_date,end_date,seq)
    if is_group.present?
      rd,new_seq = Array.new,Array.new
      image_server_image = ImageServerImage.where(:image_server_group_id=>is_group.id).first

      if image_server_image.nil?
        seq.each do |f|
          rd << {:image_server_group_id=>is_group.id, :image_set=>image_set, :seq=>f[:seq], :start_date=>start_date, :end_date=>end_date}
        end
        image_server_image = ImageServerImage.create! (rd)
      else
p "==============NEED UPDATE NOT INSERT"
p "file="+image_set.to_s
        seq.each do |f|
          new_seq << f[:seq]
        end
        exist_seq = ImageServerImage.where(:image_server_group_id=>is_group.id).distinct(:seq)
        diff_seq = new_seq - exist_seq
p "diff_seq="+diff_seq.to_s

        if not diff_seq.empty?
          diff_seq.each do |f|
            rd << {:image_server_group_id=>is_group.id, :image_set=>image_set, :seq=>f, :start_date=>start_date, :end_date=>end_date}
          end
          image_server_image = ImageServerImage.create! (rd)
        end
      end
      is_group.image_server_images << image_server_image
      is_group.save
    else
    p "ERROR: no image_server_group document for image_server_image"
    end
  end

end
