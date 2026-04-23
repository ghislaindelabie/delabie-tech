#!/usr/bin/env ruby
# frozen_string_literal: true

# Local-dev CLI: scan content files and report translation invariant violations.
# Uses scripts/lib/i18n_pairs.rb (same logic as tests/structural/i18n_pairs_spec.rb).
#
# Usage: ruby scripts/check-i18n-pairs.rb
# Exit 0 if clean, 1 if violations found.

require_relative "lib/i18n_pairs"

violations = []
by_lang_ref = Hash.new { |h, k| h[k] = [] }

I18nPairs.content_files.each do |file|
  fm = I18nPairs.frontmatter(file)
  rel = Pathname.new(file).relative_path_from(I18nPairs::ROOT).to_s

  violations << "#{rel}: missing `lang`" unless fm["lang"]
  violations << "#{rel}: missing `ref`"  unless fm["ref"]

  if fm["ref"] && fm["lang"]
    by_lang_ref[[fm["lang"], fm["ref"]]] << rel
  end

  if fm["lang"] && fm["translated"] != false
    sibling = I18nPairs.sibling_path(file)
    unless File.exist?(sibling)
      violations << "#{rel}: no sibling at #{File.basename(sibling)} (add it or set `translated: false`)"
    end
  end

  if fm["permalink"]
    if fm["lang"] == "fr" && !fm["permalink"].start_with?("/fr/")
      violations << "#{rel}: lang:fr but permalink #{fm["permalink"].inspect} missing /fr/ prefix"
    elsif fm["lang"] == "en" && fm["permalink"].start_with?("/fr/")
      violations << "#{rel}: lang:en but permalink starts with /fr/"
    end
  end
end

by_lang_ref.each do |(lang, ref), rels|
  if rels.size > 1
    violations << "ref=#{ref} lang=#{lang} claimed by #{rels.size} files: #{rels.join(', ')}"
  end
end

I18nPairs.pairs_on_disk.each do |a, b|
  fm_a = I18nPairs.frontmatter(a)
  fm_b = I18nPairs.frontmatter(b)
  next unless fm_a["ref"] && fm_b["ref"]
  if fm_a["ref"] != fm_b["ref"]
    rel_a = Pathname.new(a).relative_path_from(I18nPairs::ROOT).to_s
    rel_b = Pathname.new(b).relative_path_from(I18nPairs::ROOT).to_s
    violations << "#{rel_a}(ref=#{fm_a["ref"]}) / #{rel_b}(ref=#{fm_b["ref"]}) paired on disk but disagree on ref"
  end
end

if violations.empty?
  puts "OK — all content files have valid i18n pairs."
  exit 0
else
  puts "i18n violations found:"
  violations.each { |v| puts "  - #{v}" }
  exit 1
end
