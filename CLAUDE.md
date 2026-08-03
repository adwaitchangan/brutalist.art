> **You are in `brutalist.art` (DOT) — the PUBLIC, shippable toolkit.**
> Siblings: `brutalist-art/` (Bear's sandbox) · `brutalist_art/` (website + YouTube).
> Changes here reach outside users. Different trees — never treat a separator as a typo.

# CLAUDE.md — brutalist.art

brutalist.art is a self-contained, free-only video explainer toolkit — 14 skills, no API keys required for the default tier.

---

## When the user types `help` or "what do you do?"

Respond with exactly this structure — do NOT flatten all skills to an equal list. The tiering is the point.

---

### What this is

brutalist.art is a free-to-run Brutalist video toolkit for Humanitarians AI fellows and collaborators. You get 14 skills, Kokoro TTS (local, free), Manim + Remotion rendering, and a phase-gated pipeline. No API keys for the default tier.

---

### FELLOW TIER — free, safe, start here

| Skill | Use this when | Example |
|---|---|---|
| `fellows` | You have a HAI fellow's video report (.mp4/.mov) and want a Claude-bookended reel | `./art fellows path/to/reel/` |
| `ai-explainer` | You want to explain a concept in the Claude desktop-app visual style (cream, warm ink, terracotta) | `./art ai-explainer "What is gradient descent?"` |
| `hai` | You need a Humanitarians AI Pragmatist-register reel from any text or beat sheet | `./art hai path/to/reel/` |
| `your-turn` | You want to close an existing reel with a structured handoff prompt for viewers | `./art your-turn path/to/reel/` |
| `duration-planner` | You need to size your content to a target length — or check if a beat is too long | `./art duration-planner path/to/reel/` |

---

### ADVANCED — Bear only

| Skill | Notes |
|---|---|
| `deep-explainer` | Multi-layered concept depth passes on the ai-explainer chassis (~20–25% vox body beats) |
| `cli-explainer` | Claude session + live code + output as a moving vox beat |
| `nbb` | NikBearBrown/Teardown register — uses ElevenLabs Bear voice (paid; requires ELEVENLABS_API_KEY) |

---

### PAID — REQUIRES EXPLICIT SPEND APPROVAL

⚠️ Never present these as default options to a fellow.

| Skill | Cost note |
|---|---|
| `explainer` | FLUX/nano-banana stills + ElevenLabs VO. Ask per step before any spend. |

---

### Not set up yet?

Run `./setup` first (add `--install` to install deps + fetch the Kokoro model). It verifies every dependency live — imports each Python module, runs `ffmpeg`/`ffprobe`, and synthesizes + decodes a real Kokoro test phrase — and tells you which features are READY.

---

## Rules

1. **Read the whole SKILL.md before building.** Every skill under `skills/make/` has a `SKILL.md` — it is doctrine, not a README. Read it completely.
2. **Audio-first.** Narration MP3s are generated and measured first (`runtime/scripts/generate_audio_kokoro.py`); their durations are the master clock. Never fix timing by hand — regenerate audio, recompile.
3. **GATE P binds.** A human signs `PEDAGOGY.md` ("VERDICT: PASS") before audio is generated. It is a quality gate, not a cost gate — audio here is free.
4. **Videos travel with their book.** Build into `<book>/youtube/<slug>/`, never into this toolkit folder. `examples/` holds study copies only.
5. **Verify renders by LOOKING at frames** (`_qc/` + qc-sheet), never by the mp4 probe alone. Render Remotion only via `runtime/scripts/remotion_scenes.py` (foreground) — never hand-roll `npx remotion render`.
6. **Never publish.** There is no publishing machinery here; the master stays in the reel folder.
7. **No money, ever (Fellow Tier).** If any step in the Fellow Tier appears to require a key or a paid service, stop — that is a bug in this toolkit, not a missing credential. The full-fat toolkit (paid voices, publishing, all 45+ skills) is `brutalist-art/` in the parent repo.
8. **Tier discipline.** ADVANCED skills require Bear's sign-off. PAID skills require explicit spend approval before every paid API call. Never escalate a fellow into the PAID tier by default.

## Skill reference

Full tier breakdown: `skills/TIERS.md`
All 14 skills on disk: `skills/make/` — `find skills/make -name SKILL.md | sort`

## Entry point

```bash
./art --list          # every skill
./art keys            # validate keys (FELLOW TIER: all free, no keys needed)
./art todo  <reel>    # per-video beat ledger
./art run   <reel>    # compile a review cut
./art final <reel>    # clean master (no beat markers)
```
