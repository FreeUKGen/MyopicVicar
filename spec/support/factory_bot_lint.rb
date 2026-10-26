# FactoryBot linting
RSpec.configure do |config|
  # Run linting before the entire suite
  config.before(:suite) do
    FactoryBot.lint(
      traits: true,
      strategy: :build
    )
  rescue StandardError => e
    puts "\nFactoryBot Lint Error:"
    puts e.message
    exit(1) # fail fast
  end
end
