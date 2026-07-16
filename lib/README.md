# lib/

Notation library for this piece, split into two layers:

```
lib/
  includes.ily     ← public entry point (score files \include this only)
  core/            ← generic, zero ABC-specific content
  project/         ← this project's house style / instrumentation
```

## `core/` — promotable

Everything in `core/` is instrument-notation plumbing with no dependency
on this piece, this ensemble, or this project's house style: notehead
stencils, notation vocabulary (`\arrowSpan`, `\daln`/`\aln`, `\ss`, etc.),
frame notation, and the string-instrument library (contact articulations,
scordatura, string colors — see the header comment in `core/strings.ily`
for the design notes and a couple of empirically-verified LilyPond
quirks).

The plan is to eventually promote `core/` to its own repo (working name
`zly`) and pull it into future pieces as a git submodule, once there's a
second project that actually needs it. Until then it lives here. Because
`core/` has no outward dependencies, that promotion should just be:

```
git subtree split -P lib/core -b zly-export
# push zly-export to the new zly repo, then remove lib/core here and
# add it back as a submodule
```

Do not add anything ABC-specific into `core/` — if a function only makes
sense for this piece or this ensemble, it belongs in `project/`.

**New to this library? Read `core/MANUAL.md` first** — a plain-language,
example-driven usage guide (every example in it is verified to actually
compile). The header comments inside each `.ily` file are for whoever's
maintaining the library itself, not for day-to-day usage.

## `project/` — this piece only

- `instruments.ily` — clef/transposition shorthands for this ensemble
- `style.ily` — house `\paper`/`\layout` (margins, spacing, headers)
- `timing.ily` — chronological (movie-timecode) tracking for film cues:
  `\cueTime`, `\cueStartTime`, `\cueGapTo`, `\cueTempoTo`,
  `\cueTocEntry`/`\cueTimeline`, `\cueTotalTime`, `\cueUseSmpteFps`.
  **Read `TIMING-MANUAL.md` first**
  for plain-language usage with worked examples — the header comment in
  `timing.ily` itself is the deeper design writeup (including a real
  LilyPond bug found and worked around while building `\cueGapTo`), not
  a how-to.
- `MULTI-REEL-SPEC.md` — design spec (no code yet) for checking
  cross-film soundtrack compatibility once this project goes
  multi-channel (several films' reels playing at once). Covers what was
  actually tested of LilyPond's `\quoteDuring`/`\cueDuring`/MIDI export
  for combining independently-timed reels, and what does and doesn't
  work.

## Reel & cue conventions

This project's structure, confirmed from the real files: a **cue** file
(`1m1.ily`) defines bare music variables, no `\score` of its own. A
**reel** file (`1m.ly`) `\include`s one or more cues and concatenates
them into one continuous per-instrument `Staff`, inside one `\score`.
Concatenation is what makes `\cueTime` accumulate correctly across cues
with no extra bookkeeping — see the REEL/CUE OWNERSHIP note in
`timing.ily` for why `\cueStartTime` belongs in the reel file, called
once, and never inside an individual cue file.

Two real bugs so far have come from the same root cause — a reel or cue
file copy-pasted from an existing one, with some internal reference left
un-renamed (`2m1.ily`'s variable names, `2m.ly`'s own stale header — see
`TODO.md`). Two small, fully optional, fully reversible tools address
this directly:

- **`lib/project/reel-template.ly`** / **`cue-template.ily`** — copy
  either to the repo root as a starting point for the next reel/cue.
  Placeholders are marked `<<LIKE-THIS>>` so they're obviously wrong if
  left in, rather than a plausible-looking real value copied from
  whatever file was duplicated.
- **`check-cue-naming.sh`** (repo root) — a read-only lint script; run it
  after adding or editing a reel/cue file. It checks that each cue
  file's variable-name prefix matches its own `opus` header field, and
  that a reel file doesn't contain another reel's filename or a
  mismatched "Reel N" string. It already catches both bugs above.

None of this is enforced — the existing reels/cues work exactly as they
did before these were added, and deleting any of these three files
changes nothing else.

## `core/test-suite.ly`

Compiles standalone (no `project/` dependency) and exercises every module
in `core/`, including the cases that were previously flagged as
"unverified" in earlier drafts of this library (sounding-mode scordatura
accidentals, alto-clef staff position, explicit-vs-inferred string
colors). Run it after changing anything in `core/`.
