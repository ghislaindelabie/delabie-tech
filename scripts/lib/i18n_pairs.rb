# frozen_string_literal: true

# Shared source of truth for i18n pair invariants.
# Consumed by:
#   - tests/structural/i18n_pairs_spec.rb (RSpec-based CI gate)
#   - scripts/check-i18n-pairs.rb (local-dev CLI)
#
# Addresses [REVIEW-8]: keeps CLI and spec from drifting.
# Addresses [REVIEW-14]: module-level constants, safe on reload.

require "yaml"
require "pathname"

module I18nPairs
  ROOT = Pathname.new(File.expand_path("../..", __dir__))

  CONTENT_DIRS = %w[_tabs _posts _case_studies _publications _teaching _activity].freeze

  def self.content_files
    CONTENT_DIRS.flat_map do |dir|
      path = ROOT / dir
      next [] unless path.exist?
      Dir.glob(path / "**" / "*.md")
    end
  end

  def self.frontmatter(file)
    raw = File.read(file)
    return {} unless raw =~ /\A---\s*\n(.*?)\n---\s*\n/m
    YAML.safe_load(Regexp.last_match(1), permitted_classes: [Date, Time]) || {}
  end

  # EN:  _tabs/about.md     → _tabs/about.fr.md
  # FR:  _tabs/about.fr.md  → _tabs/about.md
  def self.sibling_path(file)
    base = File.basename(file, ".md")
    dir  = File.dirname(file)
    base.end_with?(".fr") ? File.join(dir, "#{base.chomp(".fr")}.md") : File.join(dir, "#{base}.fr.md")
  end

  # Returns [pair_path, sibling_path] for each pair that exists on disk.
  # Yields a caller-supplied block per pair, or returns the list.
  def self.pairs_on_disk
    seen = {}
    pairs = []
    content_files.each do |file|
      sibling = sibling_path(file)
      next unless File.exist?(sibling)
      key = [file, sibling].sort
      next if seen[key]
      seen[key] = true
      pairs << key
    end
    pairs
  end
end
