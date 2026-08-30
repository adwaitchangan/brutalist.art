# RENDER-TARGETS.md — brutalist.art renders; it does not publish

**Rule-owner for: where a master goes, and how 9:16 is made.**
Companion to `CLAUDE.md` rule 5 ("Never publish") — this file says what the
toolkit *does* do instead.

---

## 1 · The boundary

brutalist.art turns **a beat sheet into a 4K master.** That is the whole job.

Staging, ledgers, channel credentials, playlists, uploads — **none of that lives
here.** They belong to whatever publishing system you run downstream, which reads
finished files out of a folder. The toolkit never needs to know that system exists.

The author's own setup (a `TOPOST/` staging folder, per-channel OAuth creds, an
upload ledger) is **one person's downstream choice**, not part of this toolkit and
not a path you inherit by downloading it.

## 2 · Where a master lands

A clean 4K final is written to the first of these that is set:

| Order | Target | Use |
|---|---|---|
| 1 | `--out DIR` | explicit, always wins — one-off renders, a shared drive, a Google Drive mount |
| 2 | `$ART_OUT` | your standing render folder, set once in `.env` |
| 3 | `<toolkit>/renders/` | built-in default, so a fresh clone works with zero configuration |

```bash
./art final <reel>                          # → $ART_OUT, else brutalist.art/renders/
./art final <reel> --out ~/Drive/4K         # → anywhere, including a mounted drive
```

`renders/` is gitignored. A `--review` cut is a *working artifact* and always stays
beside the reel — only the clean final follows the target above.

**4K is the default.** `./art final` renders 2160p unless you pass `--height`.
Code lanes (Remotion, Manim) are born at 4K and are never upscaled.

## 3 · 9:16 is a DIFFERENT beat sheet

A vertical cut is **not** a crop of the wide one. `shorts.py` derives a short into
its own `short/` folder with **its own `beat_sheet.json`**, and that sheet is
rewired to portrait components:

- If `Root.tsx` registers a composition named `<Pattern>916`, the short's sheet is
  **rewired to it** and the beat re-renders portrait. Props must satisfy the 916
  composition's own zod schema.
- If no `916` composition exists, the beat is **flagged** — add the composition, or
  drop a `pantry/<beat>-916.mp4|png`. It is not silently center-cut.
- Generated graphics are never center-cut. Only captured/user media is, biased by
  `shot.focus`, written as `<beat>-916.*` beside the source so it stays inspectable
  and replaceable. `pantry/<beat>-916.*` beats everything.

Portrait compositions currently registered here:

`ClaudeTitleOutro916` · `ClaudeVerdictArtifact916` · `ClaudeWindow916` ·
`ContactSheet916` · `FormACard916` · `FormBCard916` · `LookPlate916` ·
`SleeperAgents*916` · `Values*916` · `Want*916`

Authoring a new portrait variant is one component file registering both ids —
`<Name>` at 3840×2160 and `<Name>916` at 2160×3840 (`REMOTION-STANDARDS.md`,
dual-aspect law). Ratio-encoded legacy names (`*169.tsx`) are frozen; never add one.

## 4 · What this means for a downloader

You need no account, no key, and no upload permission to get a finished 4K file.
Set `ART_OUT` (or pass `--out`) and render. What happens to the file afterwards is
entirely yours.
