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

    def find_referenced_image_uids(pages)
      image_uids = Set.new
      image_names = Set.new

      pages.each do |page|
        # Get all page parts for this page
        page_parts = page.page_parts || []
        
        page_parts.each do |part|
          body = part.body
          next if body.blank?

          # Pattern 1: Extract image_uid from /system/images/{image_uid}/filename URLs
          # Matches: /system/images/W1siZiIs.../filename.png?sha=...
          # This is the most reliable pattern - only matches actual image URLs
          body.scan(%r{/system/images/([^/]+)/}) do |match|
            uid = match[0]
            # Validate: Refinery image_uids are typically base64-like strings
            # They usually start with specific patterns and are 20+ characters
            if uid.length >= 20 && uid.match?(/\A[A-Za-z0-9+/]+\z/)
              image_uids.add(uid)
            end
          end

          # Pattern 2: Extract image names from img src attributes
          # Matches: <img src="/system/images/.../filename.png" ...>
          body.scan(/<img[^>]+src=["']([^"']+)["']/i) do |url_match|
            url = url_match[0]
            # Extract filename from URL
            if url =~ %r{/system/images/[^/]+/([^/?]+)}
              filename = $1
              # Only add if it looks like an image filename
              if filename.match?(/\.(jpg|jpeg|png|gif|svg|webp|bmp|ico)$/i)
                image_names.add(filename)
              end
            end
          end
        end
      end

      [image_uids.to_a, image_names.to_a]
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

      # Only search recursively if we have an image_name and no direct match
      # This is safer than searching all files
      if image_name.present?
        # Search recursively for the filename, but prefer exact matches
        found = Dir.glob(base_dir.join('**', image_name)).first
        # Verify it's actually in an image_uid directory structure
        if found && File.exist?(found)
          # Check if path contains an image_uid-like directory
          path_parts = found.to_s.split(File::SEPARATOR)
          if path_parts.any? { |part| part.length >= 20 && part.match?(/\A[A-Za-z0-9+/]+\z/) }
            return found
          end
        end
      end

      nil
    end

    def copy_image(image, source_base, target_dir, overwrite, site)
      return false if image.image_uid.blank?

      image_uid = image.image_uid
      image_file = find_image_file(source_base, image_uid, image.image_name)
      
      unless image_file && File.exist?(image_file)
        puts "  WARNING: Image file not found for UID: #{image_uid}"
        return false
      end

      # Determine target filename - sanitize to prevent path traversal
      target_filename = image.image_name || File.basename(image_file)
      # Remove any path components to prevent directory traversal
      target_filename = File.basename(target_filename)
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

      # Get pages for this site
      site_pages = get_site_pages(site)
      puts "Found #{site_pages.count} pages for #{site}"

      # STEP 1: Scan pages to find referenced image_uids (without loading all images)
      puts "Scanning page content for image references..."
      referenced_image_uids, referenced_image_names = find_referenced_image_uids(site_pages)
      puts "Found #{referenced_image_uids.count} unique image UIDs and #{referenced_image_names.count} image names in page content"

      # STEP 2: Query database only for referenced images
      if referenced_image_uids.empty? && referenced_image_names.empty?
        puts "No image references found in pages. Skipping image copy."
        puts
        next
      end

      puts "Querying database for referenced images..."
      
      # Check if Refinery uses ActiveRecord or Mongoid
      # Try ActiveRecord syntax first (most common for Refinery)
      begin
        # ActiveRecord syntax
        images_by_uid = if referenced_image_uids.any?
          Refinery::Image.where(image_uid: referenced_image_uids).to_a
        else
          []
        end

        images_by_name = if referenced_image_names.any?
          Refinery::Image.where(image_name: referenced_image_names).to_a
        else
          []
        end
      rescue => e
        # Fallback: try Mongoid syntax if ActiveRecord fails
        puts "  Trying alternative query syntax..."
        images_by_uid = if referenced_image_uids.any?
          Refinery::Image.where(:image_uid.in => referenced_image_uids).to_a
        else
          []
        end

        images_by_name = if referenced_image_names.any?
          Refinery::Image.where(:image_name.in => referenced_image_names).to_a
        else
          []
        end
      end

      # Combine and deduplicate
      all_referenced_images = (images_by_uid + images_by_name).uniq { |img| img.id }
      puts "Found #{all_referenced_images.count} matching images in database"

      # STEP 3: Copy only the referenced images
      if all_referenced_images.empty?
        puts "No matching images found in database. Skipping copy."
        puts
        next
      end

      puts "Copying #{all_referenced_images.count} images..."
      all_referenced_images.each do |image|
        begin
          copied = copy_image(image, refinery_images_base, target_dir, overwrite, site)
          if copied
            stats[site.to_sym][:copied] += 1
            stats[site.to_sym][:images] << (image.image_name || image.image_uid)
          else
            stats[site.to_sym][:skipped] += 1
          end
        rescue => e
          puts "  ERROR copying image #{image.image_uid}: #{e.message}"
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