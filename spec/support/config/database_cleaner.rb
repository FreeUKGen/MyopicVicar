require 'database_cleaner-mongoid'

RSpec.configure do |config|
  # 1. Set Mongoid's default cleaning strategy to "delete documents".
  # 2. Immediately remove all collections in the test MongoDB database.
  #
# Tests are isolated through `database_cleaner-mongoid` using document deletion. 
# Do not assume ActiveRecord transactional fixtures are responsible for cleaning Mongoid data.

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
