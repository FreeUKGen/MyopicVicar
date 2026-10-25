require 'database_cleaner-mongoid'

RSpec.configure do |config|
  # 1. Set Mongoid's default cleaning strategy to "delete documents".
  # 2. Immediately wipe all collections in the test database.
  #
  # ActiveRecord (MySQL/Refinery) is handled by RSpec's use_transactional_fixtures = true,
  # which wraps each test in a transaction and rolls back automatically,
  # removing test-created records while preserving pre-existing data.

  config.before(:suite) do
    DatabaseCleaner[:mongoid].strategy = :deletion
    DatabaseCleaner[:mongoid].clean_with(:deletion)
  end

  # --- Before each example ---
  config.before(:each) do
    DatabaseCleaner[:mongoid].start
  end

  # --- After each example ---
  config.after(:each) do
    DatabaseCleaner[:mongoid].clean
  end
end
