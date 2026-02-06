# frozen_string_literal: true

require 'set'

namespace :refinery do
  desc "Copy Refinery CMS resources (files) to site-specific assets directories"
  desc "Usage: rake refinery:copy_resources_to_assets[site,overwrite,copy_meta]"
  desc "  site: freereg, freecen, freebmd, or all (default: all)"
  desc "  overwrite: true to overwrite existing files (default: false)"
  desc "  copy_meta: true to copy .meta.yml files (default: true)"
  task :copy_resources_to_assets, [:site, :overwrite, :copy_meta] => :environment do |_t, args|
    # Try to access Refinery::Resource directly
    # This will trigger autoloading if the class exists
    begin
      resource_class = begin
        Refinery::Resources::Resource
      rescue NameError
        Refinery::Resource
      end
    rescue NameError => e
      puts "=" * 80
      puts "ERROR: Refinery::Resource is not available"
      puts "=" * 80
      puts "Error: #{e.message}"
      puts
      puts "This task requires Refinery CMS to be installed and configured."
      puts "Current Rails environment: #{Rails.env}"
      puts
      puts "To verify Refinery is available, try running in rails console:"
      puts "  rails c"
      puts "  Refinery::Resources::Resource.count  # or Refinery::Resource.count"
      puts
      exit 1
    end

    site_arg = args[:site] || 'all'
    overwrite = args[:overwrite] == 'true' || args[:overwrite] == true
    copy_meta = args[:copy_meta] != 'false' && args[:copy_meta] != false  # Default to true

    # Define valid sites (can be extended for any project)
    valid_sites = ['freereg', 'freecen', 'freebmd']
    
    # Determine which sites to process
    sites_to_process = case site_arg.downcase
                       when 'all'
                         valid_sites
                       else
                         if valid_sites.include?(site_arg.downcase)
                           [site_arg.downcase]
                         else
                           puts "ERROR: Invalid site argument '#{site_arg}'."
                           puts "Valid sites: #{valid_sites.join(', ')}, or 'all'"
                           exit 1
                         end
                       end

    puts "=" * 80
    puts "Copying Refinery Resources to Assets Directories"
    puts "=" * 80
    puts "Sites to process: #{sites_to_process.join(', ')}"
    puts "Overwrite existing: #{overwrite}"
    puts "Copy .meta.yml files: #{copy_meta}"
    puts "=" * 80
    puts

    # Base paths for assets
    assets_base = Rails.root.join('app')
    # Refinery stores resources in: public/system/refinery/resources/YYYY/MM/DD/filename.ext
    refinery_resources_base = Rails.root.join('public', 'system', 'refinery', 'resources')

    unless Dir.exist?(refinery_resources_base)
      puts "WARNING: Refinery resources directory not found: #{refinery_resources_base}"
      puts "Resources may be stored elsewhere or not yet uploaded."
      puts
    end

    # Track statistics - dynamically create for each site
    stats = {}
    sites_to_process.each do |site|
      stats[site.to_sym] = { copied: 0, skipped: 0, errors: 0, resources: [] }
    end

    # Helper method to safely sanitize filename
    def sanitize_filename(filename)
      return nil if filename.blank?
      # Remove any path components to prevent directory traversal
      sanitized = File.basename(filename.to_s)
      # Remove any remaining dangerous characters
      sanitized.gsub(/[^0-9A-Za-z._-]/, '_')
    end

    # Helper method to find resource file
    def find_resource_file(base_dir, resource, resource_name)
      return nil unless Dir.exist?(base_dir)

      # Get resource UID (Refinery uses file_uid)
      resource_uid = if resource.respond_to?(:file_uid)
                       resource.file_uid
                     elsif resource.respond_to?(:resource_uid)
                       resource.resource_uid
                     elsif resource.respond_to?(:uid)
                       resource.uid
                     else
                       nil
                     end

      # Strategy 1: Use created_at date to build path (most efficient and accurate)
      if resource.respond_to?(:created_at) && resource.created_at.present?
        date_path = resource.created_at.strftime('%Y/%m/%d')
        date_dir = base_dir.join(date_path)
        
        if Dir.exist?(date_dir)
          # Look for exact filename match first
          if resource_name.present?
            sanitized_name = sanitize_filename(resource_name)
            exact_path = date_dir.join(sanitized_name)
            return exact_path if File.exist?(exact_path)
          end
          
          # Look for files matching the pattern (uid_filename.ext)
          # Files are named like: {uid}_{original_filename}.ext
          if resource_uid.present?
            # Try exact UID match first
            uid_pattern = "#{resource_uid}_*"
            found = Dir.glob(date_dir.join(uid_pattern)).first
            return found if found && File.exist?(found) && !File.directory?(found)
          end
          
          # Fallback: case-insensitive partial match
          if resource_name.present?
            sanitized_name = sanitize_filename(resource_name)
            found = Dir.glob(date_dir.join('*')).find do |file|
              next if file.end_with?('.meta.yml') || file.end_with?('.meta') || File.directory?(file)
              basename = File.basename(file).downcase
              basename == sanitized_name.downcase || basename.include?(sanitized_name.downcase)
            end
            return found if found && File.exist?(found)
          end
        end
      end

      # Strategy 2: Search by UID in filename (more targeted than full recursive)
      if resource_uid.present?
        # Search only in date-based subdirectories (YYYY/MM/DD)
        date_dirs = Dir.glob(base_dir.join('*', '*', '*')).select { |d| File.directory?(d) }
        date_dirs.each do |date_dir|
          uid_pattern = "#{resource_uid}_*"
          found = Dir.glob(File.join(date_dir, uid_pattern)).first
          return found if found && File.exist?(found) && !File.directory?(found)
        end
      end

      # Strategy 3: Last resort - recursive search (slow, but only if other methods fail)
      if resource_name.present?
        sanitized_name = sanitize_filename(resource_name)
        # Limit search depth to prevent excessive scanning
        found = Dir.glob(base_dir.join('**', '*')).find do |file|
          next if file.end_with?('.meta.yml') || file.end_with?('.meta') || File.directory?(file)
          File.basename(file).downcase == sanitized_name.downcase
        end
        return found if found && File.exist?(found)
      end

      nil
    end

    # Helper method to extract original filename from UID-prefixed filename
    def extract_original_filename(filename, resource_uid)
      return filename unless filename.present? && resource_uid.present?
      
      # Sanitize inputs
      filename = sanitize_filename(filename)
      return filename unless filename && resource_uid
      
      # Files are named like: {uid}_{original_filename}.ext
      # Example: 2qksok5od_extended_burial_fields.csv
      # We want: extended_burial_fields.csv
      
      # Check if filename starts with UID followed by underscore
      uid_pattern = /^#{Regexp.escape(resource_uid)}_/
      if filename.match?(uid_pattern)
        return filename.sub(uid_pattern, '')
      end
      
      filename
    end

    # Helper method to copy resource file
    def copy_resource(resource, source_base, target_dir, overwrite, site, copy_meta, filename_tracker)
      # Get resource UID (Refinery uses file_uid)
      resource_uid = if resource.respond_to?(:file_uid)
                       resource.file_uid
                     elsif resource.respond_to?(:resource_uid)
                       resource.resource_uid
                     elsif resource.respond_to?(:uid)
                       resource.uid
                     else
                       nil
                     end

      return [false, nil, false] if resource_uid.blank?

      # Get resource filename (Refinery uses file_name)
      resource_name = if resource.respond_to?(:file_name)
                        resource.file_name
                      elsif resource.respond_to?(:resource_name)
                        resource.resource_name
                      elsif resource.respond_to?(:name)
                        resource.name
                      else
                        nil
                      end

      # Find the actual file on disk
      resource_file = find_resource_file(source_base, resource, resource_name)
      
      unless resource_file && File.exist?(resource_file)
        puts "  SKIP: Resource #{resource_uid} - file not found on disk"
        return [false, nil, false]
      end

      # Extract original filename (remove UID prefix) and sanitize
      original_filename = extract_original_filename(File.basename(resource_file), resource_uid)
      base_filename = sanitize_filename(original_filename) || sanitize_filename(File.basename(resource_file))
      
      return [false, nil, false] if base_filename.blank?
      
      # Determine target filename, handle duplicates
      target_filename = base_filename
      is_duplicate = false

      # Check for duplicate filenames
      if filename_tracker[target_filename.downcase].present?
        # If the exact UID is already copied, skip (e.g., if overwrite=false)
        if filename_tracker[target_filename.downcase].include?(resource_uid)
          puts "  SKIP: #{target_filename} (already copied for this UID)"
          return [false, target_filename, false]
        end

        # Make filename unique by adding date or UID
        is_duplicate = true
        ext = File.extname(base_filename)
        name_without_ext = File.basename(base_filename, ext)
        
        if resource.respond_to?(:created_at) && resource.created_at.present?
          date_str = resource.created_at.strftime('%Y-%m-%d')
          target_filename = "#{name_without_ext}_#{date_str}#{ext}"
        else
          uid_suffix = resource_uid[0..7] if resource_uid
          target_filename = "#{name_without_ext}_#{uid_suffix}#{ext}"
        end
        
        # Sanitize the new filename
        target_filename = sanitize_filename(target_filename)
        puts "  DUPLICATE: Renaming '#{base_filename}' to '#{target_filename}' to avoid collision."
      end
      
      # Add current resource to tracker
      filename_tracker[target_filename.downcase] ||= []
      filename_tracker[target_filename.downcase] << resource_uid

      # Ensure target_filename is safe (prevent path traversal)
      target_filename = sanitize_filename(target_filename)
      target_path = target_dir.join(target_filename)

      # Check if file already exists on disk (from previous run or manual copy)
      if File.exist?(target_path) && !overwrite
        puts "  SKIP: #{target_filename} (already exists on disk, use overwrite=true to replace)"
        return [false, target_filename, is_duplicate]
      end

      # Copy the resource file
      begin
        FileUtils.cp(resource_file, target_path)
        puts "  COPIED: #{target_filename} -> #{target_path}"
        
        # Copy .meta.yml file if requested and it exists
        if copy_meta
          meta_file = Pathname.new(resource_file).sub_ext('.meta.yml')
          if File.exist?(meta_file)
            meta_target = target_path.sub_ext('.meta.yml')
            FileUtils.cp(meta_file, meta_target)
            puts "  COPIED META: #{File.basename(meta_file)} -> #{File.basename(meta_target)}"
          end
        end
        
        [true, target_filename, is_duplicate]
      rescue => e
        puts "  ERROR copying #{target_filename}: #{e.message}"
        [false, target_filename, is_duplicate]
      end
    end

    # Get all Refinery resources from the current database
    begin
      # Use the resource_class we determined earlier
      all_resources = resource_class.all
      puts "Found #{all_resources.count} total Refinery resources in current database"
    rescue NoMethodError => e
      puts "ERROR: Cannot access Refinery::Resource.all: #{e.message}"
      puts "Current Rails environment: #{Rails.env}"
      exit 1
    rescue NameError => e
      puts "ERROR: Cannot access Refinery::Resource: #{e.message}"
      puts "Current Rails environment: #{Rails.env}"
      exit 1
    end

    sites_to_process.each do |site|
      puts "-" * 80
      puts "Processing #{site.upcase} resources..."
      puts "-" * 80

      target_dir = assets_base.join("assets_#{site}", 'resources')
      
      begin
        FileUtils.mkdir_p(target_dir) unless Dir.exist?(target_dir)
      rescue Errno::EACCES => e
        puts "ERROR: Permission denied creating directory: #{target_dir}"
        puts "Please check permissions or run with appropriate user privileges."
        stats[site.to_sym][:errors] += 1
        next
      end

      puts "Copying all #{all_resources.count} resources to #{target_dir}"
      puts

      # Track filenames to detect duplicates
      # Key: target filename, Value: array of resource UIDs using that filename
      filename_tracker = {}

      # Copy all resources from the current database to the specified site's directory
      all_resources.each do |resource|
        resource_uid = if resource.respond_to?(:file_uid)
                         resource.file_uid
                       elsif resource.respond_to?(:resource_uid)
                         resource.resource_uid
                       elsif resource.respond_to?(:uid)
                         resource.uid
                       else
                         nil
                       end
        
        next if resource_uid.blank?

        begin
          copied, target_filename, is_duplicate = copy_resource(
            resource, 
            refinery_resources_base, 
            target_dir, 
            overwrite, 
            site,
            copy_meta,
            filename_tracker
          )
          
          if copied
            stats[site.to_sym][:copied] += 1
            stats[site.to_sym][:resources] << (target_filename || resource_uid)
            
            if is_duplicate
              puts "    NOTE: Filename made unique due to duplicate: #{target_filename}"
            end
          else
            stats[site.to_sym][:skipped] += 1
          end
        rescue => e
          puts "  ERROR copying resource #{resource_uid}: #{e.message}"
          puts "  #{e.backtrace.first(3).join("\n  ")}"
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