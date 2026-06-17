# Data Cleaning Log — World Layoffs 2020–2026

This document records every cleaning decision made during the pipeline,
including mistakes caught and corrected along the way. Maintaining a log
like this demonstrates data governance — verifying every assumption
against the actual data rather than accepting it at face value.

---

## Dataset Profile (Raw)

| Metric | Value |
|--------|-------|
| Total rows | 4,453 |
| Total columns | 11 |
| Date range | March 2020 – June 2026 |
| Exact duplicates | 3 (Cars24, Beyond Meat, Cazoo) |
| Soft duplicates (same company + date, different values) | 21 |

---

## Column-Level Quality Assessment (Pre-Cleaning)

| Column | Type (raw) | Missing | Issue Found |
|--------|-----------|---------|-------------|
| company | TEXT | 0 | 15 rows with trailing whitespace |
| location | TEXT | 1 | Multiple formatting and encoding issues — see Step 6 |
| total_laid_off | TEXT | 1,534 (34.4%) | Stored as decimals e.g. `50.0` not `50` |
| date | TEXT | 0 | Correct M/D/YYYY format — needed type conversion |
| percentage_laid_off | TEXT | 1,656 (37.2%) | Stored as proportions 0.0–1.0 (correct, no fix needed) |
| industry | TEXT | 2 | Blank strings |
| source | TEXT | 3 | URL column — no analytical value |
| stage | TEXT | 5 | Blank strings + `Unknown` inconsistency |
| funds_raised | TEXT | 517 (11.6%) | Renamed from `funds_raised_millions` in original 2,300-row dataset |
| country | TEXT | 2 | `UAE` vs `United Arab Emirates`, plus location-country mismatches |
| date_added | TEXT | 0 | Differs from `date` — entry date vs announcement date |

---

## Cleaning Decisions Made

### Duplicates

| Issue | Decision | Reason |
|-------|----------|--------|
| 3 exact duplicates (Cars24, Beyond Meat, Cazoo) | Removed via `ROW_NUMBER()` partition | Identical across all 9 analytical columns |
| 21 soft duplicates (same company + date) | Investigated individually, not bulk-deleted | Same company can report multiple distinct events on the same date |

**Correction made during the process:** an early profiling pass checked for duplicates using a full-row hash that included `source` and `date_added`. Since those two columns differed slightly between the Cars24/Beyond Meat/Cazoo pairs, the hash made them look unique and an initial report wrongly stated "0 exact duplicates." Re-running the check using only the 9 analytical columns (matching what the actual SQL `GROUP BY` does) correctly surfaced all 3. **Lesson: always verify duplicate detection logic matches the columns actually being compared in the SQL, not an assumed superset.**

### Standardization

| Issue | Decision | Reason |
|-------|----------|--------|
| 15 company names with trailing spaces | Trimmed via `TRIM()` | Prevents false distinct values in GROUP BY |
| `UAE` vs `United Arab Emirates` | Unified to `United Arab Emirates` | Same country, two names inflate country counts |
| `Unknown` in stage column | Set to NULL | Not a real stage value — NULL is more honest |
| `total_laid_off` stored as `50.0` | Cast to INT | Headcounts are whole numbers — decimal is a CSV import artifact |
| Industry variants (Crypto/CryptoCurrency) | None found | Confirmed clean — issue present in original 2,300-row dataset but not here |

### NULL Handling

| Column | Decision | Reason |
|--------|----------|--------|
| `total_laid_off` (34.4% NULL) | Preserved as NULL, flagged separately | Unknown layoffs ≠ zero layoffs |
| `percentage_laid_off` (37.2% NULL) | Preserved as NULL | Not disclosed ≠ not happened |
| `industry` (2 rows) | Self-join from matching company rows | Industry is a stable company-level attribute |
| `country` (2 rows: Fit Analytics, Ludia) | **Fixed manually using location, NOT self-join** | See correction below |
| `funds_raised` (11.6% NULL) | Preserved as NULL | Not all companies disclose funding |
| Rows where both `total_laid_off` AND `percentage_laid_off` are NULL (~724 rows) | Flagged, then deleted in Step 9 | No analytical value in either key metric |

**Correction made during the process:** the original guide suggested filling missing `country` values using the same self-join pattern as `industry` — matching on `company` alone. This was flagged as a mistake before being applied: a company can legitimately operate in multiple countries (Google has US, India, and Ireland offices), so inferring country from another row of the same company risks assigning the wrong country entirely. Industry is safe to infer this way because it is a fixed company-level attribute; country is a row-level attribute describing where that specific layoff event happened. The fix was changed to use `location` instead — both `Fit Analytics` (Berlin) and `Ludia` (Montreal) had clear, unambiguous locations, so country was set directly from that context rather than borrowed from another row. **Lesson: before using a self-join to fill NULLs, confirm the column is actually constant at the level you're joining on.**

### Numerical Validation

| Check | Result |
|-------|--------|
| Negative total_laid_off | 0 rows |
| percentage_laid_off outside 0–1 | 0 rows |
| Negative funds_raised | 0 rows |

### Location–Country Validation (Step 6)

This was the most extensive part of the cleaning process. An initial pass found 36 issues across 6 categories. Each was investigated individually — several required external verification rather than assumption.

| Category | Issue | Rows | Resolution |
|----------|-------|------|------------|
| 1 | Missing `Non-U.S.` suffix on known international cities | ~18 | Bulk suffix added (Auckland, Bengaluru, Cayman Islands, Gurugram, Kuala Lumpur, London, Mumbai, Tel Aviv, Montreal, Vancouver, Buenos Aires, Singapore) |
| 2 | `Non-U.S.` suffix present but country = United States (direct contradiction) | 8 | Country corrected to the actual country (Dublin→Ireland, Haifa→Israel, Jerusalem→Israel, Tel Aviv→Israel, Vancouver→Canada) |
| 3 | Wrong country for a clearly correct location | 8 | Each investigated individually — see corrections below |
| 4 | Garbled location names (two cities merged) | 3 | New Delhi+New York City, Luxembourg+Raleigh, Melbourne+Victoria — each resolved by identifying which value was correct |
| 5 | Location literally `Non-U.S.` with no city name | 3 | BitMEX (Seychelles) set to `Unknown`; WeDoctor confirmed as Hangzhou via external source |
| 6 | International cities never given the suffix at all | 2 | Nicosia (Cyprus), Trondheim (Norway) — suffix added |

**Major correction made during the process:** the very first pass at Category 1 included **Brisbane** as a "missing suffix" case, assuming the single non-suffixed Brisbane row was simply Brisbane, Australia entered inconsistently. External verification found that **Arch Oncology Inc. is headquartered in Brisbane, California, USA** — a real, distinct city. The row was correct exactly as originally entered. The fix was reverted and Brisbane was explicitly excluded from the bulk suffix-correction query. **Lesson: a single-occurrence row is a candidate for investigation, not an automatic error — "more likely a mistake" is a probability, not a certainty, and low-frequency values must be checked against an external source before changing them.**

**Other Category 3 corrections required external verification rather than the dataset alone:**
- Wayfair (Boston/Germany row): confirmed via online sources that Wayfair's Berlin Germany office was shut down in 2025 (720 jobs, ~3% of global workforce) as a separate event from the Boston entry. The Boston row's country was corrected to United States to match its own location field, since the Berlin layoffs are a distinct event captured elsewhere in the dataset.
- GupShup, Bright Machines, eBay (SF Bay Area/India/Israel rows): sources confirmed layoffs affected remote or international teams, but no specific city was reported in any source. Per project rule, ambiguous distributed cuts were standardized to the company's HQ location rather than left with an unverifiable foreign city.
- Jellysmack (New York City/France row): the 22 layoffs were reported as a global total spanning both US and France teams with no city-level breakdown available — standardized to the New York City HQ entry for the same reason.

### Text Encoding Issues

Several international city names were corrupted by a UTF-8 encoding error during the original CSV import — special characters were double-encoded into garbled byte sequences.

| Garbled Value | Corrected To | Country |
|---|---|---|
| `MalmÃ¶` / `Malmo` | Malmö | Sweden |
| `DÃ¼sseldorf` / `Dusseldorf` | Düsseldorf | Germany |
| `WrocÅ‚aw` | Wrocław | Poland |
| `FÃ¸rde` | Førde | Norway |

After these fixes, the `, Non-U.S.` suffix was removed from all location values dataset-wide using `REPLACE()`. The suffix was the dataset's original convention for flagging non-US cities, but with a clean, fully-corrected `country` column now in place, the suffix became redundant noise — removing it produces cleaner city names for EDA and visualization.

### Type Conversions

| Column | Before | After | Notes |
|--------|--------|-------|-------|
| `date` | TEXT `'6/12/2026'` | DATE | Enables YEAR(), MONTH(), DATEDIFF() |
| `total_laid_off` | TEXT `'50.0'` | INT | Correct type for headcount |
| `funds_raised` | TEXT | DECIMAL(12,2) | Truncated 1 row (Eatsy, value 0.9755 → 0.98) — accepted as negligible |
| `percentage_laid_off` | TEXT | DECIMAL(5,4) | Truncated 1 row (Airy Rooms) — accepted as sufficient precision |

### Columns Removed

| Column | Reason |
|--------|--------|
| `source` | URL string — no analytical value |
| `row_num` | Helper column for duplicate detection — job complete |
| `layoffs_data_missing` | Helper flag — rows already deleted, flag no longer needed |
| `date_added` | Redundant against `date` for analytical purposes |

### Final Dataset

| Metric | Value |
|--------|-------|
| Final row count | ~3,730 |
| Final column count | 7 (company, location, total_laid_off, date, percentage_laid_off, industry, stage, funds_raised, country) |

---

## Outliers — Identified, Not Removed

344 rows exceed the IQR upper fence of 440 employees (Q1=40, Q3=200, IQR=160). These are **not errors** — they represent large-scale layoffs from major companies (Oracle 30,000; Intel 22,000; Google 12,000 etc.) and are among the most analytically significant events in the dataset. Flagged and documented, never removed.

---

## Summary of All Lessons Learned

1. **Define "duplicate" precisely before counting** — a hash over the wrong column set hides true duplicates.
2. **Self-joins for NULL-filling are only safe for company-level constants** — industry qualifies, country does not.
3. **Low-frequency values are investigation candidates, not automatic errors** — Brisbane, California proved a single occurrence can be entirely correct.
4. **External verification matters** — several country corrections (Wayfair/Berlin, WeDoctor/Hangzhou) relied on information not present in the dataset itself.
5. **Encoding issues can hide as "unknown" cities** — what looked like garbled junk text was recoverable once recognized as a UTF-8 double-encoding pattern.
