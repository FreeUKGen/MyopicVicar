# frozen_string_literal: true

class Help

  TopLevelPages = {
    'search_help' => 'Search',
    'results_help' => 'View Results',
    'download_help' => 'Download and Share your results',
    'entry_help' => 'Entry Information',
    'certificates_help' => 'Order a Certificate',
    'explore_help' => 'Database',
    'tips_and_tricks' => 'Tips and Tricks',
    #    'more_help' => 'More Help'
  }

  AboutPages = {
    'about_changing' => 'Introducing the new FreeBMD web site',
    'about_freebmd' => 'About the FreeBMD project'
  }

  Search = {
    'intro' => 'Getting started',
    'freebmd_database' => 'The FreeBMD database',
    'data_fields' => 'Data fields',
    'search_strategy' => 'Search strategy'
  }

  MoreHelp = {
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

  Certificates = {
    'Ordering' => 'Ordering a Certificate',
    'GRO' =>  'About the GRO'
  }

  Downloading = {
    'Downloading' => 'Downloading Results',
    'Sharing' => 'Sharing Results'
  }

  MoreHelp = {
    'NewTopic' => 'New Topic',
    'AnotherTopic' => 'Another topic'
  }

  def self.create_island(island_hash, on_this_page = true, top_level = false)
    if on_this_page
      title = 'On this page'
      prefix = '#'
    else
      title = 'Help Pages'
      prefix = '/help/'
    end
    island = '<div class="grid__item two-fifths lap-one-third palm-one-whole float--right">'
    island += '<nav aria-labelledby="thisPage"><div class="islet islet--bordered">'
    island += '<h2 class="title-block" id="thisPage">'+title+'</h2><ul class="sub-nav">' unless top_level
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

  def self.create_help_menu(menu_hash, include_header = false)
    prefix = '/help/'
    menu = '<div class="grid__item two-fifths lap-one-third palm-one-whole float--right">'
    menu += '<nav aria-labelledby="thisPage"><div class="islet islet--bordered">'
    menu += '<h2 class="title-block" id="thisPage">Help Pages</h2>' if include_header
    menu += '<ul class="sub-nav">'
    menu_hash.each do |key, value|
      if value.is_a? String
        menu += '<li><a title="'+value+'" href="'+prefix+key+'">'+value+'</a></li>'
      end
    end
    menu += '</ul></div></nav></div>'
    menu.html_safe
  end

  def self.in_page_help_menu(menu_hash)
    prefix = '/help/'
    menu = '<div class="grid__item  one-third  lap-two-fifths  palm-one-whole  push-half--top float--right">'
    menu += '<div class="islet islet--bordered">'
    menu += '<h5 class="beta  text--teal" id="thisPage">On this page</h5>'
    menu += '<nav aria-labelledby="thisPage">'
    menu += '<ul class="sub-nav">'
    menu_hash.each do |key, value|
      if value.is_a? String
        menu += '<li><a class="reactive" data-section="'+key+'" title="search" data-method="get" href="'+prefix+key+'">'+value+'</a></li>'
      end
    end
    menu += '</ul>'
    menu += '</nav>'
    menu += '</div>'
    menu += '</div>'
    menu.html_safe
  end

end
