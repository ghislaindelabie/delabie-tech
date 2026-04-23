source "https://rubygems.org"

gem "jekyll", "~> 4.3"
# Chirpy is pinned at minor level because we fork _includes/sidebar.html
# and _data/locales/fr.yml from v7.5.x. A minor bump (7.6+) can ship
# sidebar/locale changes that silently diverge from our fork; bumping
# is an intentional re-diff operation. [REVIEW-29] / [REVIEW-8 @ 07:01].
gem "jekyll-theme-chirpy", "~> 7.5.0"

# Plugin pins match current Gemfile.lock versions so a cache-miss resolve
# can't silently pull future majors that change canonical/sitemap semantics
# the i18n layer relies on. Addresses [SEC-1].
group :jekyll_plugins do
  gem "jekyll-redirect-from", "~> 0.16"
  gem "jekyll-sitemap", "~> 1.4"
  gem "jekyll-seo-tag", "~> 2.8"
  # jekyll-feed deliberately omitted — Chirpy ships its own feed.xml.
  gem "jekyll-paginate", "~> 1.1"
end

group :test do
  gem "rspec", "~> 3.13"
  gem "html-proofer", "~> 5.0"
end

gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem "wdm", "~> 0.1.1", :platforms => [:mingw, :mswin, :x64_mingw]
gem "webrick", "~> 1.8"
