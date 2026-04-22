require "rspec"
require "yaml"
require "pathname"

ROOT = Pathname.new(File.expand_path("../..", __dir__))

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
