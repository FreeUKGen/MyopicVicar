# frozen_string_literal: true

class Help

  TopLevelPages = {
    'search' => 'Searching the FreeBMD database',
    'search_page' => 'The Search Page',
    'results_page' => 'The Results Page',
    'entry_page' => 'The Entry Page'
  }

  SearchHelp = {
    'intro' => 'Getting started',
    'freebmd_database' => 'The FreeBMD database',
    'data_fields' => 'Data fields',
    'search_strategy' => 'Search strategy'
  }

  SearchPage = {
    'Names' => 'Names',
    'Dates' => 'Dates',
    'RecordTypes' => 'Record Types',
    'Places' => 'Places',
    'VolumeAndPage' => 'Volume and Page',
    'MothersSurname' => 'Mothers Surname',
    'AgeAtDeath' => 'Age at Death',
    'SpouseName' => 'Spouse Name'
  }

  ResultsPage = {
    'ResultsTable' => 'Results Table',
    'SortingResults' => 'Sort Results',
    'ViewSearch' => 'View Search Criteria',
    'ReviseSearch' => 'Revise Search',
    'NewSearch' => 'New Search',
    'Print' => 'Print',
    'Download' => 'Download'
  }

  EntryPage = {
    'EntryTable' => 'Entry Table',
    'Districts' => 'Districts',
    'SpouseSurname' => 'Spouse Surname',
    'VolumeAndPage' => 'Volume and Page',
    'Postems' => 'Postems',
    'Scans' => 'Scans',
    'GenerateCitation' => 'Generate Citation',
    'Print' => 'Print'
  }

  def self.create_island(island_hash, on_this_page = true)
    if on_this_page
      title = 'On this page'
      prefix = '#'
    else
      title = 'Help Pages'
      prefix = '/help/'
    end
    island = '<div class="grid__item two-fifths lap-one-third palm-one-whole float--right">'
    island += '<nav aria-labelledby="thisPage"><div class="islet islet--bordered">'
    island += '<h2 class="title-block" id="thisPage">'+title+'</h2><ul class="sub-nav">'
    island_hash.each do |key, value|
      if value.is_a? Hash
        if value.key?('title')
          island += '<li><a href="'+prefix+key+'">'+value['title']+'</a></li>'
          if value.key?('subpages')
            island += '<ul class="push--left">'
            value['subpages'].each do |key, value|
              island += '<li><a href="'+prefix+key+'">'+value['title']+'</a></li>'
            end
            island += '</ul>'
          end
        end
      elsif value.is_a? String
        island += '<li><a href="'+prefix+key+'">'+value+'</a></li>'
      end
    end
    island += '</ul></div></nav></div>'
    island.html_safe
  end

end
