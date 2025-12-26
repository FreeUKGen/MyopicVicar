# frozen_string_literal: true

require 'set'

namespace :refinery do
  desc "Copy Refinery CMS images to site-specific assets directories"
  desc "Usage: rake refinery:copy_images_to_assets[site,overwrite]"
  desc "  site: freereg, freecen, or all (default: all)"
  desc "  overwrite: true to overwrite existing files (default: false)"
  task :copy_images_to_assets, [:site, :overwrite] => :environment do |_t, args|
    begin
      # Check if Refinery is available
      unless defined?(Refinery::Image)
        puts "ERROR: Refinery::Image is not available. Is Refinery CMS installed?"
        exit 1
      end
    rescue NameError => e
      puts "ERROR: Refinery models not available: #{e.message}"
      puts "This task requires Refinery CMS to be installed and configured."
      exit 1
    end

    site_arg = args[:site] || 'all'
    overwrite = args[:overwrite] == 'true' || args[:overwrite] == true

    # Determine which sites to process
    sites_to_process = case site_arg.downcase
                       when 'freereg'
                         ['freereg']
                       when 'freecen'
                         ['freecen']
                       when 'all'
                         ['freereg', 'freecen']
                       else
                         puts "ERROR: Invalid site argument '#{site_arg}'. Use 'freereg', 'freecen', or 'all'"
                         exit 1
                       end

    puts "=" * 80
    puts "Copying Refinery Images to Assets Directories"
    puts "=" * 80
    puts "Sites to process: #{sites_to_process.join(', ')}"
    puts "Overwrite existing: #{overwrite}"
    puts "=" * 80
    puts

    # Base paths for assets
    assets_base = Rails.root.join('app')
    refinery_images_base = Rails.root.join('public', 'system', 'images')

    unless Dir.exist?(refinery_images_base)
      puts "WARNING: Refinery images directory not found: #{refinery_images_base}"
      puts "Images may be stored elsewhere or not yet uploaded."
      puts
    end

    # Track statistics
    stats = {
      freereg: { copied: 0, skipped: 0, errors: 0, images: [] },
      freecen: { copied: 0, skipped: 0, errors: 0, images: [] }
    }

    # Helper methods defined as local methods
    def get_site_pages(site)
      pages = Refinery::Page.all
      # Since both sites share the DB, we get all pages
      # Images will be associated based on which pages reference them
      pages
    end

    def find_referenced_images(pages, all_images)
      image_uids = Set.new

      pages.each do |page|
        # Get all page parts for this page
        page_parts = page.page_parts || []
        
        page_parts.each do |part|
          body = part.body
          next if body.blank?

          # Search for image references in various formats:
          # 1. /system/images/W1siZiIs.../filename.png?sha=...
          # 2. image_uid patterns
          # 3. Direct image references
          
          # Pattern 1: /system/images/.../filename
          body.scan(%r{/system/images/([^/]+)/}) do |match|
            image_uids.add(match[0])
          end

          # Pattern 2: Look for image_uid in URLs
          all_images.each do |image|
            next if image.image_uid.blank?
            
            # Check if image_uid appears in the content
            if body.include?(image.image_uid) || 
               body.include?("/system/images/#{image.image_uid}") ||
               (image.image_name && body.include?(image.image_name))
              image_uids.add(image.image_uid)
            end
          end

          # Pattern 3: Look for image names in content
          all_images.each do |image|
            next if image.image_name.blank?
            
            # Check for image name in img src attributes
            if body =~ /<img[^>]+src=["'][^"']*#{Regexp.escape(image.image_name)}/i
              image_uids.add(image.image_uid) if image.image_uid.present?
            end
          end
        end
      end

      image_uids.to_a
    end

    def find_image_file(base_dir, image_uid, image_name)
      return nil unless Dir.exist?(base_dir)

      # Try direct path: base_dir/image_uid/image_name
      if image_name.present?
        direct_path = base_dir.join(image_uid, image_name)
        return direct_path if File.exist?(direct_path)
      end

      # Search for files in the image_uid directory
      uid_dir = base_dir.join(image_uid)
      if Dir.exist?(uid_dir)
        files = Dir.glob(uid_dir.join('*'))
        # Return the first file found (Refinery typically stores one file per image_uid)
        return files.first if files.any?
      end

      # If image_name is provided, search more broadly
      if image_name.present?
        # Search recursively for the filename
        found = Dir.glob(base_dir.join('**', image_name)).first
        return found if found && File.exist?(found)
      end

      nil
    end

    def copy_image(image, source_base, target_dir, overwrite, site)
      return false if image.image_uid.blank?

      # Refinery stores images in a structure like: public/system/images/W1siZiIs.../filename.ext
      # The image_uid is typically a base64-encoded string that becomes part of the path
      image_uid = image.image_uid
      
      # Try to find the image file
      # Refinery typically stores files as: public/system/images/{image_uid}/{filename}
      # We need to search for the actual file
      image_file = find_image_file(source_base, image_uid, image.image_name)
      
      unless image_file && File.exist?(image_file)
        puts "  WARNING: Image file not found for UID: #{image_uid}"
        return false
      end

      # Determine target filename
      target_filename = image.image_name || File.basename(image_file)
      target_path = target_dir.join(target_filename)

      # Check if file already exists
      if File.exist?(target_path) && !overwrite
        puts "  SKIP: #{target_filename} (already exists, use overwrite=true to replace)"
        return false
      end

      # Copy the file
      begin
        FileUtils.cp(image_file, target_path)
        puts "  COPIED: #{target_filename} -> #{target_path}"
        true
      rescue => e
        puts "  ERROR copying #{target_filename}: #{e.message}"
        false
      end
    end

    sites_to_process.each do |site|
      puts "-" * 80
      puts "Processing #{site.upcase} images..."
      puts "-" * 80

      target_dir = assets_base.join("assets_#{site}", 'images')
      
      begin
        FileUtils.mkdir_p(target_dir) unless Dir.exist?(target_dir)
      rescue Errno::EACCES => e
        puts "ERROR: Permission denied creating directory: #{target_dir}"
        puts "Please check permissions or run with appropriate user privileges."
        stats[site.to_sym][:errors] += 1
        next
      end

      # Get all Refinery images
      all_images = Refinery::Image.all
      puts "Found #{all_images.count} total Refinery images in database"

      # Get pages for this site
      # Since both sites share the same DB, we'll search page content for image references
      # and determine site association based on page context
      site_pages = get_site_pages(site)
      puts "Found #{site_pages.count} pages for #{site}"

      # Find images referenced by pages for this site
      referenced_image_uids = find_referenced_images(site_pages, all_images)
      puts "Found #{referenced_image_uids.count} unique images referenced in #{site} pages"

      # Copy each referenced image
      referenced_image_uids.each do |image_uid|
        image = all_images.find { |img| img.image_uid == image_uid }
        next unless image

        begin
          copied = copy_image(image, refinery_images_base, target_dir, overwrite, site)
          if copied
            stats[site.to_sym][:copied] += 1
            stats[site.to_sym][:images] << (image.image_name || image_uid)
          else
            stats[site.to_sym][:skipped] += 1
          end
        rescue => e
          puts "  ERROR copying image #{image_uid}: #{e.message}"
          stats[site.to_sym][:errors] += 1
        end
      end

      puts
      puts "Summary for #{site.upcase}:"
      puts "  Copied: #{stats[site.to_sym][:copied]}"
      puts "  Skipped: #{stats[site.to_sym][:skipped]}"
      puts "  Errors: #{stats[site.to_sym][:errors]}"
      puts
    end

    # Final summary
    puts "=" * 80
    puts "FINAL SUMMARY"
    puts "=" * 80
    sites_to_process.each do |site|
      site_stats = stats[site.to_sym]
      puts "#{site.upcase}:"
      puts "  Copied: #{site_stats[:copied]}"
      puts "  Skipped: #{site_stats[:skipped]}"
      puts "  Errors: #{site_stats[:errors]}"
      puts
    end
    puts "=" * 80
  end
end



