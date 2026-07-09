namespace :freeuk do
  desc 'Create Devise User rows from UseridDetail (for Refinery removal / native Devise)'
  task add_user: :environment do
    start_time = Time.now
    p "Starting at #{start_time}"
    added = 0
    skipped_existing = 0
    failures = []
    total = UseridDetail.count
    UseridDetail.no_timeout.each do |detail|
      if User.where(username: detail.userid).exists?
        skipped_existing += 1
        next
      end
      # Note: do not also set `password:` here - Devise's password= setter re-hashes
      # whatever it's given via the Freereg encryptor and overwrites encrypted_password,
      # which would double-hash `detail.password` (already a digest, not plaintext).
      u = User.new(
        username: detail.userid,
        email: detail.email_address,
        encrypted_password: detail.password,
        userid_detail_id: detail.id.to_s
      )
      if u.save
        added += 1
      else
        failures << [detail.userid, u.errors.full_messages.join(', ')]
      end
    end
    running_time = Time.now - start_time
    p "Running time #{running_time}"
    p "Added #{added}, skipped (already had User) #{skipped_existing}, failures #{failures.size}, UseridDetail documents #{total}"
    failures.first(20).each { |userid, msg| p "  FAILED #{userid.inspect}: #{msg}" }
    p "  ... #{failures.size - 20} more" if failures.size > 20
  end
end