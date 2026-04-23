#!/usr/bin/env ruby
# frozen_string_literal: true

# Local-dev CLI: scan content files and report translation invariant violations.
# Mirrors the logic of tests/structural/i18n_pairs_spec.rb so authors can catch
# missing translations without running the full RSpec suite.
#
# Usage: ruby scripts/check-i18n-pairs.rb
# Exit 0 if clean, 1 if violations found.

require "yaml"
require "pathname"

ROOT = Pathname.new(File.expand_path("..", __dir__))
CONTENT_DIRS = %w[_tabs _posts _case_studies _publications _teaching _activity].freeze

def content_files
  CONTENT_DIRS.flat_map do |dir|
    path = ROOT / dir
    next [] unless path.exist?
    Dir.glob(path / "**" / "*.md")
  end
end

def frontmatter(file)
  raw = File.read(file)
  return {} unless raw =~ /\A---\s*\n(.*?)\n---\s*\n/m
  YAML.safe_load(Regexp.last_match(1), permitted_classes: [Date, Time]) || {}
end

def sibling_path(file)
  base = File.basename(file, ".md")
  dir = File.dirname(file)
  base.end_with?(".fr") ? File.join(dir, "#{base.chomp(".fr")}.md") : File.join(dir, "#{base}.fr.md")
end

violations = []
content_files.each do |file|
  fm = frontmatter(file)
  rel = Pathname.new(file).relative_path_from(ROOT).to_s
  violations << "#{rel}: missing `lang`" unless fm["lang"]
  violations << "#{rel}: missing `ref`" unless fm["ref"]
  next if fm["translated"] == false
  next unless fm["lang"]
  sibling = sibling_path(file)
  unless File.exist?(sibling)
    violations << "#{rel}: no sibling at #{File.basename(sibling)} (add it or set `translated: false`)"
  end
end

if violations.empty?
  puts "OK — all content files have valid i18n pairs or explicit translated: false."
  exit 0
else
  puts "i18n violations found:"
  violations.each { |v| puts "  - #{v}" }
  exit 1
end
