require "rspec"
require "yaml"
require "pathname"

ROOT = Pathname.new(File.expand_path("../..", __dir__))

# Module-level constants so they're not redefined on reload (RSpec/Guard).
# Addresses [REVIEW-14] and [REVIEW-8] (shared source of truth with
# scripts/check-i18n-pairs.rb).
require_relative "../../scripts/lib/i18n_pairs"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
