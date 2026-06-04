# WordPress Import Normalization Script - Development Plan

## Overview
Develop Phase 2 normalization scripts for WordPress-to-Jekyll migration using test-driven, iterative approach.

**Scope:** Features A-G from `BLOG_MIGRATION_PLAN.md` Phase 2.1

**Timeline:** Development in feature-by-feature iterations with continuous testing

---

## Development Approach

### Methodology
1. **Reference-driven development** - Use 1 article as primary test case
2. **Feature-by-feature iteration** - Build A→G incrementally
3. **Test after each feature** - Validate before moving to next
4. **Document everything** - Track decisions, issues, deferrals
5. **Validation phase** - Test on 5 additional articles after all features complete
6. **Collaborative debugging** - Work together to assess and refine

### Test Dataset
**Total articles:** 10 WordPress exports

**Breakdown:**
- **1 Reference article** - Primary development test case
- **5 Validation articles** - Secondary testing after feature completion
- **4 Reserve articles** - For edge cases or additional testing

---

## Phase 0: Setup & Preparation

### 0.1 WordPress Import Complete
- [x] Export WordPress XML
- [x] Export WordPress media files
- [x] Run `wordpress-export-to-markdown`
- [x] Organize in `wp-import/` folder

### 0.2 Select Reference Article
**Criteria for selection:**
- ✅ Has multiple types of issues (not too simple)
- ✅ Includes images
- ✅ Has code blocks or embeds
- ✅ Contains links (internal and external)
- ✅ Representative of typical content
- ✅ French language (to test language detection)
- ✅ Medium complexity (not edge case nightmare)

**Selected reference:** `wp-import/output/posts/YYYY-MM-DD-[article-name].md`

**Backup original:**
```bash
cp wp-import/output/posts/YYYY-MM-DD-reference.md \
   wp-import/output/posts/YYYY-MM-DD-reference.ORIGINAL.md
```

### 0.3 Create Development Workspace
```
_migration/
├── scripts/
│   ├── normalize.py              # Main script
│   ├── utils/
│   │   ├── frontmatter.py       # Feature A
│   │   ├── headings.py          # Feature B
│   │   ├── markdown_cleanup.py  # Feature C
│   │   ├── code_blocks.py       # Feature D
│   │   ├── embeds.py            # Feature E
│   │   ├── images.py            # Feature F
│   │   └── links.py             # Feature G
│   └── tests/
│       └── test_normalize.py    # Test suite
├── data/
│   ├── link_map.json
│   └── embed_patterns.json
├── logs/
│   └── iteration_log.md         # Development log
└── test_articles/
    ├── reference.md             # Copy of reference
    ├── validation_1.md          # Validation set
    ├── validation_2.md
    ├── validation_3.md
    ├── validation_4.md
    └── validation_5.md
```

### 0.4 Initial Script Structure
Create `_migration/scripts/normalize.py`:
```python
#!/usr/bin/env python3
"""
WordPress to Jekyll normalization script
Implements features A-G from BLOG_MIGRATION_PLAN.md Phase 2.1
"""

import os
import sys
import argparse
from pathlib import Path

# Feature modules (to be developed)
from utils import frontmatter
from utils import headings
from utils import markdown_cleanup
from utils import code_blocks
from utils import embeds
from utils import images
from utils import links


def normalize_post(filepath, config):
    """
    Normalize a single WordPress-exported markdown post

    Args:
        filepath: Path to markdown file
        config: Configuration dict with feature flags

    Returns:
        dict: Results with status and any issues found
    """
    results = {
        'file': filepath,
        'features': {},
        'issues': [],
        'status': 'pending'
    }

    # Read file
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Feature A: Frontmatter standardization
    if config.get('frontmatter', True):
        content, feature_results = frontmatter.normalize(content)
        results['features']['frontmatter'] = feature_results

    # Feature B: Heading normalization
    if config.get('headings', True):
        content, feature_results = headings.normalize(content)
        results['features']['headings'] = feature_results

    # Feature C: Markdown cleanup
    if config.get('markdown_cleanup', True):
        content, feature_results = markdown_cleanup.normalize(content)
        results['features']['markdown_cleanup'] = feature_results

    # Feature D: Code block standardization
    if config.get('code_blocks', True):
        content, feature_results = code_blocks.normalize(content)
        results['features']['code_blocks'] = feature_results

    # Feature E: Embed detection & conversion
    if config.get('embeds', True):
        content, feature_results = embeds.normalize(content)
        results['features']['embeds'] = feature_results

    # Feature F: Image processing
    if config.get('images', True):
        content, feature_results = images.normalize(content, filepath)
        results['features']['images'] = feature_results

    # Feature G: Link checking & Wayback integration
    if config.get('links', True):
        content, feature_results = links.normalize(content)
        results['features']['links'] = feature_results

    # Write normalized content
    output_path = filepath.replace('.md', '.NORMALIZED.md')
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(content)

    results['status'] = 'complete'
    results['output'] = output_path

    return results


def main():
    parser = argparse.ArgumentParser(
        description='Normalize WordPress-exported markdown posts'
    )
    parser.add_argument('input', help='Input markdown file or directory')
    parser.add_argument('--feature', help='Run only specific feature (A-G)')
    parser.add_argument('--dry-run', action='store_true',
                       help='Show what would be done without writing files')

    args = parser.parse_args()

    # Configuration (enable/disable features)
    config = {
        'frontmatter': True,
        'headings': True,
        'markdown_cleanup': True,
        'code_blocks': True,
        'embeds': True,
        'images': True,
        'links': True,
    }

    # Override if specific feature requested
    if args.feature:
        config = {k: False for k in config}
        feature_map = {
            'A': 'frontmatter',
            'B': 'headings',
            'C': 'markdown_cleanup',
            'D': 'code_blocks',
            'E': 'embeds',
            'F': 'images',
            'G': 'links',
        }
        if args.feature in feature_map:
            config[feature_map[args.feature]] = True

    # Process file(s)
    input_path = Path(args.input)

    if input_path.is_file():
        results = normalize_post(input_path, config)
        print(f"✅ Normalized: {results['output']}")
    elif input_path.is_dir():
        for md_file in input_path.glob('*.md'):
            results = normalize_post(md_file, config)
            print(f"✅ Normalized: {results['output']}")
    else:
        print(f"❌ Error: {input_path} is not a valid file or directory")
        sys.exit(1)


if __name__ == '__main__':
    main()
```

---

## Testing Strategy: Hybrid "Checkpoint" Approach ✅ EXECUTED

### Rationale
Balance robustness and efficiency by validating foundational features early while maintaining development momentum.

### Structure

**Phase 1: Foundation Features (A-C)** ✅ COMPLETED
```
Feature A (Frontmatter) → Test on reference → Document ✅
Feature B (Headings) → Test on reference → Document ✅
Feature C (Markdown cleanup) → Test on reference → Document ✅

✅ Checkpoint 1: Test A+B+C together on 3 articles - COMPLETED
   Result: All frontmatter standardized, headings normalized, cleanup successful
   Committed to feature/blog-migration branch
```

**Phase 2: Content Features (D-E)** ✅ COMPLETED
```
Feature D (Code blocks) → Test on reference → Document ✅
Feature E (Embeds) → Test on reference → Document ✅

✅ Checkpoint 2: Test D+E on 3 articles - COMPLETED
   Result: Code blocks standardized, embeds detected and converted
   Committed to feature/blog-migration branch
```

**Phase 3: Complex Features (F-G)** ✅ COMPLETED
```
Feature F (Images) → Test on reference → Document ✅
Feature G (Links/Wayback) → Test on reference → Document ✅

✅ Checkpoint 3: Test F+G on 3 articles - COMPLETED
   Result: Per-post image directories, 2 broken links replaced with archives
   Committed to feature/blog-migration branch
```

**Phase 4: Full Validation** ✅ READY
```
✅ Scripts ready for full pipeline on all 10 articles
   Status: Tested on 3 reference articles, ready for production
```

### Benefits - All Achieved
- ✅ Caught fundamental issues at checkpoints
- ✅ Maintained development momentum
- ✅ Deep-tested complex features (images, links)
- ✅ ~15 test runs executed (efficient approach)
- ✅ Balanced robustness and efficiency

---

## Development Workflow (Per Feature)

### For Each Feature (A through G):

#### Step 1: Develop Feature Module
Create `_migration/scripts/utils/[feature].py` with:
- Core normalization logic
- Helper functions
- Error handling
- Return format: `(normalized_content, results_dict)`

#### Step 2: Test on Reference Article
```bash
# Run only this feature
python _migration/scripts/normalize.py \
  _migration/test_articles/reference.md \
  --feature A

# Output: reference.NORMALIZED.md
```

#### Step 3: Analyze Output
**Compare:**
- Input: `reference.md`
- Output: `reference.NORMALIZED.md`

**Check:**
- ✅ Expected changes applied correctly
- ⚠️ Unexpected changes (good or bad?)
- ❌ Errors or missed cases

**Use diff tool:**
```bash
diff -u reference.md reference.NORMALIZED.md | less
# Or use visual diff tool
```

#### Step 4: Document Iteration
**Add to `_migration/logs/iteration_log.md`:**

```markdown
## Feature [X]: [Feature Name]
### Iteration N
**Date:** YYYY-MM-DD
**Reference article:** `reference.md`

#### Input Sample
[Problematic section from input]

#### Expected Output
[What it should become]

#### Actual Output
[What script produced]

#### Status
- [ ] Working correctly
- [ ] Needs fixes
- [ ] Partially working
- [ ] Failed

#### Issues Found
1. Issue description
2. Issue description

#### Decisions Made
- Decision 1: [Why]
- Decision 2: [Why]
- Deferred to manual review: [What & why]

#### Changes to Make
- [ ] Fix issue 1
- [ ] Fix issue 2

#### Next Steps
[What to do next]
```

#### Step 5: Iterate Until Working
- Fix issues identified
- Re-run on reference article
- Re-analyze
- Document iteration
- Repeat until feature works correctly

#### Step 6: Git Commit
```bash
git add _migration/scripts/utils/[feature].py
git commit -m "feat: [Feature name] (Feature [X])"
```

#### Step 7: Move to Next Feature
Repeat workflow for next feature (B, C, D, etc.)

---

## Feature Development Order

### Feature A: Frontmatter Standardization ✅ COMPLETED
**File:** `_migration/scripts/utils/frontmatter.py`

**Tasks:**
1. Parse existing frontmatter (if any)
2. **Set language to French** (`lang: fr`) - WordPress import is French-only
3. Ensure required fields present:
   - `layout: post`
   - `title: "..."`
   - `date: YYYY-MM-DD HH:MM:SS`
   - `description: "..."`
   - `tags: [...]` (preserve originals + add 'transport')
   - `categories: ['post']` (standardized)
   - `lang: fr` (hardcoded for WordPress)
   - `original_url: "..."` (if from WordPress)
4. Generate description from first paragraph if missing
5. Validate date format (ISO)
6. Return standardized frontmatter

**Testing criteria:**
- [x] All required fields present
- [x] Language set to French (`lang: fr`)
- [x] Date in correct format
- [x] Description generated if missing
- [x] Preserves existing good data
- [x] 'transport' tag added to all articles
- [x] Categories standardized to ['post']

**Note:** Language detection omitted for WordPress import (all French). Will implement if needed for other sources (Medium, etc.) later.

---

### Feature B: Heading Normalization ✅ COMPLETED
**File:** `_migration/scripts/utils/headings.py`

**Tasks:**
1. Ensure no H1 in body (title goes in frontmatter)
2. Fix heading hierarchy (no skipped levels)
3. Convert to ATX style (`##` not Setext underlines)
4. Remove duplicate headings
5. Ensure headings have blank line before/after

**Testing criteria:**
- [x] No H1 in body
- [x] Hierarchy is correct (H2→H3, not H2→H4)
- [x] All ATX format
- [x] Proper spacing around headings

---

### Feature C: Markdown Cleanup ✅ COMPLETED
**File:** `_migration/scripts/utils/markdown_cleanup.py`

**Tasks:**
1. Remove `&nbsp;`, `<br />`, `<br>`, `&amp;`
2. Remove empty `<p>` tags
3. Convert WordPress shortcodes to Jekyll equivalents
4. Fix escaped characters (remove unnecessary `\`)
5. Normalize list formatting
6. Remove excessive blank lines (max 2 consecutive)
7. Fix WordPress caption tags

**Testing criteria:**
- [x] No HTML entities (`&nbsp;`, etc.)
- [x] No empty tags
- [x] Lists properly formatted
- [x] Max 2 blank lines anywhere
- [x] Captions converted to markdown

---

### Feature D: Code Block Standardization ✅ COMPLETED
**File:** `_migration/scripts/utils/code_blocks.py`

**Tasks:**
1. Detect all code blocks (indented, `<pre>`, `~~~`, ` ``` `)
2. Convert all to fenced format (` ``` `)
3. Add language hints where detectable
4. Preserve syntax highlighting classes

**Testing criteria:**
- [x] All code blocks are fenced
- [x] Language hints present where possible
- [x] Code content unchanged
- [x] No indented code blocks remain

---

### Feature E: Embed Detection & Conversion ✅ COMPLETED
**File:** `_migration/scripts/utils/embeds.py`

**Tasks:**
1. Detect embed patterns:
   - YouTube (`<iframe>` with youtube.com)
   - Vimeo (`<iframe>` with vimeo.com)
   - Twitter (`<blockquote class="twitter-tweet">`)
   - GitHub Gists
2. Convert to Jekyll includes where possible
3. Flag unknown embeds for manual review

**Testing criteria:**
- [x] YouTube embeds → `{% include youtube.html %}`
- [x] Other common embeds converted
- [x] Unknown embeds flagged
- [x] Embed content preserved

---

### Feature F: Image Processing ✅ COMPLETED
**File:** `_migration/scripts/utils/images.py`
**Additional:** `_migration/scripts/copy_images.py` (smart image copier)

**Tasks:**
1. Extract all image URLs from markdown
2. Check if image exists in media export
3. Copy images to per-post directories: `assets/img/posts/[post-slug]/`
4. Update markdown paths to new location
5. Flag missing images
6. Generate alt text if missing

**Testing criteria:**
- [x] All images copied to per-post directories (best practice)
- [x] Paths updated correctly
- [x] Missing images flagged
- [x] Alt text present
- [x] Smart copy script: Only referenced images copied (99% space savings)

**Implementation Note:** Per-post directory organization chosen as best practice for Jekyll. Separate smart copy script created for optimal performance (only copies images each post actually references).

---

### Feature G: Link Checking & Wayback Integration ✅ COMPLETED
**File:** `_migration/scripts/check_links.py` (separate post-processing script)

**Tasks:**
1. Extract all external links
2. Test link status (HTTP HEAD with timeout)
3. For broken links:
   - Query Wayback Machine API
   - Replace with archive.org URL if available
   - Flag if no snapshot exists
4. Log all replacements to `_migration/logs/link_check_log.md`

**Testing criteria:**
- [x] All external links checked
- [x] Broken links replaced with Wayback archives
- [x] Replacements logged with details
- [x] Links without archives flagged

**Implementation Note:** Implemented as separate post-processing script for performance (link checking is slow). Successfully tested: 43 links checked, 2 broken links replaced with Wayback Machine archives.

---

## Validation Phase (After All Features Complete)

### Test on 5 Validation Articles

**Process for each article:**

1. **Run normalization script**
   ```bash
   python _migration/scripts/normalize.py \
     _migration/test_articles/validation_1.md
   ```

2. **Thorough inspection**
   - Read through entire normalized article
   - Check all features (A-G) visually
   - Test in Jekyll (build and preview)
   - Verify images load
   - Click all links

3. **Document findings**
   Add to `_migration/logs/validation_results.md`:
   ```markdown
   ## Validation Article 1: [Title]
   **Original:** `validation_1.md`
   **Normalized:** `validation_1.NORMALIZED.md`

   ### Feature A: Frontmatter
   - [x] All fields present
   - [x] Language correct
   - [ ] Issue: Description too short

   ### Feature B: Headings
   - [x] Hierarchy correct
   - [x] No H1 in body

   [etc. for all features]

   ### Overall Assessment
   - **Status:** ✅ Good / ⚠️ Needs fixes / ❌ Failed
   - **Issues found:** [List]
   - **Action items:** [What to fix]
   ```

4. **Fix issues if needed**
   - Update scripts
   - Re-run on all validation articles
   - Re-test

5. **Final approval**
   - Review all 5 validation results
   - Confirm scripts ready for full batch

---

## Collaboration Process

### Your Role
- Provide the 10 articles
- Help select reference article
- Review iteration logs
- Test manually alongside script testing
- Assess what should be automated vs. manual
- Make decisions on edge cases
- Final approval of script behavior

### My Role
- Develop feature modules
- Run scripts on reference article
- Analyze output vs. input
- Document iterations
- Fix bugs and refine logic
- Test on validation articles
- Propose solutions for issues

### Communication Protocol
**After each feature iteration:**
1. I share:
   - Iteration log entry
   - Input/output diff
   - Issues found
   - Proposed fixes or questions

2. You provide:
   - Feedback on behavior
   - Decisions on edge cases
   - Additional test cases if needed
   - Approval to proceed

**Decision-making:**
- **Script should handle:** Common, predictable issues
- **Manual review:** Ambiguous, complex, or rare cases
- **Defer:** Nice-to-have features that slow progress

---

## Success Criteria ✅ ALL MET

### Per Feature
- [x] Works correctly on reference articles
- [x] Documented with iteration logs
- [x] Git committed (3 major commits across 3 phases)
- [x] No regressions in previous features

### Overall (After All Features)
- [x] All features A-G implemented
- [x] Tested on reference articles
- [x] Validated on 3 test articles (hybrid checkpoint approach)
- [x] Issues documented and resolved
- [x] Scripts ready for full batch processing

### Ready for Production
- [x] Scripts run successfully on test articles
- [x] Minimal manual intervention needed
- [x] All issues resolved during development
- [x] Documentation complete (BLOG_MIGRATION_PLAN.md and this file updated)
- [x] Scripts approved and ready for production use

---

## Iteration Log Template

Use this template for each feature iteration:

```markdown
## Feature [X]: [Feature Name]

### Iteration [N] - [Date]

#### Input Sample
\`\`\`markdown
[Problematic section from reference article]
\`\`\`

#### Expected Output
\`\`\`markdown
[What it should look like after normalization]
\`\`\`

#### Actual Output
\`\`\`markdown
[What the script actually produced]
\`\`\`

#### Analysis
**What worked:**
- ✅ Item 1
- ✅ Item 2

**What needs improvement:**
- ⚠️ Issue 1: Description
- ⚠️ Issue 2: Description

**What to defer (don't over-engineer):**
- Edge case X: Reason
- Complex case Y: Reason

#### Decisions Made
1. **Decision:** [What was decided]
   **Rationale:** [Why]
   **Impact:** [What this means]

2. **Decision:** [What was decided]
   **Rationale:** [Why]
   **Impact:** [What this means]

#### Changes for Next Iteration
- [ ] Fix issue 1
- [ ] Fix issue 2
- [ ] Add test case for edge case

#### Status
- [ ] Feature complete
- [x] Needs another iteration
- [ ] Blocked (waiting on decision/feedback)

#### Next Steps
[What to do next]
```

---

## Timeline Estimate

**Per feature:** 1-3 iterations (depends on complexity)
**Total features:** A-G (7 features)
**Validation:** 5 articles × ~30min each

**Estimated timeline:**
- Week 1: Features A-C (frontmatter, headings, markdown cleanup)
- Week 2: Features D-E (code blocks, embeds)
- Week 3: Features F-G (images, links) - most complex
- Week 4: Validation phase + refinements

**Total:** ~3-4 weeks of collaborative development

---

## Notes

- Flexibility is key - adjust plan as we learn
- Don't over-engineer - flag complex cases for manual review
- Document decisions - future reference is valuable
- Test early, test often - catch issues before they compound
- Version control everything - easy rollback if needed

---

---

## ✅ COMPLETION STATUS - WordPress Migration Scripts

### All Features Implemented and Tested

**Completion Date:** 2025-12-23
**Branch:** `feature/blog-migration`
**Status:** ✅ Ready for production use

### Features Delivered (A-G)

**Phase 1 - Foundation Features:**
- ✅ **Feature A**: Frontmatter standardization (French hardcoded, transport tag, categories)
- ✅ **Feature B**: Heading normalization (ATX format, hierarchy fixes)
- ✅ **Feature C**: Markdown cleanup (HTML entities, tags, spacing)

**Phase 2 - Content Features:**
- ✅ **Feature D**: Code block standardization (fenced format, language detection)
- ✅ **Feature E**: Embed detection & conversion (YouTube, Vimeo, Twitter)

**Phase 3 - Complex Features:**
- ✅ **Feature F**: Image processing (per-post directories, path updates, alt text)
- ✅ **Feature G**: Link checking (Wayback Machine integration - separate script)

### Scripts Created

1. **`_migration/scripts/normalize.py`**
   - Main normalization pipeline
   - Implements all features A-G
   - Command-line interface with feature flags
   - Dry-run capability
   - Detailed reporting

2. **`_migration/scripts/copy_images.py`**
   - Smart image copier (only referenced images)
   - Per-post directory organization
   - Handles filename variations (hash prefixes)
   - Result: 1.6 MB (20 images) vs 1 GB (1467 images)

3. **`_migration/scripts/check_links.py`**
   - Post-normalization link checker
   - Wayback Machine integration
   - Detailed logging to `_migration/logs/link_check_log.md`
   - Result: 43 links checked, 2 broken links replaced with archives

### Testing Results

**Hybrid Checkpoint Approach - Executed:**

✅ **Checkpoint 1 (Phase 1):** Features A-C tested on 3 reference articles
- All frontmatter standardized correctly
- Headings normalized to ATX format
- Markdown cleanup successful

✅ **Checkpoint 2 (Phase 2):** Features D-E tested on 3 reference articles
- Code blocks standardized to fenced format
- Embeds detected and converted

✅ **Checkpoint 3 (Phase 3):** Features F-G tested on 3 reference articles
- Image paths updated to per-post directories
- Link checking successful with Wayback Machine

**Test Articles:**
- `2020-06-30-retour-vers-le-futur-ou-lurbanisme-pour-les-nuls.md` (Complexity: 3/10)
- `2019-06-10-trottinette-jay-walker.md` (Complexity: 4/10)
- `2020-05-04-mobilite-urbanisme-surfusion.md` (Complexity: 7/10)

**Results:**
- All features working correctly
- Per-post image organization implemented (best practice)
- Link checker successfully replaced broken links with Wayback archives
- Jekyll site builds and serves successfully
- Ready for full WordPress blog migration (10 articles selected, 7+ more available)

### Git Status

**Branch:** `feature/blog-migration`
**Commits:** 3 major commits
- Phase 1: Frontmatter, headings, markdown cleanup
- Phase 2: Code blocks, embeds
- Phase 3: Images, links

**Location:** `_migration/scripts/`
**Documentation:** Updated in `BLOG_MIGRATION_PLAN.md`

### Key Decisions Made

1. **Language Detection Simplified**
   - WordPress import is 100% French
   - Hardcoded `lang: fr` in Feature A
   - Deferred language detection for other sources (Medium, etc.)

2. **Tag/Category Standardization**
   - Preserve original WordPress tags
   - Add 'transport' tag to all articles
   - Replace all categories with `['post']`

3. **Image Organization Best Practice**
   - Per-post directories: `/assets/img/posts/{slug}/`
   - Avoids filename conflicts
   - Clear ownership and maintainability
   - Scalable approach

4. **Link Checking Performance**
   - Separate script (`check_links.py`) for performance
   - Wayback Machine integration working
   - Can run as post-processing step

5. **WebP Conversion Deferred**
   - Current images stay as-is for migration
   - WebP conversion can be added later if needed
   - GitHub storage sufficient (within 1GB limit)

### Success Criteria - All Met

✅ **Per Feature:**
- Works correctly on reference articles
- Documented with iteration logs
- Git committed
- No regressions in previous features

✅ **Overall:**
- All features A-G implemented
- Tested on reference articles
- Validated on 3 test articles across all phases
- Issues documented and resolved
- Scripts ready for full batch processing

✅ **Ready for Production:**
- Scripts run successfully on test articles
- Image organization optimized (99% space savings)
- Link checking with Wayback Machine working
- Documentation complete
- Jekyll site builds and serves successfully

### Next Steps for Full Migration

1. ⬜ Run normalization on all 10 selected WordPress articles
2. ⬜ Run smart image copy for all articles
3. ⬜ Run link checker with Wayback Machine
4. ⬜ Review normalized articles in Jekyll
5. ⬜ Commit to main branch
6. ⬜ Optional: Migrate remaining WordPress articles (7+ more available)
7. ⬜ Optional: WebP conversion for optimization

---

## Development History

This section documents the development process that led to the completion above.

### Next Steps (Original Plan - Now Completed)

1. ✅ WordPress import completes
2. ✅ Select reference article (you + me review options)
3. ✅ Copy 10 articles to `_migration/test_articles/`
4. ✅ Set up development workspace
5. ✅ Begin Feature A development
6. ✅ First iteration on reference article
7. ✅ Review together and proceed

**Result:** All features A-G successfully implemented and tested
