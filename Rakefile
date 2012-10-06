require 'mongo_mapper'
require 'securerandom'

task :env do
  mongo_url = ENV['MONGOHQ_URL']

  MongoMapper.connection = Mongo::Connection.from_uri mongo_url
  MongoMapper.database = URI.parse(mongo_url).path.gsub(/^\//, '')
  require './models'
end

task :add_new_auth_key => :env do
  key = SecureRandom.uuid
  AuthKey.create!(key: key)
  puts key
end