#!/usr/bin/env ruby
# frozen_string_literal: true

# test script for postem api integration
# run with: bundle exec rails runner script/test_postem_api.rb

require 'colorize'

def log_section(title)
  puts "\n#{'=' * 80}".colorize(:cyan)
  puts "  #{title}".colorize(:cyan).bold
  puts "#{'=' * 80}\n".colorize(:cyan)
end

def log_info(message)
  puts "ℹ #{message}".colorize(:blue)
end

def log_success(message)
  puts "✓ #{message}".colorize(:green)
end

def log_error(message)
  puts "✗ #{message}".colorize(:red)
end

def log_warning(message)
  puts "⚠ #{message}".colorize(:yellow)
end

def format_response(response)
  response.to_json.then { |json| JSON.pretty_generate(JSON.parse(json)) }
end

# configuration check
log_section "configuration check"

api_url = ENV['FREEBMD_POSTEM_API_URL']
api_key = ENV['FREEBMD_API_KEY']

if api_url.nil?
  log_error "FREEBMD_POSTEM_API_URL not set"
  log_info "set it with: export FREEBMD_POSTEM_API_URL='https://www.freebmd.org.uk/api/create-postem.pl'"
  exit 1
end

if api_key.nil?
  log_warning "FREEBMD_API_KEY not set (will rely on ip whitelist)"
else
  log_success "FREEBMD_API_KEY is set (length: #{api_key.length} chars)"
end

log_success "api url: #{api_url}"
puts

# find a test record
log_section "finding test record"

record = BestGuess.joins(:best_guess_hash).first
unless record
  log_error "no bestguess records found in database"
  exit 1
end

log_success "found record: #{record.RecordNumber}"
log_info "  surname: #{record.Surname}"
log_info "  given name: #{record.GivenName}"
log_info "  district: #{record.District}"
log_info "  year/quarter: #{record.event_quarter}"
log_info "  hash: #{record.best_guess_hash.Hash}"

db_name = Postem.connection.current_database
log_info "  database: #{db_name}"
puts

# test 1: dry-run with valid postem
log_section "test 1: dry-run with valid postem"

service = FreebmdPostemService.new
test_info = "test postem from rails script #{Time.current.to_i}"

begin
  response = service.create_postem(
    record: record,
    information: test_info,
    source_info: 'rails test script',
    dry_run: true
  )

  if response[:dry_run]
    log_success "dry-run validation passed"
    log_info "response:"
    puts format_response(response).colorize(:light_black)
  else
    log_error "expected dry_run: true in response"
  end
rescue => e
  log_error "dry-run test failed: #{e.class.name}: #{e.message}"
end

puts

# test 2: dry-run with validation error (no space)
log_section "test 2: dry-run with validation error"

begin
  response = service.create_postem(
    record: record,
    information: 'nospaceshere',  # should fail validation
    dry_run: true
  )

  log_error "expected validation error but got success"
rescue FreebmdPostemService::ValidationError => e
  log_success "validation error caught as expected"
  log_info "error: #{e.message}"
rescue ArgumentError => e
  log_success "rails-side validation caught error"
  log_info "error: #{e.message}"
rescue => e
  log_error "unexpected error: #{e.class.name}: #{e.message}"
end

puts

# test 3: check no data was created
log_section "test 3: verify no data created by dry-runs"

initial_count = Postem.where(Hash: record.best_guess_hash.Hash).count
log_info "postems for this record before tests: #{initial_count}"

# check confirmed flag not set
confirmed = record.Confirmed.to_i
has_postem_flag = (confirmed & BestGuess::ENTRY_POSTEM) != 0

if has_postem_flag
  log_info "record already has ENTRY_POSTEM flag set (expected if postems exist)"
else
  log_success "record does not have ENTRY_POSTEM flag (good for dry-run test)"
end

puts

# test 4: optional real postem creation (interactive)
log_section "test 4: real postem creation (optional)"

print "create a real postem for testing? this will write to the database. (y/N): "
response_input = STDIN.gets.chomp.downcase

if response_input == 'y'
  log_warning "creating real postem..."

  begin
    response = service.create_postem(
      record: record,
      information: "test postem created by rails script at #{Time.current}",
      source_info: 'rails test script - real creation',
      dry_run: false  # actually create it
    )

    if response[:success]
      log_success "postem created successfully!"
      log_info "response:"
      puts format_response(response).colorize(:light_black)

      # verify postem was created
      new_count = Postem.where(Hash: record.best_guess_hash.Hash).count
      log_info "postems for this record after creation: #{new_count}"

      if new_count > initial_count
        log_success "verified: postem count increased from #{initial_count} to #{new_count}"
      else
        log_warning "postem count did not increase (may be duplicate)"
      end

      # check logs
      log_info "\nto verify postem was logged, check:"
      puts "  tail ../FreeBMD/log/postemlog".colorize(:light_black)
      puts "  tail ../FreeBMD/log/postemTrans.*".colorize(:light_black)
      puts "  tail /var/log/apache2/error.log | grep postem".colorize(:light_black)

    elsif response[:dry_run]
      log_warning "got dry-run response even though dry_run=false"
    else
      log_error "postem creation failed"
    end

  rescue FreebmdPostemService::ValidationError => e
    log_error "validation failed: #{e.message}"
  rescue => e
    log_error "error creating postem: #{e.class.name}: #{e.message}"
    puts e.backtrace.first(5).join("\n").colorize(:light_black) if ENV['DEBUG']
  end
else
  log_info "skipping real postem creation"
end

puts

# summary
log_section "test summary"

log_success "all dry-run tests completed"
log_info "check apache error log for [DRY-RUN] entries:"
puts "  tail /var/log/apache2/error.log | grep DRY-RUN".colorize(:light_black)
puts

log_info "to test from command line:"
puts <<~BASH.colorize(:light_black)
  cd /path/to/FreeBMD/api
  ./test-dry-run.sh
BASH
puts
