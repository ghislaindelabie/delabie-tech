require_relative "spec_helper"

# Invariants for the CV tab. CV is hand-written plain markdown (no rendercv);
# tests pin the high-level structure + the positioning rewrite from plan §3.1:
# remove "transitioning" framing; lead with the Alien role.

describe "CV tab invariants" do
  EN_PATH = I18nPairs::ROOT / "_tabs/cv.md"
  FR_PATH = I18nPairs::ROOT / "_tabs/cv.fr.md"

  # Required section headings (at any heading level). Each FR entry is the
  # direct counterpart of its EN peer — keep them symmetric so a drop on
  # either side is caught.
  REQUIRED_EN_HEADINGS = %w[Experience Skills Education Speaking Selected].freeze
  REQUIRED_FR_HEADINGS = %w[Expérience Compétences Formation Conférences Travaux].freeze

  it "EN and FR files exist with lang + ref + permalink" do
    [EN_PATH, FR_PATH].each do |p|
      expect(p.exist?).to be(true), "missing #{p}"
      fm = I18nPairs.frontmatter(p)
      %w[lang ref permalink].each do |k|
        expect(fm[k]).not_to be_nil, "#{p}: missing `#{k}`"
      end
    end
  end

  # Match either kramdown `## Heading` style or inline HTML `<h2>Heading</h2>` —
  # the CV currently uses inline HTML to render the split layout.
  HEADING_RE = ->(h) {
    Regexp.union(
      /^#+\s+.*\b#{Regexp.escape(h)}\b/i,
      /<h[1-6][^>]*>[^<]*\b#{Regexp.escape(h)}\b/i
    )
  }

  it "EN CV contains each required section heading" do
    content = File.read(EN_PATH)
    missing = REQUIRED_EN_HEADINGS.reject { |h| content =~ HEADING_RE.call(h) }
    expect(missing).to be_empty, "EN CV missing headings: #{missing}"
  end

  it "FR CV contains each required section heading" do
    content = File.read(FR_PATH)
    missing = REQUIRED_FR_HEADINGS.reject { |h| content =~ HEADING_RE.call(h) }
    expect(missing).to be_empty, "FR CV missing headings: #{missing}"
  end

  # Plan §3.1: "remove the 'transitioning' framing" on the EN CV.
  it "EN CV does NOT contain 'transitioning into AI' language" do
    content = File.read(EN_PATH)
    expect(content.downcase).not_to include("transitioning into ai")
  end

  # Plan §3.1: lead with the current Alien role.
  it "EN CV mentions Alien Intelligence (current role)" do
    content = File.read(EN_PATH)
    expect(content).to match(/alien\s+intelligence/i)
  end

  it "FR CV mentions Alien Intelligence" do
    content = File.read(FR_PATH)
    expect(content).to match(/alien\s+intelligence/i)
  end
end
