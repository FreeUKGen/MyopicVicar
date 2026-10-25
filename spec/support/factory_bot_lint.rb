# FactoryBot linting
RSpec.configure do |config|
  # Run linting before the entire suite
  config.before(:suite) do
    begin
      FactoryBot.lint(
        traits: true,
        strategy: :build
      )
    rescue => e
      puts "\nFactoryBot Lint Error:"
      puts e.message
      exit(1)   # fail fast
    end
  end
end
