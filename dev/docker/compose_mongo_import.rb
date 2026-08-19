#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'mongo'
require 'time'

database = ARGV.fetch(0)
collection_name = ARGV.fetch(1)
file_path = ARGV.fetch(2)
host = ENV.fetch('MONGO_HOST', 'mongo')
port = ENV.fetch('MONGO_PORT', '27017')

def convert_extended_json(value)
  case value
  when Array
    value.map { |item| convert_extended_json(item) }
  when Hash
    return BSON::ObjectId.from_string(value['$oid']) if value.keys == ['$oid']
    return Time.parse(value['$date']).utc if value.keys == ['$date']

    value.transform_values { |item| convert_extended_json(item) }
  else
    value
  end
end

client = Mongo::Client.new(["#{host}:#{port}"], database: database)
collection = client[collection_name]

count = 0
File.foreach(file_path) do |line|
  next if line.strip.empty?

  collection.insert_one(convert_extended_json(JSON.parse(line)))
  count += 1
end

puts "Imported #{count} documents into #{database}.#{collection_name}"
