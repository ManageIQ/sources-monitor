source "https://rubygems.org"

plugin 'bundler-inject', '~> 1.1'
require File.join(Bundler::Plugin.index.load_paths("bundler-inject")[0], "bundler-inject") rescue nil
$LOAD_PATH.push(File.expand_path("lib", __dir__))

# Parser for Clowder config in ENV['ACG_CONFIG'] path
gem "activesupport",         "~> 5.2", ">= 5.2.4.3"
gem 'clowder-common-ruby',   "~> 0.2.3"
gem "insights-loggers-ruby", "~> 0.1.11"
gem "manageiq-messaging",    "~> 1.0.0"
gem "optimist"
gem "rake",                  "~> 13.0.0"
gem "rest-client",           "~>2.0"
gem "sources-api-client",    "~> 3.0"

group :test, :development do
  gem "rspec"
  gem "rubocop",             "~> 1.0.0", :require => false
  gem "rubocop-performance", "~> 1.8",   :require => false
  gem "rubocop-rails",       "~> 2.8",   :require => false
  gem "simplecov",           "= 0.17.1"
  gem "webmock"
end
