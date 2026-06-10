# frozen_string_literal: true

# Shared source of truth for i18n pair invariants.
# Consumed by:
#   - tests/structural/i18n_pairs_spec.rb (RSpec-based CI gate)
#   - scripts/check-i18n-pairs.rb (local-dev CLI)
#
# Addresses [REVIEW-8]: keeps CLI and spec from drifting.
# Addresses [REVIEW-14]: module-level constants, safe on reload.

require "yaml"
require "date"
require "pathname"

module I18nPairs
  ROOT = Pathname.new(File.expand_path("../..", __dir__))

  CONTENT_DIRS = %w[_tabs _posts _case_studies _publications _teaching _activity _archive].freeze

  def self.content_files
    CONTENT_DIRS.flat_map do |dir|
      path = ROOT / dir
      next [] unless path.exist?
      Dir.glob(path / "**" / "*.md")
    end
  end

  # Maps a content file to its collection name (e.g. "_archive/x.md" → "archive",
  # "_case_studies/y.fr.md" → "case_studies"). Returns nil for loose dirs.
  def self.collection_of(file)
    rel = Pathname.new(file).relative_path_from(ROOT).to_s
    dir = rel.split("/").first
    return nil unless dir&.start_with?("_")
    dir.delete_prefix("_")
  end

  # [code review 2026-06 #4] Collections whose configured permalink template
  # does NOT vary by language — both the EN and FR sibling resolve to the same
  # URL unless the FR file carries its own /fr/ permalink. A template is
  # language-distinct only if it injects the lang into the path (a literal
  # "/fr" segment or a ":lang"-style variable); the collection defaults in
  # _config.yml (e.g. archive's "/archive/:year/:slug/") do not, so an FR file
  # that OMITS an explicit permalink silently collides with its EN sibling at
  # build time (Jekyll only warns, exit 0 — this incident happened once).
  #
  # Derived from _config.yml so adding a collection automatically extends the
  # rule; nothing is hardcoded to "archive".
  def self.collections_needing_explicit_fr_permalink
    config = YAML.safe_load_file(ROOT / "_config.yml", permitted_classes: [Date, Time]) || {}
    collections = config["collections"] || {}
    collections.filter_map do |name, settings|
      next unless settings.is_a?(Hash)
      next unless settings["output"] # output:false collections are never routed → no collision
      template = settings["permalink"].to_s
      # Language-distinct templates encode the lang in the path themselves.
      next if template.include?("/fr") || template.include?(":lang")
      name
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
