#!/usr/bin/env bash
# SETUP.sh — brutalist.art dependency checker and smoke-test runner
# Run from the brutalist.art root: ./SETUP.sh
# Never auto-installs anything without prompting.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

MISSING_DEPS=()
ALL_PASS=true

# ─── helpers ─────────────────────────────────────────────────────────────────

get_version() {
  local cmd="$1"
  case "$cmd" in
    node)    node --version 2>/dev/null | tr -d '\n' ;;
    npm)     npm --version 2>/dev/null | tr -d '\n' ;;
    python3) python3 --version 2>/dev/null | awk '{print $2}' ;;
    ffmpeg)  ffmpeg -version 2>/dev/null | head -1 | awk '{print $3}' ;;
    manim)   manim --version 2>/dev/null | head -1 | tr -d '\n' ;;
    kokoro)  python3 -c "import kokoro; print(getattr(kokoro,'__version__','installed'))" 2>/dev/null || echo "installed" ;;
    *)       echo "—" ;;
  esac
}

check_dep() {
  local name="$1"
  local cmd="$2"
  local found=false
  local version="—"

  if command -v "$cmd" &>/dev/null 2>&1; then
    found=true
    version=$(get_version "$cmd" 2>/dev/null || echo "—")
  fi

  if $found; then
    printf "  %-16s ${GREEN}%-12s${NC} %s\n" "$name" "FOUND" "$version"
  else
    printf "  %-16s ${RED}%-12s${NC} %s\n" "$name" "MISSING" "—"
    MISSING_DEPS+=("$name")
    ALL_PASS=false
  fi
}

check_kokoro() {
  local name="kokoro"
  local version="—"
  if python3 -c "import kokoro" 2>/dev/null; then
    version=$(python3 -c "import kokoro; print(getattr(kokoro,'__version__','installed'))" 2>/dev/null || echo "installed")
    printf "  %-16s ${GREEN}%-12s${NC} %s\n" "$name" "FOUND" "$version"
  else
    printf "  %-16s ${RED}%-12s${NC} %s\n" "$name" "MISSING" "—"
    MISSING_DEPS+=("kokoro")
    ALL_PASS=false
  fi
}

check_font() {
  local name="$1"
  local found=false

  # Check via fc-list (Linux/mac with fontconfig)
  if command -v fc-list &>/dev/null; then
    if fc-list 2>/dev/null | grep -qi "$name"; then
      found=true
    fi
  fi

  # Also check common macOS font dirs
  if ! $found; then
    for dir in "$HOME/Library/Fonts" "/Library/Fonts" "/System/Library/Fonts" "/usr/share/fonts"; do
      if [ -d "$dir" ] && ls "$dir" 2>/dev/null | grep -qi "$name"; then
        found=true
        break
      fi
    done
  fi

  if $found; then
    printf "  %-16s ${GREEN}%-12s${NC} %s\n" "$name" "FOUND" "—"
  else
    printf "  %-16s ${RED}%-12s${NC} %s\n" "$name" "MISSING" "—"
    MISSING_DEPS+=("font:$name")
    ALL_PASS=false
  fi
}

# ─── install prompts ──────────────────────────────────────────────────────────

prompt_install() {
  local name="$1"
  local install_cmd="$2"
  echo ""
  echo "  Install command: ${BOLD}${install_cmd}${NC}"
  printf "  Install %s? [y/N] " "$name"
  read -r answer
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo "  Running: $install_cmd"
    eval "$install_cmd"
    echo "  Done."
  else
    echo "  Skipped."
  fi
}

# ─── smoke test ───────────────────────────────────────────────────────────────

run_smoke_test() {
  echo ""
  echo "${BOLD}── Smoke Test ────────────────────────────────────────────────${NC}"

  # Find an example mp4 to probe, or attempt a minimal compile
  local test_mp4=""
  local smoke_dir=""

  # Look for any existing compiled mp4 in examples/
  test_mp4=$(find "$SCRIPT_DIR/examples" -name "*.mp4" 2>/dev/null | head -1 || true)

  if [ -z "$test_mp4" ]; then
    # Try to compile the smallest example beat sheet
    local example_reel="$SCRIPT_DIR/examples/ai-explainer/claude-liam-algorithmic-art"
    if [ -f "$example_reel/beat_sheet.json" ] && command -v python3 &>/dev/null; then
      echo "  No compiled mp4 found in examples/; attempting minimal smoke render..."
      smoke_dir="$example_reel"
      # Run art run on the example (best-effort — may fail if manim/remotion not ready)
      if cd "$SCRIPT_DIR" && ./art run "$smoke_dir" 2>&1 | tail -5; then
        test_mp4=$(find "$smoke_dir/mp4" -name "*.mp4" 2>/dev/null | head -1 || true)
        if [ -z "$test_mp4" ]; then
          test_mp4=$(find "$smoke_dir" -name "*.mp4" 2>/dev/null | head -1 || true)
        fi
      fi
    fi
  fi

  if [ -z "$test_mp4" ]; then
    echo "  ${RED}SMOKE RENDER: FAIL — no mp4 to probe (compile failed or examples not rendered)${NC}"
    echo "  To produce a test render: cd $SCRIPT_DIR && ./art run examples/ai-explainer/claude-liam-algorithmic-art"
    GATE_AUDIO="FAIL — no mp4"
    GATE_TYPE="FAIL — no mp4"
    GATE_VERIFY="FAIL"
    ALL_PASS=false
    return
  fi

  echo "  Probing: $test_mp4"

  # ── GATE TYPE: file exists and > 100 KB
  local filesize_bytes filesize_kb
  filesize_bytes=$(stat -f%z "$test_mp4" 2>/dev/null || stat -c%s "$test_mp4" 2>/dev/null || echo "0")
  filesize_kb=$(( filesize_bytes / 1024 ))
  if [ "$filesize_kb" -gt 100 ]; then
    GATE_TYPE="${GREEN}PASS${NC} — ${filesize_kb} KB"
    echo "  GATE TYPE:   ${GREEN}PASS${NC} (${filesize_kb} KB > 100 KB minimum)"
  else
    GATE_TYPE="${RED}FAIL${NC} — ${filesize_kb} KB (must be > 100 KB)"
    echo "  GATE TYPE:   ${RED}FAIL${NC} (${filesize_kb} KB — below 100 KB minimum)"
    ALL_PASS=false
  fi

  # ── GATE VERIFY: valid video stream
  local probe_json verify_ok=false
  if command -v ffprobe &>/dev/null; then
    probe_json=$(ffprobe -v quiet -of json -show_streams "$test_mp4" 2>/dev/null || echo '{}')
    if echo "$probe_json" | python3 -c "
import json,sys
d=json.load(sys.stdin)
streams=d.get('streams',[])
video_streams=[s for s in streams if s.get('codec_type')=='video']
sys.exit(0 if video_streams else 1)
" 2>/dev/null; then
      verify_ok=true
    fi
    if $verify_ok; then
      GATE_VERIFY="${GREEN}PASS${NC} — valid video stream"
      echo "  GATE VERIFY: ${GREEN}PASS${NC}"
    else
      GATE_VERIFY="${RED}FAIL${NC} — no valid video stream"
      echo "  GATE VERIFY: ${RED}FAIL${NC}"
      ALL_PASS=false
    fi
  else
    GATE_VERIFY="${YELLOW}SKIP${NC} — ffprobe not found"
    echo "  GATE VERIFY: ${YELLOW}SKIP${NC} (ffprobe not available)"
  fi

  # ── GATE AUDIO: mean_volume > -40 dB
  if command -v ffprobe &>/dev/null; then
    local audio_info mean_vol
    audio_info=$(ffprobe -v quiet -of json -show_streams "$test_mp4" 2>/dev/null || echo '{}')
    # Use ffmpeg volumedetect filter
    local vol_output
    vol_output=$(ffmpeg -i "$test_mp4" -af volumedetect -f null - 2>&1 || true)
    mean_vol=$(echo "$vol_output" | grep mean_volume | awk '{print $5}' | tr -d 'dB' || echo "")

    if [ -n "$mean_vol" ]; then
      # Compare: pass if mean_volume > -40 (i.e., louder than -40 dB)
      local pass_audio
      pass_audio=$(python3 -c "print('PASS' if float('$mean_vol') > -40.0 else 'FAIL')" 2>/dev/null || echo "UNKNOWN")
      if [ "$pass_audio" = "PASS" ]; then
        GATE_AUDIO="${GREEN}PASS${NC} — ${mean_vol} dB (threshold: > -40 dB)"
        echo "  GATE AUDIO:  ${GREEN}PASS${NC} (${mean_vol} dB)"
      else
        GATE_AUDIO="${RED}FAIL${NC} — ${mean_vol} dB (must be > -40 dB)"
        echo "  GATE AUDIO:  ${RED}FAIL${NC} (${mean_vol} dB — below -40 dB threshold)"
        ALL_PASS=false
      fi
    else
      # No audio track — check if there are audio streams at all
      local has_audio
      has_audio=$(echo "$audio_info" | python3 -c "
import json,sys
d=json.load(sys.stdin)
streams=d.get('streams',[])
audio_streams=[s for s in streams if s.get('codec_type')=='audio']
print('YES' if audio_streams else 'NO')
" 2>/dev/null || echo "UNKNOWN")
      if [ "$has_audio" = "NO" ]; then
        GATE_AUDIO="${YELLOW}SKIP${NC} — no audio stream in file (silent/visual-only)"
        echo "  GATE AUDIO:  ${YELLOW}SKIP${NC} (no audio stream — silent or visual-only render)"
      else
        GATE_AUDIO="${RED}FAIL${NC} — could not measure volume"
        echo "  GATE AUDIO:  ${RED}FAIL${NC} (could not measure volume)"
        ALL_PASS=false
      fi
    fi
  else
    GATE_AUDIO="${YELLOW}SKIP${NC} — ffprobe not found"
    echo "  GATE AUDIO:  ${YELLOW}SKIP${NC} (ffprobe not available)"
  fi
}

# ─── main ─────────────────────────────────────────────────────────────────────

echo ""
echo "${BOLD}brutalist.art — Dependency Check${NC}"
echo "════════════════════════════════════════════════════════"
printf "  %-16s %-12s %s\n" "DEPENDENCY" "STATUS" "VERSION"
printf "  %-16s %-12s %s\n" "──────────" "──────" "───────"

check_dep    "node"     "node"
check_dep    "npm"      "npm"
check_dep    "python3"  "python3"
check_dep    "ffmpeg"   "ffmpeg"
check_dep    "manim"    "manim"
check_kokoro
check_font   "EB Garamond"
check_font   "Oswald"

echo ""

# ─── install prompts for missing deps ────────────────────────────────────────

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
  echo "${BOLD}── Missing Dependencies ──────────────────────────────────────${NC}"
  for dep in "${MISSING_DEPS[@]}"; do
    case "$dep" in
      node)
        echo "  node: Install via https://nodejs.org or:"
        prompt_install "node" "brew install node"
        ;;
      npm)
        echo "  npm comes with node. Re-run after installing node."
        ;;
      python3)
        prompt_install "python3" "brew install python3"
        ;;
      ffmpeg)
        prompt_install "ffmpeg" "brew install ffmpeg"
        ;;
      manim)
        echo "  manim requires pip + system deps."
        prompt_install "manim" "pip3 install manim"
        ;;
      kokoro)
        prompt_install "kokoro" "pip3 install kokoro soundfile"
        ;;
      "font:EB Garamond")
        echo "  EB Garamond: Download from https://fonts.google.com/specimen/EB+Garamond"
        echo "  Then drag the .ttf files into ~/Library/Fonts/ (macOS)."
        printf "  Open font download page? [y/N] "
        read -r ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
          open "https://fonts.google.com/specimen/EB+Garamond" 2>/dev/null || true
        fi
        ;;
      "font:Oswald")
        echo "  Oswald: Download from https://fonts.google.com/specimen/Oswald"
        echo "  Then drag the .ttf files into ~/Library/Fonts/ (macOS)."
        printf "  Open font download page? [y/N] "
        read -r ans
        if [[ "$ans" =~ ^[Yy]$ ]]; then
          open "https://fonts.google.com/specimen/Oswald" 2>/dev/null || true
        fi
        ;;
    esac
  done
fi

# ─── smoke test ───────────────────────────────────────────────────────────────

GATE_AUDIO="NOT RUN"
GATE_TYPE="NOT RUN"
GATE_VERIFY="NOT RUN"

run_smoke_test

# ─── summary ──────────────────────────────────────────────────────────────────

echo ""
echo "${BOLD}── Summary ───────────────────────────────────────────────────${NC}"
echo "  GATE AUDIO:  $GATE_AUDIO"
echo "  GATE TYPE:   $GATE_TYPE"
echo "  GATE VERIFY: $GATE_VERIFY"
echo ""
if $ALL_PASS; then
  echo "${GREEN}${BOLD}Package is READY.${NC}"
else
  echo "${RED}${BOLD}Package has ISSUES — see above.${NC}"
fi
echo ""
