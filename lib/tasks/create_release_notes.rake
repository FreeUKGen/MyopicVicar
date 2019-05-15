
task :new_release_note do
  
  puts "Creating new release note"
  puts "..."

  git_log = `git log --since="two weeks ago" --no-merges --format=%B`
  git_log.gsub!(/^$\n/, '')
  git_log.gsub!(/^/, "* ") 
  
  current_time = DateTime.now 
  current_date = current_time.strftime "%Y-%m-%d"
  current_date_UK = current_time.strftime "%d-%m-%Y"
  
  if MyopicVicar::Application.config.template_set == 'freecen'
    template = "__FreeCEN2 | Release Notes__"
  else
    template = "__FreeREG | Release Notes__"
  end
  template += "
  =======================
  #{current_date_UK}

  __New Features__
  ----------------

  * None


  __Improvements__
  ----------------

  * None


  __Fixes__
  ---------

  * None


  __Change Log__
  ----------------

  Change log listing all commit messages for this release.


  #{git_log}
  "

  out_file = File.new("./doc/release_notes/release-notes-#{current_date}.md", "w")
  out_file.puts(template)

  if File.exist?(out_file) 
    puts "New release note generated successfully at /doc/release-notes/release-notes-#{current_date}.md"
  else 
    puts "Error - file not generated."
  end 
  
end


