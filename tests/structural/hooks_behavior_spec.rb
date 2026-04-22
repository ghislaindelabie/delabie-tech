require_relative "spec_helper"
require "open3"
require "json"

# Verifies the pre-bash hook behaves correctly: rejects forbidden commands,
# allows permitted ones. Runs the real hook script with synthetic payloads.

HOOK = (ROOT / "scripts/hooks/pre-bash.sh").to_s

def run_hook(command)
  payload = JSON.dump(tool: "Bash", input: { command: command })
  # Pass as array form to avoid shell splitting on paths with spaces.
  _, stderr, status = Open3.capture3("bash", HOOK, stdin_data: payload)
  [status.exitstatus, stderr]
end

describe "pre-bash hook" do
  context "blocks dangerous operations" do
    {
      "git push origin main" => /direct push to main/,
      "git push -u origin main" => /direct push to main/,
      "git push --force origin feature/foo" => /force-push/,
      "git push -f origin feature/foo" => /force-push/,
      "git commit -m 'x' --no-verify" => /--no-verify/,
      "git reset --hard HEAD~3" => /destructive/,
      "gh pr merge 1" => /reserved to Ghislain/,
      "gh api -X DELETE /repos/foo/bar/branches/main/protection" => /branch-protection changes/,
    }.each do |cmd, match|
      it "rejects: #{cmd}" do
        code, stderr = run_hook(cmd)
        expect(code).not_to eq(0), "hook should have blocked: #{cmd}"
        expect(stderr).to match(match)
      end
    end
  end

  context "allows safe operations" do
    [
      "git status",
      "git diff",
      "git add file.md",
      "git commit -m 'feat: thing'",
      "git push -u origin feature/phase-1",
      "git checkout -b feature/phase-2-i18n",
      "gh pr create --fill",
      "gh pr view 42",
      "gh pr checks 42",
      "bundle exec jekyll build",
      "npm run test",
    ].each do |cmd|
      it "allows: #{cmd}" do
        code, _ = run_hook(cmd)
        expect(code).to eq(0), "hook should have allowed: #{cmd}"
      end
    end
  end
end
