# frozen_string_literal: true

require 'set'

namespace :refinery do
  desc "Copy Refinery CMS images to site-specific assets directories"
  desc "Usage: rake refinery:copy_images_to_assets[site,overwrite]"
  desc "  site: freereg, freecen, or all (default: all)"
  desc "  overwrite: true to overwrite existing files (default: false)"
  task :copy_images_to_assets, [:site, :overwrite] => :environment do |_t, args|
    begin
      # Check if Refinery is available by trying to access the class
      # This will trigger autoloading if the class exists
      Refinery::Image
    rescue NameError => e
      puts "ERROR: Refinery::Image is not available. Is Refinery CMS installed?"
      puts "Error: #{e.message}"
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
    refinery_images_base = Rails.root.join('public', 'system', 'refinery', 'images')

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
    def find_image_file(base_dir, image_uid, image_name)
      return nil unless Dir.exist?(base_dir)

      # Check if image_uid is a date-based path (contains slashes)
      if image_uid.include?('/')
        # image_uid is a path like "2014/09/07/16_04_06_544_alphabet.jpg"
        # Try direct path: base_dir/image_uid
        direct_path = base_dir.join(image_uid)
        return direct_path if File.exist?(direct_path)

        # If image_name is provided and different from the filename in image_uid,
        # try replacing the filename
        if image_name.present?
          path_parts = image_uid.split('/')
          path_parts[-1] = image_name
          alternative_path = base_dir.join(path_parts.join('/'))
          return alternative_path if File.exist?(alternative_path)
        end
      else
        # image_uid is a base64-like string (old format)
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
      end

      # Only search recursively if we have an image_name and no direct match
      # This is safer than searching all files
      if image_name.present?
        # Search recursively for the filename, but prefer exact matches
        found = Dir.glob(base_dir.join('**', image_name)).first
        # Verify it's actually in an image_uid directory structure
        if found && File.exist?(found)
          # Check if path contains an image_uid-like directory or date-based path
          path_parts = found.to_s.split(File::SEPARATOR)
          # Accept if it's in a date-based directory structure (YYYY/MM/DD) or has long UID-like parts
          if path_parts.any? { |part| part.length >= 20 && part.match?(/\A[A-Za-z0-9+\/]+\z/) } ||
             found.to_s.match?(%r{/\d{4}/\d{2}/\d{2}/})
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

      # Get ALL images from Refinery database
      puts "Querying database for all Refinery images..."
      
      # Check if Refinery uses ActiveRecord or Mongoid
      begin
        # Try ActiveRecord syntax first (most common for Refinery)
        all_images = Refinery::Image.all.to_a
      rescue => e
        # Fallback: try Mongoid syntax if ActiveRecord fails
        puts "  Trying alternative query syntax..."
        begin
          all_images = Refinery::Image.all.to_a
        rescue => e2
          puts "ERROR: Could not query Refinery::Image: #{e2.message}"
          stats[site.to_sym][:errors] += 1
          next
        end
      end

      total_images = all_images.count
      puts "Found #{total_images} total images in Refinery database"

      if total_images == 0
        puts "No images found in database. Skipping copy."
        puts
        next
      end

      # Copy all images
      puts "Copying #{total_images} images..."
      all_images.each_with_index do |image, index|
        begin
          copied = copy_image(image, refinery_images_base, target_dir, overwrite, site)
          if copied
            stats[site.to_sym][:copied] += 1
            stats[site.to_sym][:images] << (image.image_name || image.image_uid)
          else
            stats[site.to_sym][:skipped] += 1
          end
          
          # Progress indicator for large batches
          if (index + 1) % 100 == 0
            puts "  Progress: #{index + 1}/#{total_images} images processed..."
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