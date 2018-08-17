
task :new_release_note do
  
  puts "Creating new release note"
  puts "..."

  git_log = `git log --since="two weeks ago" --no-merges --format=%B`
  git_log.gsub!(/^$\n/, '')
  git_log.gsub!(/^/, "* ") 
  
  current_time = DateTime.now 
  current_date = current_time.strftime "%Y-%m-%d"
  current_date_UK = current_time.strftime "%d-%m-%Y"
  
  template = "__FreeREG | Release Notes__
  =======================
  #{current_date_UK}

  __New Features__
  ----------------

  * -


  __Improvements__
  ----------------

  * -


  __Fixes__
  ---------

  * -


  __Change Log__
  ----------------

  Detailed release notes below, listing all commit messages for this release.


  #{git_log}
  "

  out_file = File.new("./doc/release_notes/release_notes-#{current_date}.md", "w")
  out_file.puts(template)

  if File.exist?(out_file) 
    puts "New release note generated successfully at /doc/release-notes/release-notes-#{current_date}.md"
  else 
    puts "Error - file not generated."
  end 
  
end


