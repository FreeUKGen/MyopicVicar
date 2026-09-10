# Run once per deployment environment.
# mongo_session_store + Mongoid::Timestamps set `updated_at` on every session write.
# A TTL on that field removes a document 7 *days after last activity* (idle expiry).
# https://www.mongodb.com/docs/manual/core/index-ttl/
#
#   bundle exec rake db:rails_sessions_ttl_index
#   DROP_OLD=1 bundle exec rake db:rails_sessions_ttl_index   # drop existing updated_at index then recreate

namespace :db do
  desc "Create TTL index on rails_sessions.updated_at (7 days idle, expire_after_seconds=604800)"
  task rails_sessions_ttl_index: :environment do
    name = MongoSessionStore.collection_name
    seconds = 7.days.to_i
    index_name = "rails_sessions_updated_at_ttl_7d"
    key = { updated_at: 1 }
    # Default Mongoid connection (where mongo_session_store writes); not related to the User model.
    collection = Mongoid::Clients.default[name]

    if ENV["DROP_OLD"].present?
      collection.indexes.each do |spec|
        k = spec["key"]
        next if spec["name"] == "_id_"
        next unless k == { "updated_at" => 1 } || k == { :updated_at => 1 } || (k.is_a?(Hash) && (k["updated_at"] == 1 || k[:updated_at] == 1))
        warn "Dropping index #{spec['name']}..."
        collection.indexes.drop_one(spec["name"])
      end
    end

    ttl_ok = false
    collection.indexes.each do |spec|
      k = spec["key"]
      next unless k.is_a?(Hash) && (k["updated_at"] == 1 || k[:updated_at] == 1)
      if spec["expireAfterSeconds"] == seconds
        ttl_ok = true
        puts "TTL index already present on #{name}.updated_at (#{seconds}s = 7 days idle)."
        break
      end
      if spec["expireAfterSeconds"] && spec["expireAfterSeconds"] != seconds
        warn "Index #{spec['name']} on updated_at has expireAfterSeconds=#{spec['expireAfterSeconds']}, want #{seconds}. Re-run with DROP_OLD=1."
        ttl_ok = true
        break
      end
    end

    unless ttl_ok
      begin
        collection.indexes.create_one(
          key,
          { name: index_name, expire_after_seconds: seconds, background: true }
        )
        puts "Created TTL index on #{name}.updated_at (expireAfterSeconds=#{seconds})."
      rescue StandardError => e
        if e.message.to_s =~ /already exists|IndexOptionsConflict|85|86/i
          warn e.message
          warn "To replace, run: DROP_OLD=1 bundle exec rake db:rails_sessions_ttl_index"
        else
          raise
        end
      end
    end
  end
end
