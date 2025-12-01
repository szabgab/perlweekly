# Perl Weekly AI Coding Instructions

## Project Overview
This is the source code for the Perl Weekly newsletter website (https://perlweekly.com/). It's a Perl-based static site generator that transforms JSON-formatted newsletter content into HTML, RSS, email formats. Subscription is handled manually.

## Core Architecture

### Data Flow & Publishing Workflow
1. **Content Creation**: Newsletter editions stored as JSON files in `src/` (e.g., `src/650.json`)
2. **Generation**: `bin/generate.pl` transforms JSON → HTML/RSS/email using Template Toolkit templates in `tt/`
3. **Output**: Static files generated to `docs/` directory for web serving
4. **Local Preview**: Use `rustatic --path docs/ --indexfile index.html`
 at http://127.0.0.1:5000/

### Key Components
- **`src/*.json`**: Newsletter editions (1.json, 2.json, etc.)
- `next.json` is used as a template for the next edition and also the date of the next is used on the main page of the web site.
- `src/authors.json` stores information about the authors quoted in the editions.
- `src/events.json` is used to generate the `/events` page.
- **`lib/PerlWeekly/`**: Core modules (`Issue.pm` for edition processing, `Template.pm` for rendering)
- **`bin/*.pl`**: Utility scripts for feeds, email sending, stats, validation
- **`tt/`**: Template Toolkit templates for HTML generation
- **`static/` → `docs/`**: Static assets copied during build

## Essential Development Patterns

### Newsletter JSON Structure
```json
{
  "date": "YYYY-MM-DD",
  "editor": "author_key_from_authors_json",
  "subject": "Email subject line",
  "header": ["Editorial text paragraphs"],
  "chapters": [
    {
      "title": "Section Name",
      "entries": [
        {
          "title": "Article title",
          "author": "author_key",
          "text": "Description with optional <a> tags",
          "url": "https://...",
          "ts": "YYYY.MM.DD"
        }
      ]
    }
  ]
}
```

### Critical Validation Rules
- **JSON must pass strict parsing** - use `bin/tidy_json.pl` to normalize

### Development Commands
```bash
# Generate specific issue for web preview
perl bin/generate.pl web 650

# Generate all issues and website
perl bin/generate.pl web all

# Preview locally
rustatic --path docs/ --indexfile index.html  # Visit http://127.0.0.1:5000/

# Validate and tidy JSON
perl bin/tidy_json.pl

# Generate from markdown (alternate workflow)
perl bin/mkd2json.pl src/650.mkd

# Auto-generate feed entries
perl bin/gen_mkd_from_feeds.pl data/feeds.url >> src/650.mkd
```

### Template System (Template Toolkit)
- **Custom wrapper**: `PerlWeekly::Template` handles UTF-8 and line ending normalization
- **Shared includes**: `tt/incl/` directory for common template fragments
- **Output targets**: Same templates generate web, email, and RSS formats
- **Author linking**: Authors automatically linked to `/a/{handler}.html` pages

### Author Management
- **Master file**: `src/authors.json` with keys like `"gabor_szabo"`
- **Required fields**: `name` (display name)
- **Optional fields**: `pause`, `twitter`, `url`, `img`, `linkedin`
- **Handler generation**: Underscores become hyphens for URL slugs

## Integration Points

### External Data Sources
- **RSS Feeds**: `data/feeds.url` lists monitored blogs/sites
- **Events**: `src/events.json` for community event calendar
- **MetaCPAN Stats**: `src/metacpan.txt` updated via cpan-digger
- **Subscriber Count**: `src/count.txt` (private data)

### Email & Delivery
- **SendGrid integration**: `bin/sendgrid.pl` for newsletter delivery
- **Local testing**: `bin/sendmail.pl --to your@email.com` for preview
- **Mailman integration**: `bin/mailman.pl` for subscription management

### Build Artifacts
- **Web output**: All files generated to `docs/` directory
- **RSS feeds**: `docs/index.rss` and `docs/perlweekly.rss`
- **Calendar**: `docs/perlweekly.ical` from events.json
- **Archive pages**: Individual issues at `/archive/{number}.html`

## Development Guidelines

### Adding New Issues
1. Copy `src/next.json` to `src/{number}.json`
2. Update date, editor, subject, and header
3. Add entries to appropriate chapters (remove empty chapters)
4. Validate with `perl bin/generate.pl web {number}`

### Code Style & Quality
- **Perl::Tidy**: Use `tidyall -a --refresh-cache` for code formatting
- **Strict mode**: All Perl code uses `strict` and `warnings`
- **UTF-8 handling**: Consistent encoding throughout (`binmode`, `slurp_utf8`)

### Testing & Validation
- **Local preview**: Always test with `rustatic` before deploying
- **JSON validation**: Check for parse errors and missing required fields
- **URL validation**: Verify all links work and use canonical formats
- **Author verification**: Ensure all referenced authors exist in authors.json

This codebase prioritizes content workflow efficiency and reliable newsletter generation over complex architecture - most functionality is in straightforward Perl scripts with clear, linear data transformations.