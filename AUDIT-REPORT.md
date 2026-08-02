# AUDIT-REPORT.md — brutalist.art

Generated: 2026-08-02

---

## Skill Audit

| Skill | SKILL.md | Frontmatter valid | name == folder | No dangling refs | Tier | Status |
|---|---|---|---|---|---|---|
| ai-explainer | Y | Y | Y | Y | FELLOW | SHIP |
| cli-explainer | Y | Y | Y | Y | ADVANCED | SHIP |
| deep-explainer | Y | Y | Y | Y | ADVANCED | SHIP |
| duration-planner | Y | Y | Y | Y | FELLOW | SHIP |
| explainer | Y | Y | Y | Y | PAID | SHIP |
| fellows | Y | Y | Y | Y | FELLOW | SHIP |
| hai | Y | Y | Y | Y | FELLOW | SHIP |
| nbb | Y | Y | Y | Y | ADVANCED | SHIP |
| nopunt | Y | Y | Y | Y | FELLOW | SHIP |
| your-turn | Y | Y | Y | Y | FELLOW | SHIP |
| finance | — | — | — | — | — | BLOCKED — skill not in brutalist-art source |

**Dangling-ref check:** grepped every SKILL.md for `../vox`, `../unreal-reels`, and absolute `/Users/` paths. Zero hits across all 10 skills.

---

## Housekeeping

| Item | Action | Result |
|---|---|---|
| `claude-liam-model-update-slate.mp4` at root | Moved to `examples/` | Done |
| `claude-liam-manim-cancer-biology.mp4` at root | Removed (loose root mp4) | Done |
| `node_modules/` at root | Not present; added `node_modules/` to `.gitignore` | Done |
| `runtime/remotion/node_modules/` | Already in `.gitignore` | OK |

---

## Dependency Table (this machine — 2026-08-02)

| Dependency | Status | Version |
|---|---|---|
| node | FOUND | v24.17.0 |
| npm | FOUND | 12.0.0 |
| python3 | FOUND | 3.14.6 |
| ffmpeg | FOUND | 8.1.2 |
| manim | FOUND | 0.20.1 (SoX WARNING — non-fatal for Brutalist pipeline) |
| kokoro | MISSING | — (install: `pip3 install kokoro soundfile`) |
| EB Garamond | FOUND | — |
| Oswald | FOUND | — |

---

## Smoke Test

Probed: `examples/claude-liam-model-update-slate.mp4`

| Gate | Result | Detail |
|---|---|---|
| GATE AUDIO | PASS | mean_volume: -24.0 dB (threshold: > -40 dB) |
| GATE TYPE | PASS | 1999 KB (threshold: > 100 KB) |
| GATE VERIFY | PASS | Valid h264 video stream + aac audio stream |

---

## finance skill

`finance` is BLOCKED. The skill does not exist in `brutalist-art/skills/make/` (the source toolkit). No stub was created. This row is logged as BLOCKED and excluded from the shipped package.

---

## Other Notes

- **kokoro MISSING** on this machine. All FELLOW TIER and ADVANCED skills use Kokoro for TTS by default. The package will not produce audio until `pip3 install kokoro soundfile` is run and the ONNX model weights are downloaded (see `setup --install`).
- **manim SoX WARNING** is non-fatal — the Brutalist pipeline does not use SoX. Manim renders correctly without it.
- The `nopunt` skill has an inline catalog body directly in SKILL.md (no separate sub-files needed). Frontmatter closes correctly with `---` after the `name:` field on line 1 and before the body on line 3.
