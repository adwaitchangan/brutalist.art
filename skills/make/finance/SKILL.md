---
name: finance
description: >
  Fully-templatized financial-filings reels on the ai-explainer chassis. Same
  ELEVEN beats, same five charts, same order, every company, every quarter —
  nothing is chosen at build time except the ticker, because GAAP already fixed
  the shape. Data comes from SEC EDGAR's XBRL JSON APIs, so no figure is ever
  retyped: ticker to CIK, then companyfacts for every tagged fact, then frames
  for a real sector population. Shape logic is locked — flow gets a Sankey
  (income statement, cash flow), a snapshot gets a mirrored bar (balance sheet),
  composition over time gets a stacked bar (segments) — and picking otherwise is
  a factual misrepresentation, not a style choice. Two independent deterministic
  audits gate every render: AUDIT-RECONCILE (the charts against their own
  arithmetic) and AUDIT-SOURCE (every rendered number against its XBRL fact).
  Both FAIL the build. Use when the user types `finance <TICKER>`, or asks to
  break down a public company's latest financials. Never publishes.
---

# finance — reading a public company's filings

The first fully-templatized modifier. Every other explainer needs judgment about
*what shape teaches this idea*. This one does not: three statements, three
structures, filed on a schedule, tagged in a standard vocabulary. **The template
is not a shortcut — it is the accounting standard, rendered.**

Which also inverts the failure mode. Nothing here is "did the model pick a good
visual." Everything is "does the number on screen equal the number in the
filing" — deterministic, machine-verifiable, twice.

## Trigger

`finance <TICKER>` · optional `--form 10-Q`

## Which filing

| Form | What it is | Use |
|---|---|---|
| **10-K** | Annual. **Audited.** Full statements + segment notes. | **The default.** |
| **10-Q** | Quarterly. **Unaudited.** Q1–Q3 only; Q4 folds into the 10-K. | The quarterly cut. |
| **8-K** | Current report. Earnings releases arrive here as Exhibit 99.1, weeks earlier. | **Never as primary** — unaudited, often non-GAAP. |
| **20-F** | Annual for foreign private issuers. | 10-K substitute for non-US filers. |

If only an 8-K exists for the period, say so on screen and label every figure
*unaudited, company-reported*. Never blend an 8-K figure into a 10-K chart
without marking it.

## Data — EDGAR XBRL, Rung 1, never retyped

```
https://www.sec.gov/files/company_tickers.json                      ticker -> CIK
https://data.sec.gov/submissions/CIK##########.json                 filing index
https://data.sec.gov/api/xbrl/companyfacts/CIK##########.json       every tagged fact
https://data.sec.gov/api/xbrl/frames/us-gaap/<Tag>/USD/CY####Q#I.json   sector population
```

CIK is zero-padded to 10 digits.

**Two hard requirements or it fails:**

- **A User-Agent naming your org and a contact email.** Without it SEC returns **403**.
- **10 requests/second maximum.** Sleep ~0.12s between calls or you get 429s.

Every fact carries its own `accn`, `form`, `fy`, `fp`, `end` — on-chart
provenance for free. Write the pull to `data/facts.json`; **charts read only from
that file.** No numeric constant is ever typed into a component.

## The eleven beats

| # | Beat | Visual |
|---|---|---|
| B01 | COLD OPEN — "break down COMPANY's latest financials" | composer → filing header |
| B02 | EXECUTIVE SUMMARY — BLUF, the shape of the year | headline stat card |
| B03 | THE SOURCE — form, period, filed date, accession number | provenance card |
| B04 | INCOME STATEMENT | **Sankey** |
| B05 | CASH FLOW — sources converge, uses diverge | **Sankey** |
| B06 | BALANCE SHEET | **mirrored bar** |
| B07 | SEGMENTS | **stacked bar** |
| B08 | VS SECTOR | **dot-plot distribution** |
| B09 | WHAT TO LOOK OUT FOR — concentration, one-offs, GAAP vs non-GAAP, estimates | annotated callouts |
| B10 | YOUR TURN | composer |
| B11 | OUTRO | title restate |

**No beat is ever dropped.** A company with no segment disclosure still renders
B07 and says so — a filer who never trips the 10%-customer threshold has thereby
proven no customer exceeds ~10% of revenue. *Absence of disclosure is a finding.*
Dropping a beat reintroduces the per-reel guessing this modifier removes.

## Shape logic, locked

**Flow → Sankey. Snapshot → mirrored bar. Composition × time → stacked bar.**

A balance sheet is **never** a Sankey: ribbons read as motion, and a viewer's gut
reading of a balance-sheet Sankey is "assets become liabilities," which is false.

Sankeys cannot draw negative-width ribbons. A net cash outflow is handled by
including a real, disclosed inflow (beginning cash) so every ribbon stays
positive. **Never invent a number to force positivity.**

## Palette

Page `#FAF9F5`, ink `#3D3929`, rule `#D8D2C4`.

**Terracotta `#D97757` is reserved for the subject company only** — its dot, its
bars, nothing else.

Data series use the measured CVD-safe set: black `#000000` (totals), blue
`#0072B2` (profit/inflow), vermilion `#D55E00` (cost/outflow), yellow `#F0E442`
(other/adjustment). **A 1px keyline `#1a1a1a` on every fill is mandatory** —
yellow measures 1.1:1 on cream and is invisible without it.

Estimates render with a dashed border, always.

## B08 — the comparator rule

Do not improvise per company. Take the subject's SIC code from its submissions
JSON, pull the same GAAP tag across that SIC via `frames`, keep filers with
revenue ≥ 10% of the subject's, require at least 5, cap at 8 for legibility. If
fewer than 5 qualify, widen to the 2-digit SIC group **and say so on the chart**.
Label with tickers plus a key.

**Let the subject land wherever it actually lands** — including not first. Two
hand-picked peers is cherry-picking with extra steps.

## The two audits — both deterministic, both fail the build

**AUDIT-RECONCILE — the charts against themselves.** Income statement columns
reconcile · cash-flow sources sum equals uses sum, no negative ribbon · balance
sheet assets equals liabilities plus equity, **computed from line items, not a
stored total** · each period's segments sum to that period's total AND periods
sum to the fiscal-year total · every non-terminal Sankey node's inflow equals
outflow.

**AUDIT-SOURCE — the charts against EDGAR.** Every rendered number equals its
XBRL fact by tag and value · every back-solved figure is dashed AND listed in
B09 · grep the components for hard-coded numerics and fail if any exist.

They are independent by construction: one checks internal arithmetic, the other
checks external truth. They cannot fail the same way.

Plus the render gate: no overflow, no truncation, and **no bar wider than its
track** — a 71.1% value in a 70%-wide track is a hard fail, not a clip.

## Known trap — the template does not fit banks

The income-statement Sankey assumes revenue → COGS → gross profit. **Banks have
no COGS**; they have net interest income. Insurers run on premiums and reserves;
REITs headline funds-from-operations. Running this template across the S&P 500
would render structurally meaningless charts for the financial and real-estate
sectors.

The **Nasdaq-100 excludes financials by construction**, which makes it the better
batch target. For financials, write a second template — do not force banks
through this one.

## Never

Never publish. Never spend. Never render past a failed audit.
