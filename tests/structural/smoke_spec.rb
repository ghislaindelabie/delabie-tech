require_relative "spec_helper"

describe "Build smoke" do
  it "has a Gemfile" do
    expect((ROOT / "Gemfile").exist?).to be true
  end

  it "has _config.yml" do
    expect((ROOT / "_config.yml").exist?).to be true
  end

  it "has an index page" do
    expect((ROOT / "index.html").exist?).to be true
  end

  it "has CLAUDE.md with the no-direct-main-commit rule" do
    claude_md = (ROOT / "CLAUDE.md").read
    expect(claude_md).to include("NEVER commit directly to")
    expect(claude_md).to include("main")
  end

  it "has branch-protection snapshot referencing all required status checks" do
    snapshot = JSON.parse((ROOT / ".github/branch-protection.json").read)
    contexts = snapshot.dig("rules", "required_status_checks", "contexts")
    expect(contexts).to include(match(/Build/))
    expect(contexts).to include(match(/Claude Review/))
    expect(contexts).to include(match(/Claude Security Review/))
    expect(contexts).to include(match(/Review gate/))
  end

  it "has the pre-bash hook script executable" do
    hook = ROOT / "scripts/hooks/pre-bash.sh"
    expect(hook.exist?).to be true
    expect(File.executable?(hook)).to be true
  end

  it "has the .claude/settings.json with deny rules for dangerous git ops" do
    settings = JSON.parse((ROOT / ".claude/settings.json").read)
    deny = settings.dig("permissions", "deny")
    expect(deny).to include(match(/git push origin main/))
    expect(deny).to include(match(/git push --force/))
    expect(deny).to include(match(/gh pr merge/))
  end

  it "has CNAME pointing to v2.delabie.tech" do
    cname = (ROOT / "CNAME").read.strip
    expect(cname).to eq("v2.delabie.tech")
  end

  it "has robots_noindex true in _config.yml (preview precaution)" do
    config = YAML.safe_load_file((ROOT / "_config.yml"), permitted_classes: [Date])
    expect(config["robots_noindex"]).to be true
  end
end

require "json"
