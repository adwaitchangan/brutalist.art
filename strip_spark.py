#!/usr/bin/env python3
"""
strip_spark.py — remove the decorative Spark GLYPH from every Remotion scene.

What this removes: the 8-line asterisk/splat SVG that renders as a bullet before a
spark line, and its now-unused component definition.

What this KEEPS: the spark LINE ITSELF — the italic serif text. The SPARK-LINE LAW is
about the words being present, not about the glyph. Every place a glyph is deleted, the
text beside it survives untouched.

    python3 strip_spark.py --root <remotion/src> --dry
    python3 strip_spark.py --root <remotion/src> --apply

--apply copies every file it touches into <root>/../.spark-strip-backup/ first, preserving
relative paths, so the whole change is reversible with a single cp -R even though the repo
has uncommitted work in it.
"""

import argparse
import os
import re
import shutil
import sys

# Render sites: <Spark ... /> and <SparkIcon ... />, self-closing, possibly multiline.
RENDER = re.compile(r'[ \t]*<(?:Spark|SparkIcon)\b[^>]*?/>[ \t]*\n?', re.S)

# Inline glyphs: an <svg> whose body is 8 <line>s radiating from (12,12). This is the
# same asterisk written out longhand instead of via a <Spark/> component, so the render-site
# regex above never sees it. Matched on the geometry, not on a name.
INLINE = re.compile(
    r'[ \t]*<svg\b(?:(?!</svg>).)*?viewBox="0 0 24 24"(?:(?!</svg>).)*?'
    r'x1=\{12\}\s*y1=\{12\}(?:(?!</svg>).)*?</svg>[ \t]*\n?', re.S)

# Component definitions: `const Spark: React.FC<...> = (...) => ( ...svg... );`
# Anchored on the arrow-function-returning-JSX form used throughout this repo.
DEF = re.compile(
    r'(?:export\s+)?const\s+(?:Spark|SparkIcon)\s*:\s*React\.FC<[^=]*?=\s*\([^)]*\)\s*=>\s*\('
    r'.*?\n\);\n',
    re.S)


def process(text):
    """Return (new_text, n_renders_removed, n_defs_removed)."""
    new, nr = RENDER.subn('', text)
    new, ni = INLINE.subn('', new)
    nr += ni

    nd = 0
    # Only drop a definition once nothing references it any more.
    for name in ('SparkIcon', 'Spark'):
        pat = re.compile(
            r'(?:export\s+)?const\s+' + name + r'\s*:\s*React\.FC<[^=]*?=\s*\([^)]*\)\s*=>\s*\('
            r'.*?\n\);\n', re.S)
        m = pat.search(new)
        if not m:
            continue
        rest = new[:m.start()] + new[m.end():]
        # Comments keep a name "referenced" without using it, and a leftover unused
        # const fails the build under noUnusedLocals. Test against comment-stripped code.
        code = re.sub(r'\{/\*.*?\*/\}', '', rest, flags=re.S)
        code = re.sub(r'/\*.*?\*/', '', code, flags=re.S)
        code = re.sub(r'//[^\n]*', '', code)
        if re.search(r'\b' + name + r'\b', code):
            continue
        new = rest
        nd += 1

    # Collapse the blank-line runs a removal can leave behind.
    new = re.sub(r'\n{4,}', '\n\n\n', new)
    return new, nr, nd


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--root', required=True)
    ap.add_argument('--apply', action='store_true')
    ap.add_argument('--dry', action='store_true')
    a = ap.parse_args()
    if not (a.apply or a.dry):
        print('pick --dry or --apply'); return 2

    root = os.path.abspath(a.root)
    backup = os.path.join(os.path.dirname(root), '.spark-strip-backup')

    files, tot_r, tot_d = [], 0, 0
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in ('node_modules', '.spark-strip-backup')]
        for fn in filenames:
            if not fn.endswith('.tsx'):
                continue
            p = os.path.join(dirpath, fn)
            src = open(p, encoding='utf-8').read()
            # Case-sensitive \bSpark\b misses files whose only reference is the token
            # CLAUDE.SPARK — which is exactly the inline-glyph case. Widen the prefilter.
            if not (re.search(r'(?i)\bspark(?:icon)?\b', src) or INLINE.search(src)):
                continue
            new, nr, nd = process(src)
            if new == src:
                continue
            files.append((p, nr, nd))
            tot_r += nr
            tot_d += nd
            if a.apply:
                rel = os.path.relpath(p, root)
                bp = os.path.join(backup, rel)
                os.makedirs(os.path.dirname(bp), exist_ok=True)
                shutil.copy2(p, bp)
                open(p, 'w', encoding='utf-8').write(new)

    for p, nr, nd in sorted(files)[:25]:
        print(f"  {os.path.relpath(p, root):58s} renders-{nr} defs-{nd}")
    if len(files) > 25:
        print(f"  ... and {len(files) - 25} more")
    print(f"\nfiles touched : {len(files)}")
    print(f"glyphs removed: {tot_r}")
    print(f"defs removed  : {tot_d}")
    if a.apply:
        print(f"backup        : {backup}")
        print(f"restore with  : cp -R {backup}/. {root}/")
    else:
        print("(dry run — nothing written)")
    return 0


if __name__ == '__main__':
    sys.exit(main())
