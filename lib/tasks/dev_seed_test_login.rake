namespace :dev do
  desc "Create/update a local UseridDetail + User so USERID/PASSWORD (default testuser4/testuser4) " \
       "can log in on THIS machine, no matter what our_secret_key bin/setup generated here. " \
       "Usage: rake dev:seed_test_login[testuser4,testuser4]"
  task :seed_test_login, [:userid, :password] => :environment do |_t, args|
    # Safety: this creates an account with a well-known, guessable password.
    # Never let it touch anything but a local development database.
    real_hosts = %w[
      https://www.freereg.org.uk https://www.freecen.org.uk https://www.freebmd2.org.uk
      https://test.freereg.org.uk https://dev.freereg.org.uk
      https://test.freecen.org.uk https://dev.freebmd.org.uk
      https://test.freebmd2.org.uk https://dev.freebmd2.org.uk
    ]
    unless Rails.env.development? && !real_hosts.include?(Rails.application.config.website)
      abort "Refusing to run dev:seed_test_login outside local development " \
            "(Rails.env=#{Rails.env}, website=#{Rails.application.config.website})."
    end

    userid = args.userid.presence || 'testuser4'
    password = args.password.presence || userid

    # Digest computed with THIS machine's current our_secret_key (config/mongo_config.yml),
    # so it always matches whatever bin/setup generated here - see Freereg.digest in
    # config/initializers/devise.rb. A digest computed elsewhere (e.g. imported from a
    # mentor's collections.zip) would only match if our_secret_key happens to be identical.
    digest = Devise::Encryptable::Encryptors::Freereg.digest(password, nil, nil, nil)

    detail = UseridDetail.where(userid: userid).first
    if detail.nil?
      detail = UseridDetail.new(
        userid: userid,
        syndicate: 'Norfolk',
        email_address: "#{userid}@example.invalid",
        person_role: 'technical',
        person_surname: 'Test',
        person_forename: userid.capitalize,
        skill_level: 'Unspecified',
        active: true,
        transcription_agreement: true,
        technical_agreement: true,
        research_agreement: true,
        volunteer_induction_handbook: '1',
        code_of_conduct: '1',
        volunteer_policy: '1'
      )
    end
    detail.password = digest
    detail.password_confirmation = digest
    detail.save!

    # Do not also set `password=` here - Devise's setter re-hashes whatever it's given
    # via the Freereg encryptor, which would double-hash our already-computed digest.
    user = User.where(username: userid).first || User.new(username: userid)
    user.email = detail.email_address
    user.userid_detail_id = detail.id.to_s
    user.encrypted_password = digest
    user.save!

    puts "#{userid} / #{password} ready to log in on this machine."
  end
end
