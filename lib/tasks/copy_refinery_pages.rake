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
      # Get the page slug (downcased for URL consistency)
      page_slug = (page.slug || page.title&.parameterize || "page_#{page.id}").to_s.downcase
      
      # Check if this page has children
      # Use children_count first (counter cache, fast), fallback to children.any? if needed
      has_children = if page.respond_to?(:children_count)
                       page.children_count.to_i > 0
                     elsif page.respond_to?(:children)
                       page.children.any?
                     else
                       false
                     end
      
      # Build directory structure based on hierarchy
      if page.parent.present?
        # This is a child page - build path from parent hierarchy
        parent_dirs = []
        current_parent = page.parent
        
        # Build parent directory path by traversing up the hierarchy
        while current_parent
          parent_slug = (current_parent.slug || current_parent.title&.parameterize).to_s.downcase
          break if parent_slug.blank?
          
          # Check if this parent has children (if so, it should be a directory)
          parent_has_children = if current_parent.respond_to?(:children_count)
                                   current_parent.children_count.to_i > 0
                                 elsif current_parent.respond_to?(:children)
                                   current_parent.children.any?
                                 else
                                   false
                                 end
          
          if parent_has_children
            # Parent has children, so it should be a directory
            parent_dirs.unshift(parent_slug)
          end
          
          current_parent = current_parent.parent
        end
        
        # Build the file path: parent directories + current page
        # If current page has children, it also needs its own subdirectory
        if parent_dirs.any?
          # Create nested directory structure
          dir_path = parent_dirs.join(File::SEPARATOR)
          if has_children
            # This page has children, so create a subdirectory for it
            file_name = "#{dir_path}#{File::SEPARATOR}#{page_slug}#{File::SEPARATOR}#{page_slug}.html.erb"
          else
            # No children, just put it in the parent directory
            file_name = "#{dir_path}#{File::SEPARATOR}#{page_slug}.html.erb"
          end
        else
          # No parent directories, but check if this page has children
          if has_children
            file_name = "#{page_slug}#{File::SEPARATOR}#{page_slug}.html.erb"
          else
            file_name = "#{page_slug}.html.erb"
          end
        end
      else
        # This is a top-level page
        if has_children
          # For top-level pages with children, create the page at root level
          # so /information-for-coordinators works directly
          # Child pages will go in the subdirectory: information-for-coordinators/child-page.html.erb
          file_name = "#{page_slug}.html.erb"
        else
          # No children, just a regular file
          file_name = "#{page_slug}.html.erb"
        end
      end
      
      # Return full path
      target_base.join(file_name)
    end
    
    def extract_page_content(page)
      # Get all page parts ordered by position
      page_parts = page.parts.order(:position)
      
      # Helper to escape HTML in titles
      def escape_html(text)
        text.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;').gsub("'", '&#39;')
      end
      
      if page_parts.empty?
        # No page parts, return basic template with actual page title
        page_title = page.title || page.menu_title || 'Untitled Page'
        escaped_title = escape_html(page_title)
        return <<~ERB
          <h1>#{escaped_title}</h1>
          <p>No content available.</p>
        ERB
      end
      
      # Build ERB content from page parts
      content_parts = []
      
      # Add page title as heading if first part doesn't have a title
      first_part = page_parts.first
      if first_part.title.blank? || first_part.title == 'Body'
        # Use actual page title from Refinery, not a dynamic reference
        page_title = page.title || page.menu_title || 'Untitled Page'
        escaped_title = escape_html(page_title)
        content_parts << "<h1>#{escaped_title}</h1>"
      end
      
      # Process each page part - only add parts that have content
      page_parts.each do |part|
        part_body = part.body.to_s
        
        # Check if part has meaningful content
        # Strip HTML tags to check for actual text content
        text_content = part_body.gsub(/<[^>]*>/, '').strip
        # Check if there are any non-empty HTML elements (like images, iframes, etc.)
        has_meaningful_html = part_body.match?(/<(img|iframe|object|embed|video|audio|canvas|svg)[^>]*>/i)
        
        # Skip if no text content and no meaningful HTML elements
        # This will skip parts with only empty HTML tags or whitespace
        next if text_content.blank? && !has_meaningful_html
        
        # Only add part title as heading if part has content and it's not "Body"
        if part.title.present? && part.title != 'Body'
          escaped_part_title = escape_html(part.title)
          content_parts << "<h2>#{escaped_part_title}</h2>"
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
    
    # Note: We don't check for Refinery::Page here because it may not be loaded yet
    # The actual usage will happen later and will raise a clear error if it's not available
    
    total_copied = 0
    total_skipped = 0
    total_errors = 0
    
    # Process each site
    sites_to_process.each do |site|
      puts "\n" + "=" * 80
      puts "Processing #{site.upcase} pages..."
      puts "=" * 80
      
      # Initialize counters
      copied_count = 0
      skipped_count = 0
      error_count = 0
      
      # Target directory for in-app pages (organized by site)
      target_base = Rails.root.join('app', 'views', 'pages', site)
      
      # Ensure target directory exists
      begin
        FileUtils.mkdir_p(target_base) unless File.exist?(target_base)
      rescue Errno::EACCES => e
        puts "ERROR: Permission denied when creating directory: #{target_base}"
        puts ""
        puts "The current user does not have write permissions to create this directory."
        puts ""
        puts "Solutions:"
        puts "  1. Check directory permissions: ls -ld #{target_base.parent}"
        puts "  2. Create the directory manually with appropriate permissions:"
        puts "     sudo mkdir -p #{target_base}"
        puts "     sudo chown -R $(whoami) #{target_base.parent}"
        puts "  3. Run the rake task with a user that has write permissions"
        puts ""
        puts "Error: #{e.message}"
        error_count = 1  # Mark this site as having an error
        total_errors += 1
        puts "\n#{site.upcase} Summary:"
        puts "  Copied: #{copied_count} pages"
        puts "  Skipped: #{skipped_count} pages"
        puts "  Errors: #{error_count} pages"
        next
      rescue => e
        puts "ERROR: Unable to create directory #{target_base}: #{e.message}"
        puts e.backtrace.first(3).join("\n")
        error_count = 1  # Mark this site as having an error
        total_errors += 1
        puts "\n#{site.upcase} Summary:"
        puts "  Copied: #{copied_count} pages"
        puts "  Skipped: #{skipped_count} pages"
        puts "  Errors: #{error_count} pages"
        next
      end
      
      # Get all Refinery pages, ordered by depth to maintain hierarchy
      begin
        pages = Refinery::Page.order(:depth, :lft).where(draft: false)
      rescue NameError => e
        puts "ERROR: Refinery::Page is not available."
        puts ""
        puts "Current environment: #{Rails.env}"
        puts "Error: #{e.message}"
        puts ""
        puts "If Refinery::Page works in 'rails c', try:"
        puts "  RAILS_ENV=#{Rails.env} rake refinery:copy_pages_to_app[overwrite,#{site}]"
        puts ""
        error_count += 1
        next
      end
      
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


