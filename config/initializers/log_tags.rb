# frozen_string_literal: true
#
# Tag every log line with the request id so the log tailer can join
# "Processing by X#y" to its "Completed ... in Nms" line. Required because
# Puma interleaves requests across threads.
#
# Set here rather than in config/environments/production.rb: config/initializers/*
# run during the railtie phase, and the middleware stack (which reads
# config.log_tags when constructing Rails::Rack::Logger) is built afterwards,
# in the finisher phase.
Rails.application.config.log_tags = [:request_id]
