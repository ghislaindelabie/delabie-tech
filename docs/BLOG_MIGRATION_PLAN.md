# Blog Migration & Archive Enhancement Plan

## Project Goal
Transform legacy blog content from WordPress, Medium, and other outlets into a unified, enhanced Jekyll archive that serves as the lasting repository for all publications.

**End Result:** A powered-up archive superior to the originals with:
- No broken links (Wayback Machine integration)
- Improved style and readability (while preserving original voice)
- Graceful bilingual support (EN/FR)
- Preserved internal linking structure
- Consistent formatting and metadata

---

## Phase 1: Deterministic Conversion (Import)

### 1.1 WordPress Content
**Tool:** `wordpress-export-to-markdown` (Node.js) or Jekyll WordPress importer

**Input:**
- WordPress XML export file
- Or direct WordPress site access (if available)

**Process:**
```bash
npx wordpress-export-to-markdown
# Interactive wizard guides through:
# - Source selection (XML or URL)
# - Output directory (_posts/)
# - Image download preferences
# - Metadata options
```

**Output:**
- Markdown files with basic frontmatter
- Downloaded images in organized folders
- Preserved publication dates

### 1.2 Medium Content
**Tool:** Pandoc + Medium export

**Input:**
- Medium data export (Settings → Download your information)
- HTML files from export

**Process:**
```bash
# For each Medium post
pandoc medium-post.html -f html -t markdown -o post.md
# Then manual frontmatter addition
```

**Output:**
- Markdown files (needs frontmatter enhancement)
- Medium-hosted images (URLs only - download in Phase 2)

### 1.3 Other Outlets
**Approach:** Case-by-case using Pandoc or web scraping

**Process:**
- For accessible HTML: `pandoc article.html -o article.md`
- For PDFs: Extract text, then manual formatting
- For live URLs: Scrape HTML, then convert

---

## Phase 2: Normalization Pass (Automated Cleanup)

### 2.1 Core Normalization Script
**Language:** Python (or Node.js based on preference)

**Script:** `normalize_posts.py`

**Responsibilities:**

#### A. Frontmatter Standardization
```yaml
---
layout: post
title: "Article Title"
date: YYYY-MM-DD HH:MM:SS
description: "Brief description (auto-generated if missing)"
tags: [tag1, tag2, transport]  # preserve original tags + add 'transport'
categories: [post]  # standardized to 'post' for WordPress migration
lang: fr  # hardcoded for WordPress import (all French)
original_url: "https://original-source.com/article"  # for provenance
redirect_from:  # for SEO if migrating domains
  - /old-path/article
translated: false  # flag for translation status
---
```

**Logic:**
- Parse existing frontmatter
- **Language:** Set to French (`lang: fr`) for WordPress import (all articles in French)
- **Tags:** Preserve original tags + add 'transport' tag (for blog navigation)
- **Categories:** Set all to ['post'] (WordPress categories replaced with standardized category)
- Generate description from first paragraph if missing
- Ensure all required fields present
- Validate dates (ISO format)

**Rationale:**
- **Tags:** Keep WordPress tags for content navigation (e.g., 'fun', 'innovation', 'urbanism')
- **Categories:** WordPress used multiple categories (magazine, mobilite-active, etc.) → standardize to 'post'
- **Transport tag:** Added to all WordPress articles for blog-wide transport theme showcase

**Note:** WordPress import is French-only. Language detection will be implemented later for Medium/other sources if needed.

#### B. Heading Normalization
- Ensure single H1 (post title in frontmatter, not body)
- No skipped heading levels (H2 → H4 without H3)
- Consistent heading style (ATX: `##` not Setext)
- Auto-fix hierarchy violations

#### C. Markdown Cleanup
**Common WordPress artifacts:**
```markdown
# Before
&nbsp;&nbsp;Some text<br /><br />
<p><br></p>
[caption]Image caption[/caption]

# After
Some text

_Image caption_
```

**Fixes:**
- Remove `&nbsp;`, `<br />`, empty `<p>` tags
- Convert WordPress shortcodes to Jekyll equivalents
- Fix escaped characters (`\*`, `\_` when not needed)
- Normalize list formatting (consistent spacing)
- Remove excessive blank lines (max 2 consecutive)

#### D. Code Block Standardization
```markdown
# Before (various formats)
<pre>code here</pre>
~~~
code here
~~~
    indented code

# After (fenced with language)
```python
code here
```
```

**Logic:**
- Convert all code blocks to fenced format
- Add language hints where detectable
- Preserve syntax highlighting classes

#### E. Embed Pattern Detection & Conversion
**YouTube:**
```liquid
# Before
<iframe src="youtube.com/embed/VIDEO_ID"></iframe>

# After
{% include youtube.html id="VIDEO_ID" %}
```

**Twitter:**
```liquid
# Before
<blockquote class="twitter-tweet">...</blockquote>

# After
{% include twitter.html id="TWEET_ID" %}
```

**Supported embeds:**
- YouTube
- Vimeo
- Twitter
- CodePen
- GitHub Gists

**Unknown embeds → flagged for manual review**

#### F. Image Processing ✅ COMPLETED

**Storage Strategy:**
- **Current:** Store images directly in GitHub repository
- **Size:** ~500MB (within 1GB GitHub recommendation)
- **Future:** Migrate to Git LFS if repo approaches 1GB
- **CDN:** GitHub Pages built-in CDN (Fastly)

**Best Practice: Per-Post Directories** ✅ IMPLEMENTED
```
assets/img/posts/
  ├── 2023-01-15-article-slug/
  │   ├── hero.webp        # Converted from JPG/PNG
  │   ├── diagram-1.webp
  │   └── screenshot.webp
  ├── 2023-02-20-another-article/
  │   └── photo.webp
```

**Advantages:**
- ✅ No filename conflicts (each post can have `header.jpg`)
- ✅ Clear ownership (easy to see which images belong to which post)
- ✅ Easy maintenance (delete post = delete folder)
- ✅ Scales well for many posts

**Process:**
1. Extract all image URLs from markdown
2. Download images (with retry logic)
3. **Convert to WebP format** (lossless or minimal quality loss)
   - Use Pillow (Python) or similar library
   - Quality setting: 90-95 (minimal visual loss)
   - Skip if conversion would increase file size
   - Keep original format if WebP conversion fails
4. Organize by post slug in `assets/img/posts/[slug]/`
5. Optimize images (compress, resize if needed)
6. Update markdown paths:
   ```markdown
   ![Alt text](/assets/img/posts/2023-01-15-article-slug/hero.webp)
   ```

**WebP Conversion Logic:**
```python
from PIL import Image
import os

def convert_to_webp(image_path, quality=90):
    """
    Convert image to WebP format with quality preservation

    Args:
        image_path: Path to source image
        quality: WebP quality (90-95 recommended)

    Returns:
        Path to WebP file or original if conversion fails/increases size
    """
    try:
        img = Image.open(image_path)
        webp_path = os.path.splitext(image_path)[0] + '.webp'

        # Convert to WebP
        img.save(webp_path, 'WEBP', quality=quality)

        # Check if WebP is actually smaller
        if os.path.getsize(webp_path) < os.path.getsize(image_path):
            os.remove(image_path)  # Remove original
            return webp_path
        else:
            os.remove(webp_path)  # Keep original
            return image_path
    except Exception as e:
        print(f"WebP conversion failed for {image_path}: {e}")
        return image_path  # Keep original
```

**Git Configuration:**
```bash
# Add to .gitattributes for better binary handling
echo "*.jpg binary" >> .gitattributes
echo "*.png binary" >> .gitattributes
echo "*.webp binary" >> .gitattributes
```

**Migration Path to Git LFS (when needed):**
```bash
# If repo approaches 1GB, migrate to Git LFS
git lfs install
git lfs track "*.webp" "*.jpg" "*.png"
git add .gitattributes
git lfs migrate import --include="*.webp,*.jpg,*.png"
```

**Failed downloads → flagged for manual intervention**

#### G. Link Checking & Wayback Integration ✅ COMPLETED

**Implementation:**
- ✅ Separate post-processing script: `_migration/scripts/check_links.py`
- ✅ Wayback Machine integration working
- ✅ Tested on all posts: 2 broken links successfully replaced with archives

**Process:**
1. Extract all external links from post
2. Test link status (HTTP HEAD request with timeout)
3. For broken links (4xx, 5xx, timeout):
   - Query Wayback Machine API
   - If snapshot exists: replace with archive.org URL
   - If no snapshot: flag for manual review
4. Log all link replacements to `_migration/logs/link_check_log.md`

**Usage:**
```bash
# Check all posts
python _migration/scripts/check_links.py _posts/

# Dry run
python _migration/scripts/check_links.py _posts/ --dry-run
```

**Wayback Machine API:**
```python
import requests

def get_wayback_url(url):
    api = f"https://archive.org/wayback/available?url={url}"
    response = requests.get(api).json()

    if 'archived_snapshots' in response:
        closest = response['archived_snapshots'].get('closest', {})
        if closest.get('available'):
            return closest['url']
    return None
```

**Link replacement format:**
```markdown
# Before
[Dead link](https://defunct-site.com/article)

# After
[Dead link](https://web.archive.org/web/20220315/defunct-site.com/article) *(archived)*
```

#### H. Internal Link Preservation
**Challenge:** URLs change during migration (permalinks, slugs, etc.)

**Solution: Link mapping database**

**Step 1: Build link map**
```json
{
  "old_urls": {
    "https://old-wp-site.com/2020/03/my-article": "2020-03-15-my-article",
    "https://medium.com/@user/my-post-123abc": "2021-05-20-my-post"
  },
  "internal_refs": {
    "my-article": "/blog/2020/03/15/my-article/",
    "my-post": "/blog/2021/05/20/my-post/"
  }
}
```

**Step 2: Rewrite internal links**
```python
def fix_internal_links(content, link_map):
    # Find all links in markdown
    # Check if link points to old blog domain
    # Replace with new Jekyll permalink
    # Preserve anchor links (#section)
    pass
```

**Step 3: Add redirects for SEO**
```yaml
# In frontmatter
redirect_from:
  - /2020/03/my-article
  - /my-article
```

Uses `jekyll-redirect-from` plugin to create redirect pages.

---

## Phase 3: Exception Handling (Manual Queue)

### 3.1 Flag File System
**Output:** `_migration/manual_review.md`

**Categories:**
1. **Unknown embeds:** Iframes/scripts not recognized
2. **Complex tables:** May degrade in Markdown
3. **Failed image downloads:** Blocked, 404, or CORS issues
4. **Dead links without Wayback:** No archive available
5. **Ambiguous language detection:** Can't determine FR/EN
6. **Complex HTML:** Custom styling that won't translate

**Format:**
```markdown
## Post: 2023-01-15-complex-article.md

### Issue: Unknown embed
**Location:** Line 42
**Content:**
```html
<iframe src="https://unknown-service.com/embed/123"></iframe>
```
**Action needed:** Manual conversion or removal

### Issue: Failed image download
**URL:** https://blocked-cdn.com/image.jpg
**Error:** 403 Forbidden
**Action needed:** Download manually or find alternative
```

### 3.2 Review Workflow
1. Script generates `manual_review.md`
2. Human reviews each flagged item
3. Make manual fixes in markdown files
4. Mark items as resolved
5. Re-run normalization (skips resolved items)

---

## Phase 4: Bilingual Content Strategy

### 4.1 Language Detection & Tagging
**Auto-detection using `langdetect` (Python):**
```python
from langdetect import detect

def detect_language(content):
    try:
        lang = detect(content)
        return 'fr' if lang == 'fr' else 'en'
    except:
        return 'unknown'  # Flag for manual review
```

**Add to frontmatter:**
```yaml
lang: fr  # or en
translated: false  # true if translation exists
translation_url: /blog/2023/01/15/article-title-en/  # if paired
```

### 4.2 Translation Workflow
**For priority articles (to be translated EN ↔ FR):**

**Translation Agent Script:** `translate_post.py`

**Process:**
1. Select post for translation
2. LLM translates content (preserving markdown structure)
3. Create paired post with `-en` or `-fr` suffix
4. Link posts via `translation_url` frontmatter
5. Human review for accuracy

**LLM Translation Prompt:**
```
Translate the following blog post from French to English.

Requirements:
- Preserve all markdown formatting exactly
- Maintain technical terminology accuracy
- Keep the author's voice and style
- Do not translate:
  - Code blocks
  - URLs
  - Proper nouns (unless commonly translated)
  - YAML frontmatter keys

Original post:
[CONTENT]
```

**Output:** Paired files
```
_posts/
  ├── 2023-01-15-mon-article-fr.md  (lang: fr)
  └── 2023-01-15-my-article-en.md   (lang: en, translated: true)
```

### 4.3 Graceful Fallback for Untranslated Posts
**Scenario:** French post, no English translation, English reader visits

**Solution 1: Display French with warning banner**

**Create include:** `_includes/translation_notice.liquid`
```liquid
{% if page.lang != site.active_lang and page.translated == false %}
<div class="translation-notice">
  <p>
    ℹ️ This article is available in {{ page.lang | upcase }} only.
    {% if page.lang == 'fr' %}
      An English translation is not yet available.
    {% endif %}
  </p>
</div>
{% endif %}
```

**Add to post layout:**
```liquid
<!-- In _layouts/post.html -->
{% include translation_notice.liquid %}
```

**Solution 2: Auto-duplicate with flag**
```python
# For posts without translation
# Create symlink or duplicate in other language folder
# Add frontmatter: auto_duplicated: true
# Show prominent notice
```

### 4.4 Language Switcher Enhancement
**Update header to show translation availability:**
```liquid
{% if page.translation_url %}
  <a href="{{ page.translation_url }}" class="translation-link">
    {% if site.active_lang == 'en' %}
      Lire en français
    {% else %}
      Read in English
    {% endif %}
  </a>
{% endif %}
```

---

## Phase 5: Content Polishing (LLM Enhancement)

### 5.1 Text Polishing Agent
**Purpose:** Improve style, grammar, readability WITHOUT changing meaning or voice

**Script:** `polish_content.py`

**LLM Prompt Template:**
```
You are a professional editor helping improve a blog post.

Task: Polish this text to improve:
- Grammar and syntax
- Clarity and readability
- Flow and transitions
- Sentence structure variety

CRITICAL RULES:
- DO NOT change the author's core ideas or arguments
- DO NOT change technical accuracy
- DO NOT alter the author's voice or tone
- DO NOT add new information
- DO NOT remove important details
- PRESERVE all markdown formatting exactly
- PRESERVE all links and images
- PRESERVE all code blocks unchanged

Original text:
[CONTENT]

Return ONLY the polished text with no explanation.
```

**Safety measures:**
1. **Diff review:** Show before/after for human approval
2. **Selective application:** Run on body content only (not titles, code, quotes)
3. **Preserve structure:** Don't reorganize sections
4. **Change tracking:** Log all polishing edits

**Workflow:**
```python
def polish_post(markdown_file):
    # Parse frontmatter and body
    # Extract body content
    # Send to LLM for polishing
    # Show diff to user
    # Await approval (y/n)
    # Apply changes if approved
    # Log changes to polish_log.json
```

### 5.2 Quality Checks
**Automated validation:**
- [ ] Markdown lints successfully
- [ ] All images load
- [ ] All internal links resolve
- [ ] All external links work or archived
- [ ] Language tag matches content
- [ ] Frontmatter complete
- [ ] No HTML rendering errors

**Manual review checklist:**
- [ ] Polished text preserves original meaning
- [ ] Technical accuracy maintained
- [ ] Author's voice intact
- [ ] Visual formatting correct
- [ ] Embeds render properly

---

## Phase 6: Testing & Validation

### 6.1 Local Testing
```bash
# Build site locally
bundle exec jekyll build

# Check for errors
# Test sample posts in browser
# Verify:
# - Images load
# - Links work
# - Code blocks render
# - Embeds display
# - Language switching works
# - Translation notices appear
```

### 6.2 Link Validation
```bash
# Check all links
bundle exec htmlproofer ./_site \
  --disable-external \
  --allow-hash-href

# For external links (slower)
bundle exec htmlproofer ./_site \
  --external_only
```

### 6.3 Content Review
Sample 10-20% of migrated posts:
- Read through completely
- Check formatting
- Test all interactive elements
- Verify metadata accuracy

---

## Implementation Roadmap

### Sprint 1: Foundation (Week 1)
- [ ] Set up migration workspace (`_migration/` folder)
- [ ] Export WordPress content (XML)
- [ ] Export Medium content
- [ ] Collect articles from other outlets
- [ ] Run initial conversion (WordPress + Medium)
- [ ] Assess conversion quality

### Sprint 2: Normalization (Week 2)
- [ ] Build core normalization script
  - [ ] Frontmatter standardization
  - [ ] Heading fixes
  - [ ] Markdown cleanup
  - [ ] Code block formatting
- [ ] Test on sample posts (5-10)
- [ ] Refine based on results

### Sprint 3: Media & Links (Week 3)
- [ ] Implement image downloader
- [ ] Organize images in assets structure
- [ ] Build link checker
- [ ] Integrate Wayback Machine API
- [ ] Create internal link mapper
- [ ] Test on sample posts

### Sprint 4: Language Handling (Week 4)
- [ ] Implement language detection
- [ ] Add language tags to all posts
- [ ] Build translation notice component
- [ ] Test bilingual navigation
- [ ] Create translation workflow documentation

### Sprint 5: Content Enhancement (Week 5)
- [ ] Build content polishing agent
- [ ] Test polishing on 3-5 posts
- [ ] Implement diff review system
- [ ] Create approval workflow
- [ ] Document polishing guidelines

### Sprint 6: Review & Deploy (Week 6)
- [ ] Run full migration on all posts
- [ ] Review manual queue items
- [ ] Polish priority posts (top 10-20)
- [ ] Full site testing
- [ ] Fix any issues
- [ ] Deploy to `content` branch
- [ ] Merge to `main` after final review

---

## Success Criteria

### Quantitative Metrics
- [ ] 100% of posts converted to Markdown
- [ ] 95%+ of images successfully downloaded
- [ ] 90%+ of broken links replaced with Wayback archives
- [ ] 100% of posts have complete frontmatter
- [ ] 0 markdown syntax errors
- [ ] All internal links functional

### Qualitative Goals
- [ ] Posts are more readable than originals
- [ ] Formatting is consistent across all posts
- [ ] No degradation of technical content
- [ ] Author's voice preserved
- [ ] Bilingual experience is seamless
- [ ] Archive serves as definitive source

---

## Tools & Technologies

### Core Stack
- **Jekyll** - Static site generator
- **Python 3.x** - Scripting language
- **Pandoc** - Document converter
- **wordpress-export-to-markdown** - WP migration

### Python Libraries
```txt
# requirements.txt
requests          # HTTP requests
beautifulsoup4    # HTML parsing
markdown          # Markdown processing
pyyaml           # YAML frontmatter
Pillow           # Image processing & WebP conversion
anthropic        # Claude API (for polishing)

# Note: langdetect omitted - WordPress import is French-only
# Add later if needed for other sources (Medium, etc.)
```

### Jekyll Plugins
```ruby
# Gemfile
gem 'jekyll-redirect-from'  # SEO redirects
gem 'jekyll-imagemagick'    # Image optimization
gem 'jekyll-polyglot'       # Multi-language
```

---

## File Structure

```
ghislaindelabie/
├── _posts/                 # Migrated posts
│   ├── 2020-01-15-old-wp-post-fr.md
│   ├── 2021-03-20-medium-article-en.md
│   └── ...
├── assets/
│   └── img/
│       └── posts/          # Downloaded images
│           ├── 2020-01-15-old-wp-post/
│           └── 2021-03-20-medium-article/
├── _migration/             # Migration workspace
│   ├── scripts/
│   │   ├── normalize_posts.py
│   │   ├── download_images.py
│   │   ├── fix_links.py
│   │   ├── translate_post.py
│   │   └── polish_content.py
│   ├── data/
│   │   ├── link_map.json
│   │   ├── polish_log.json
│   │   └── translation_map.json
│   ├── imports/
│   │   ├── wordpress/      # Raw WP exports
│   │   ├── medium/         # Raw Medium exports
│   │   └── other/          # Other sources
│   └── manual_review.md    # Exception queue
├── BLOG_MIGRATION_PLAN.md  # This document
└── README.md
```

---

## Risk Mitigation

### Potential Issues & Solutions

**Risk:** Image downloads fail (CORS, 404, etc.)
**Mitigation:**
- Retry with different user agents
- Manual download list for problematic sources
- Use Wayback Machine for archived images

**Risk:** Internal links break after migration
**Mitigation:**
- Comprehensive link mapping
- Jekyll redirects for old URLs
- Validation before deployment

**Risk:** LLM polishing changes meaning
**Mitigation:**
- Human review of all polished content
- Diff view for approval
- Conservative polishing prompts
- Option to revert changes

**Risk:** Language detection errors
**Mitigation:**
- Manual review of edge cases
- Allow manual override in frontmatter
- Fallback to default language

**Risk:** Complex embeds don't work
**Mitigation:**
- Manual review queue
- Custom Jekyll includes for common cases
- Keep as HTML for rare cases

---

## ✅ COMPLETED - WordPress Migration (Phase 2.1)

### Normalization Pipeline Complete
All 7 features (A-G) implemented and tested on 3 reference articles:

**Phase 1 - Foundational Features:**
- ✅ **Feature A**: Frontmatter standardization (French, transport tag, categories)
- ✅ **Feature B**: Heading normalization (ATX format, hierarchy fixes)
- ✅ **Feature C**: Markdown cleanup (HTML entities, tags, spacing)

**Phase 2 - Content Features:**
- ✅ **Feature D**: Code block standardization (fenced format, language detection)
- ✅ **Feature E**: Embed detection & conversion (YouTube, Vimeo, Twitter)

**Phase 3 - Complex Features:**
- ✅ **Feature F**: Image processing (per-post directories, path updates, alt text)
- ✅ **Feature G**: Link checking (Wayback Machine integration)

### Scripts Created
1. **`normalize.py`** - Main normalization pipeline (all features A-G)
2. **`copy_images.py`** - Smart image copier (per-post organization)
3. **`check_links.py`** - Link checker with Wayback Machine

### Test Results
- **Articles processed**: 3 reference articles (10 total available)
- **Images**: Per-post organization (1.6 MB for test articles)
- **Links**: 2 broken links replaced with Wayback archives
- **Status**: ✅ Ready for full WordPress blog migration

### Git Status
- Branch: `feature/blog-migration`
- Commits: 3 (Phase 1, 2, 3)
- Location: `_migration/scripts/`

---

## Next Steps

1. **Review this plan** - Confirm approach and priorities
2. **Set up migration workspace** - Create folder structure
3. **Export source content** - WordPress XML, Medium data
4. **Begin Sprint 1** - Initial conversion
5. **Iterate and refine** - Adjust plan based on real data

---

## Notes

- Estimated timeline: 6 weeks (can be compressed or extended)
- Can be done incrementally (batch by batch vs. all at once)
- Recommend starting with a small batch (10 posts) to validate approach
- Archive originals before any destructive operations
- Version control everything (Git commits for each phase)
