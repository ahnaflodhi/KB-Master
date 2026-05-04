---
name: Provenance and citation rot patterns for knowledge bases
type: reference
researched: 2026-04-12
primary_sources:
  - https://onlinelibrary.wiley.com/doi/full/10.1002/leap.1560
  - https://github.com/DocNow/waybackprov
  - https://github.com/ArchiveBox/ArchiveBox
  - https://www.mdpi.com/2079-9292/15/1/56
---

# Provenance and Citation Rot Patterns

## The citation rot problem

"Reference rot" — when web-based references disappear or become dysfunctional. No industry-wide solution exists. Directly relevant to wiki pages that cite web sources.

## Existing mitigation tools

### Perma.cc
- Maintained by consortium of research libraries
- Captures website snapshots and provides persistent identifiers
- Academic-grade — used in legal citations

### Wayback Machine (Internet Archive)
- Automatic crawling but NOT comprehensive — some sites never archived
- **waybackprov** tool: given a URL, summarizes which Internet Archive collections have archived it
- Limitation: does not crawl continuously; snapshots at intervals; some sites opt out via robots.txt

### ArchiveBox (self-hosted)
- Saves snapshots in redundant formats: HTML+CSS+JS, singlefile HTML, screenshot PNG, PDF, WARC
- Extracts embedded content (images, videos, etc.)
- Can be self-hosted alongside a wiki for local source archival

## AuditableLLM (hash-chain provenance)

From arXiv/MDPI 2026:
- Hash-chained update logs for tamper-evident provenance tracking
- Each update logged as hash-chain entry — any alteration immediately detectable
- Performance overhead: 3.4 ms/step, 5.7% slowdown, sub-second audit validation
- Aligns with EU AI Act (Article 50) and GDPR requirements
- Negligible utility degradation: below 0.2% in accuracy and macro-F1

## Wikipedia's own archival practice

Wikipedia policy (Help:Archiving_a_source):
- Always archive web sources at time of citation
- Use Wayback Machine or archive.today
- Record both original URL and archive URL
- This is the gold standard for wiki source management

## Synthesis for our blueprint

Our blueprint currently:
- Uses `sources/.manifest.json` with SHA-256 hashes for source delta tracking
- Has inline citation format
- Does NOT address what happens when a cited URL goes dead
- Does NOT specify source archival at ingest time
- Does NOT mention hash-chain audit logs

Recommended additions:
1. **Archive-on-ingest**: when ingesting a web source, save a local snapshot (ArchiveBox-style) or at minimum record Wayback Machine URL + snapshot date
2. **Citation health check in lint**: periodic check that cited URLs still resolve; flag 404s for manual review
3. **Hash-chain audit log**: extend log.md or parallel audit file with hash-chain linking (each entry hashes previous entry). Overhead is negligible (3.4ms/step) and enables tamper-evident provenance
4. **Dual URL format**: store both `original_url` and `archive_url` in source frontmatter
