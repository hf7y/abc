#!/usr/bin/env bash
# check-cue-naming.sh
# Lint for the exact bug class already found (and fixed/flagged) twice in
# this repo's history: a cue or reel file copy-pasted from another one,
# with some internal reference left un-renamed.
#   - 2m1.ily's variable names (oneMone_vn etc.) still say "1M1" even
#     though its own header opus field says "2M1" (see TODO.md).
#   - 2m.ly's own header/comments still say "reel1.ly"/"Reel 1" even
#     though the file is named 2m.ly (see TODO.md).
#
# This is a standalone, read-only script -- it edits nothing, and not
# running it changes nothing about how any reel/cue file behaves. Delete
# it any time with zero effect on the actual project. Run it from the
# repo root:
#
#   ./check-cue-naming.sh
#
# Exit status: 0 if no mismatches found, 1 if any were reported.

set -u
cd "$(dirname "$0")"

# Number -> spelled word, matching this project's existing convention
# (oneMone, twoMone -- "M" for the cue's own "M" in "1M1"/"2M1", spelled
# out because LilyPond identifiers can't start with a digit).
number_word() {
  case "$1" in
    1) echo "one" ;;   2) echo "two" ;;   3) echo "three" ;;
    4) echo "four" ;;  5) echo "five" ;;  6) echo "six" ;;
    7) echo "seven" ;; 8) echo "eight" ;; 9) echo "nine" ;;
    10) echo "ten" ;;
    *) echo "" ;;
  esac
}

found_issue=0

echo "== Checking cue files (*m*.ily) for variable-name / opus mismatches =="
for f in [0-9]*m[0-9]*.ily; do
  [ -e "$f" ] || continue

  # Filename-derived reel/cue numbers, e.g. "2m1.ily" -> reel=2 cue=1
  base="${f%.ily}"
  reel_num="${base%%m*}"
  cue_num="${base##*m}"

  reel_word=$(number_word "$reel_num")
  cue_word=$(number_word "$cue_num")
  if [ -z "$reel_word" ] || [ -z "$cue_word" ]; then
    echo "  SKIP $f -- number_word doesn't cover reel $reel_num or cue $cue_num (extend check-cue-naming.sh's number_word table)"
    continue
  fi
  expected_prefix="${reel_word}M${cue_word}"

  # opus header field, e.g. opus = "2M1"
  opus=$(grep -m1 -oP 'opus\s*=\s*"\K[^"]+' "$f")
  expected_opus="${reel_num}M${cue_num}"
  if [ -n "$opus" ] && [ "$opus" != "$expected_opus" ]; then
    echo "  MISMATCH $f: opus is \"$opus\" but filename implies \"$expected_opus\""
    found_issue=1
  fi

  # Variable definitions, e.g. "oneMone_vn = " -- collect distinct prefixes
  prefixes=$(grep -oP '^\s*\K[A-Za-z]+(?=_(vn|vci|vcii|cb)\s*=)' "$f" | sort -u)
  if [ -z "$prefixes" ]; then
    echo "  SKIP $f -- no _vn/_vci/_vcii/_cb variable definitions found"
    continue
  fi
  bad_prefixes=$(echo "$prefixes" | grep -v "^${expected_prefix}\$")
  if [ -n "$bad_prefixes" ]; then
    echo "  MISMATCH $f: expected variable prefix \"$expected_prefix\", found: $(echo "$bad_prefixes" | tr '\n' ' ')"
    found_issue=1
  fi
done

echo ""
echo "== Checking reel files (*m.ly) for stale copy-pasted headers =="
for f in [0-9]*m.ly; do
  [ -e "$f" ] || continue
  base="${f%.ly}"
  reel_num="${base%m}"
  # Any OTHER reel number's filename or "Reel <n>" text appearing inside
  # this file is a strong signal of an un-updated copy-paste.
  for g in [0-9]*m.ly; do
    [ "$g" = "$f" ] && continue
    other_base="${g%.ly}"
    if grep -qF "$other_base" "$f"; then
      echo "  MISMATCH $f: contains \"$other_base\" (looks like a copy-paste from $g that wasn't fully updated)"
      found_issue=1
    fi
  done
  other_reel_pattern='[Rr]eel [0-9]+'
  match=$(grep -oP "$other_reel_pattern" "$f" | head -1)
  if [ -n "$match" ]; then
    match_num=$(echo "$match" | grep -oP '[0-9]+')
    if [ "$match_num" != "$reel_num" ]; then
      echo "  MISMATCH $f: says \"$match\" but this is reel $reel_num"
      found_issue=1
    fi
  fi
done

echo ""
if [ "$found_issue" -eq 0 ]; then
  echo "No naming mismatches found."
else
  echo "Mismatches found above. These are your composition's content, not"
  echo "a library bug -- fix them (or don't) at your own discretion."
fi
exit "$found_issue"
