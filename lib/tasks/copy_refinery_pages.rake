# frozen_string_literal: true
namespace :refinery do
  desc "Copy Refinery CMS pages to in-app pages maintaining directory structure"
  desc "Usage: rake refinery:copy_pages_to_app[overwrite,site]"
  desc "  - 'overwrite': replace existing files"
  desc "  - 'site': 'freereg', 'freecen', or 'all' (default: current template_set)"
  task :copy_pages_to_app, [:overwrite, :site] => :environment do |t, args|
    require 'fileutils'
    # Helper methods
    def determine_file_path(page, target_base)
      # Use path if available, otherwise construct from slug hierarchy
      if page.path.present? && page.path != '/'
        # Remove leading slash and convert to file path
        relative_path = page.path.sub(/^\//, '')
        # Replace slashes with directory separators
        file_name = relative_path.gsub('/', File::SEPARATOR)
      else
        # Build path from page hierarchy
        slugs = []
        current_page = page
        while current_page
          slug = current_page.slug || current_page.title&.parameterize
          break if slug.blank?
          slugs.unshift(slug)
          current_page = current_page.parent
        end
        file_name = slugs.join(File::SEPARATOR)
      end
      
      # Ensure we have a valid file name
      if file_name.blank?
        file_name = page.slug || page.title&.parameterize || "page_#{page.id}"
      end
      
      # Add .html.erb extension
      file_name += '.html.erb' unless file_name.end_with?('.html.erb')
      
      # Return full path
      target_base.join(file_name)
    end
    
    def extract_page_content(page)
      # Get all page parts ordered by position
      page_parts = page.parts.order(:position)
      
      if page_parts.empty?
        # No page parts, return basic template
        return <<~ERB
          <h1><%= @page.title %></h1>
          <p>No content available.</p>
        ERB
      end
      
      # Build ERB content from page parts
      content_parts = []
      
      # Add page title as heading if first part doesn't have a title
      first_part = page_parts.first
      if first_part.title.blank? || first_part.title == 'Body'
        content_parts << "<h1><%= @page.title %></h1>"
      end
      
      # Process each page part
      page_parts.each do |part|
        part_body = part.body.to_s
        
        # Skip empty parts
        next if part_body.blank?
        
        # Add part title as heading if it's not "Body"
        if part.title.present? && part.title != 'Body'
          content_parts << "<h2>#{part.title}</h2>"
        end
        
        # Add part body - preserve ALL HTML including style tags, scripts, etc.
        # The body content is preserved exactly as stored in Refinery
        # This includes: 
        #   - <style scoped="scoped"> tags with CSS
        #   - Inline styles (style="...")
        #   - All HTML structure (divs, forms, images, links, etc.)
        #   - Scripts and any other HTML content
        # No escaping or modification is performed - content is written as-is
        content_parts << part_body
      end
      
      # Join all parts with line breaks
      # All HTML (including style tags) is preserved as-is
      content_parts.join("\n\n")
    end
    
    # Determine which site(s) to process
    site_arg = args[:site] || MyopicVicar::Application.config.template_set
    sites_to_process = case site_arg.to_s.downcase
                       when 'all'
                         ['freereg', 'freecen', 'freebmd']
                       when 'freereg', 'freecen', 'freebmd'
                         [site_arg.to_s.downcase]
                       else
                         # Default to current template_set
                         [MyopicVicar::Application.config.template_set]
                       end
    
    puts "Processing pages for site(s): #{sites_to_process.join(', ')}"
    puts "Current template_set: #{MyopicVicar::Application.config.template_set}"
    puts "=" * 80
    
    # Check if Refinery is available
    unless defined?(Refinery::Page)
      puts "ERROR: Refinery::Page is not available. Make sure Refinery CMS is installed."
      exit 1
    end
    
    total_copied = 0
    total_skipped = 0
    total_errors = 0
    
    # Process each site
    sites_to_process.each do |site|
      puts "\n" + "=" * 80
      puts "Processing #{site.upcase} pages..."
      puts "=" * 80
      
      # Target directory for in-app pages (organized by site)
      target_base = Rails.root.join('app', 'views', 'pages', site)
      
      # Ensure target directory exists
      FileUtils.mkdir_p(target_base) unless File.exist?(target_base)
      
      copied_count = 0
      skipped_count = 0
      error_count = 0
      
      # Get all Refinery pages, ordered by depth and lft to maintain hierarchy
      # Note: In a shared database, you may need to filter pages by site
      # This assumes all pages should be copied, but organized by site directory
      # If pages are site-specific in the database, add a where clause here
      pages = Refinery::Page.order(:depth, :lft).where(draft: false)
      
      if pages.empty?
        puts "No Refinery pages found to copy for #{site}."
        next
      end
      
      pages.each do |page|
      begin
        # Skip pages with link_url (external links)
        if page.link_url.present?
          puts "Skipping page '#{page.title}' (ID: #{page.id}) - has external link_url: #{page.link_url}"
          skipped_count += 1
          next
        end
        
        # Determine file path based on page path or slug
        file_path = determine_file_path(page, target_base)
        
        # Check if file already exists
        overwrite = args[:overwrite] == 'overwrite'
        file_exists = File.exist?(file_path)
        
        if file_exists && !overwrite
          puts "Skipping page '#{page.title}' (ID: #{page.id}) - file already exists: #{file_path}"
          puts "  (Use 'rake refinery:copy_pages_to_app[overwrite]' to overwrite existing files)"
          skipped_count += 1
          next
        end
        
        # Get page content from page parts
        content = extract_page_content(page)
        
        # Create directory if needed
        FileUtils.mkdir_p(File.dirname(file_path))
        
        # Write the ERB file
        File.write(file_path, content)
        
        action = file_exists ? "Overwrote" : "Copied"
        puts "#{action} page '#{page.title}' (ID: #{page.id}) -> #{file_path}"
        copied_count += 1
        
      rescue => e
        puts "ERROR copying page '#{page.title}' (ID: #{page.id}): #{e.message}"
        puts e.backtrace.first(3).join("\n")
        error_count += 1
      end
      end # pages.each
    end # sites_to_process.each
    
      puts "\n#{site.upcase} Summary:"
      puts "  Copied: #{copied_count} pages"
      puts "  Skipped: #{skipped_count} pages"
      puts "  Errors: #{error_count} pages"
      
      total_copied += copied_count
      total_skipped += skipped_count
      total_errors += error_count
    end
    
    puts "\n" + "=" * 80
    puts "Overall Summary:"
    puts "  Total Copied: #{total_copied} pages"
    puts "  Total Skipped: #{total_skipped} pages"
    puts "  Total Errors: #{total_errors} pages"
    puts "Done!"
  end
end


