source "https://rubygems.org"

plugin 'bundler-inject', '~> 1.1'
require File.join(Bundler::Plugin.index.load_paths("bundler-inject")[0], "bundler-inject") rescue nil
$LOAD_PATH.push(File.expand_path("lib", __dir__))

gem "cloudwatchlogger",   "~> 0.2"
gem "manageiq-loggers",   "~> 0.4.2"
gem "manageiq-messaging", "~> 0.1.2"
gem "optimist"
gem "rake",               "~> 13.0.0"
gem "rest-client",        "~>2.0"
gem "sources-api-client", "~> 1.0"

group :test, :development do
  gem "rspec"
  gem 'rubocop', '~>0.69.0', :require => false
  gem 'rubocop-performance', '~>1.3',    :require => false
  gem 'simplecov', '= 0.17.1'
  gem "webmock"
end
