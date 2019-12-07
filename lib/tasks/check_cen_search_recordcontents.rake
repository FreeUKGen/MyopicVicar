desc "Check content of certain cen search record contents"
task :check_cen_search_record_contents, [:limit] => :environment do |t, args|
  limit = args.limit.to_i
  file_for_warning_messages = 'log/check_cen_search_record_contents.log'
  FileUtils.mkdir_p(File.dirname(file_for_warning_messages))
  message_file = File.new(file_for_warning_messages, 'w')
  start = Time.now
  puts "Checking #{limit} documents for cen search record contents at #{start}"
  message_file.puts "Checking #{limit} documents for cen search record at #{start}"
  number_processed = 0
  occupation_1841 = []
  language_1841 = []
  disability_1841 = []
  marital_status_1841 = []
  sex_1841 = []
  occupation_1851 = []
  language_1851 = []
  disability_1851 = []
  marital_status_1851 = []
  sex_1851 = []
  occupation_1861 = []
  language_1861 = []
  disability_1861 = []
  marital_status_1861 = []
  sex_1861 = []
  occupation_1871 = []
  language_1871 = []
  disability_1871 = []
  marital_status_1871 = []
  sex_1871 = []
  occupation_1881 = []
  language_1881 = []
  disability_1881 = []
  marital_status_1881 = []
  sex_1881 = []
  occupation_1891 = []
  language_1891 = []
  disability_1891 = []
  marital_status_1891 = []
  sex_1891 = []
  FreecenIndividual.no_timeout.each do |individual|
    number_processed = number_processed + 1
    break if number_processed > limit

    case individual.search_record.record_type
    when '1841'
      occupation_1841 << individual.occupation unless individual.occupation.blank? || occupation_1841.include?(individual.occupation)
      language_1841 << individual.language unless individual.language.blank? || language_1841.include?(individual.language)
      marital_status_1841 << individual.marital_status unless individual.marital_status.blank? || marital_status_1841.include?(individual.marital_status)
      disability_1841 << individual.disability unless individual.disability.blank? || disability_1841.include?(individual.disability)
      sex_1841 << individual.sex unless individual.sex.blank? || sex_1841.include?(individual.sex)

    when '1851'
      occupation_1851 << individual.occupation unless individual.occupation.blank? || occupation_1851.include?(individual.occupation)
      language_1851 << individual.language unless individual.language.blank? || language_1851.include?(individual.language)
      marital_status_1851 << individual.marital_status unless individual.marital_status.blank?|| marital_status_1851.include?(individual.marital_status)
      disability_1851 << individual.disability unless individual.disability.blank? || disability_1851.include?(individual.disability)
      sex_1851 << individual.sex unless individual.sex.blank? || sex_1851.include?(individual.sex)

    when '1861'
      occupation_1861 << individual.occupation unless individual.occupation.blank? || occupation_1861.include?(individual.occupation)
      language_1861 << individual.language unless individual.language.blank? || language_1861.include?(individual.language)
      marital_status_1861 << individual.marital_status unless individual.marital_status.blank? || marital_status_1861.include?(individual.marital_status)
      disability_1861 << individual.disability unless individual.disability.blank? || disability_1861.include?(individual.disability)
      sex_1861 << individual.sex unless individual.sex.blank? || sex_1861.include?(individual.sex)

    when '1871'
      occupation_1871 << individual.occupation unless individual.occupation.blank? || occupation_1871.include?(individual.occupation)
      language_1871 << individual.language unless individual.language.blank? || language_1871.include?(individual.language)
      marital_status_1871 << individual.marital_status unless individual.marital_status.blank? || marital_status_1871.include?(individual.marital_status)
      disability_1871 << individual.disability unless individual.disability.blank? || disability_1871.include?(individual.disability)
      sex_1871 << individual.sex unless individual.sex.blank? || sex_1871.include?(individual.sex)

    when '1881'
      occupation_1881 << individual.occupation unless individual.occupation.blank? || occupation_1881.include?(individual.occupation)
      language_1881 << individual.language unless individual.language.blank? || language_1881.include?(individual.language)
      marital_status_1881 << individual.marital_status unless individual.marital_status.blank? || marital_status_1881.include?(individual.marital_status)
      disability_1881 << individual.disability unless individual.disability.blank? || disability_1881.include?(individual.disability)
      sex_1881 << individual.sex unless individual.sex.blank? || sex_1881.include?(individual.sex)

    when '1891'
      occupation_1891 << individual.occupation unless individual.occupation.blank? || occupation_1891.include?(individual.occupation)
      language_1891 << individual.language unless individual.language.blank? || language_1891.include?(individual.language)
      marital_status_1891 << individual.marital_status unless individual.marital_status.blank? || marital_status_1891.include?(individual.marital_status)
      disability_1891 << individual.disability unless individual.disability.blank? || disability_1891.include?(individual.disability)
      sex_1891 << individual.sex unless individual.sex.blank? || sex_1891.include?(individual.sex)
    end
  end
  time_processing = Time.now - start
  message_file.puts "checked  #{number_processed} records in #{time_processing}"
  p "checked  #{number_processed} records "
  message_file.puts '1841'
  message_file.puts "Occupations, #{occupation_1841} "
  message_file.puts "Language, #{language_1841}"
  message_file.puts "Marital status #{marital_status_1841}"
  message_file.puts "Disability #{disability_1841}"
  message_file.puts "Sex, #{sex_1841}"
  message_file.puts '1851'
  message_file.puts "Occupations, #{occupation_1851} "
  message_file.puts "Language, #{language_1851}"
  message_file.puts "Marital status #{marital_status_1851}"
  message_file.puts "Disability #{disability_1851}"
  message_file.puts "Sex, #{sex_1851}"
  message_file.puts '1861'
  message_file.puts "Occupations, #{occupation_1861} "
  message_file.puts "Language, #{language_1861}"
  message_file.puts "Marital status #{marital_status_1861}"
  message_file.puts "Disability #{disability_1861}"
  message_file.puts "Sex, #{sex_1861}"
  message_file.puts '1871'
  message_file.puts "Occupations, #{occupation_1871} "
  message_file.puts "Language, #{language_1871}"
  message_file.puts "Marital status #{marital_status_1871}"
  message_file.puts "Disability #{disability_1871}"
  message_file.puts "Sex, #{sex_1871}"
  message_file.puts '1881'
  message_file.puts "Occupations, #{occupation_1881} "
  message_file.puts "Language, #{language_1881}"
  message_file.puts "Marital status #{marital_status_1881}"
  message_file.puts "Disability #{disability_1881}"
  message_file.puts "Sex, #{sex_1881}"
  message_file.puts '1891'
  message_file.puts "Occupations, #{occupation_1891} "
  message_file.puts "Language, #{language_1891}"
  message_file.puts "Marital status #{marital_status_1891}"
  message_file.puts "Disability #{disability_1891}"
  message_file.puts "Sex, #{sex_1891}"
  message_file.close
end
