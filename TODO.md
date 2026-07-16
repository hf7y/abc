# TODO / bug tracker

Running log of known issues so bug-fixing can happen in batches without
derailing whatever else is in progress. Add a line whenever you notice
something instead of stopping to fix it; come back to the "Open" section
when you're ready to do a pass.

Convention: each entry names where the bug lives, what's wrong, and how
to re-check it after a fix (usually a `lib/core/test-suite.ly` score
number — compile that file and look at the referenced score).

## Open

- **cues: `2m1.ily` still has `1m1.ily`'s variable names.** `2m.ly` calls
  `\twoMone_vn`, `\twoMone_cb`, etc., but `2m1.ily` defines `oneMone_vn`,
  `oneMone_cb` (its header comment even still says `%%% 1m1.ily`) —
  looks like it was copy-pasted as a starting template and never
  renamed. `2m.ly` currently fails to compile because of this (only
  `cbTrack` is active there, and it references `\twoMone_cb`, which
  doesn't exist). Fix: rename the `oneMone_*` definitions in `2m1.ily` to
  `twoMone_*` (or decide the whole file needs different content — it's
  your composition, not a library bug).

- **reel: `2m.ly` itself still says "Reel 1" / "reel1.ly".** Line 1's
  comment (`%%% reel1.ly`) and the `\header { title = "Reel 1" }` inside
  it are both stale copy-paste from `1m.ly` — same root cause as the
  `2m1.ily` entry above, just in the reel file instead of the cue file.
  Found by (and now automatically caught by) `check-cue-naming.sh` at
  the repo root — run it after adding or editing any reel/cue file; see
  `lib/project/reel-template.ly` and `cue-template.ily` for a
  copy-paste-safe starting point that avoids this class of mistake by
  construction (placeholders instead of plausible-looking real values).

- **lib: legacy `\square`/`\half-harmonic` vs. new `\squareHead`/`\halfHarmonic`.**
  `1m1.ily`, `1m2.ily`, `2m1.ily` still use the old prefix-function forms
  (`\square d,1`) ~40 times. The new suffix forms
  (`lib/core/strings.ily`) are strictly more capable — chord-member
  independence, StringStaff-scoped — and are the ones any future piece
  pulling from this library should use. Migrating the existing cues is
  mechanical (delete the `\square `/`\half-harmonic ` prefix, append
  `\squareHead`/`\halfHarmonic` as a suffix on the same note) but touches
  real music content, so it's deliberately not done automatically.
  Decide whether/when to do that pass; re-check with test-suite.ly
  score 2b either way.

## Resolved

- **2026-07-16 — `notation.ily`'s own usage comment for `\sp`/`\ord`/`\st`
  showed syntax that doesn't actually work.** It said "Suffix usage:
  `c4\sp d\ord e\st`" — confirmed empirically that the bare form is
  silently dropped ("Ignoring non-music expression"), because these are
  plain markups, not events; a direction indicator is required
  (`c4^\sp`). Found while writing `lib/core/MANUAL.md` and testing every
  example before publishing it. Fixed the comment in place.

- **2026-07-16 — `test-suite.pdf`'s explanatory text was silently clipped
  at the page margin, and the actual PDF sitting in the repo was ~5 hours
  stale.** The user opened `lib/core/test-suite.pdf` directly and
  reported it "doesn't show the right behavior." Two independent causes,
  neither a library bug:
  1. Every compile that session had been run into scratch directories —
     the PDF actually sitting next to the source in `lib/core/` was from
     partway through the fixing process, before several of the fixes
     above landed. Lesson: when a test artifact lives in the repo, keep
     it current in place, not just in scratch copies.
  2. Independent of staleness, the descriptive text above each score
     (`\markup \wordwrap-lines { \bold "..." "..." }`) never actually
     wrapped — it silently ran off the page edge with no warning, for
     two stacked reasons: `\wordwrap-lines` only wraps *between*
     markup-list items, not within a single quoted string (each quoted
     string is one atomic item to it); and being a markup-*list*
     command, it needed `\markuplist` as the entry point and
     `\override-lines` for line-width, not the singular `\markup` /
     `\override` I'd used. This meant nobody — not the user, and not me
     if I'd looked at the actual file instead of scratch renders — could
     read most of the "Expect: ..." text to check the page against it.
     Root-caused by testing each wrong-but-plausible guess directly
     (`\override` alone, explicit tiny `line-width`, bare top-level
     `\markup`) rather than assuming any of them worked. Fixed with a
     `wordwrap-text` helper (splits a plain Scheme string into one-word
     markups before handing it to `\markuplist \wordwrap-lines`) — see
     the comment in `test-suite.ly`. All 29 header blocks rewritten
     shorter and now fully readable within the page margin on a fresh
     visual pass across every page.

- **2026-07-15 — scordatura silently no-opped for an unreachable written
  pitch, with zero feedback.** If a written pitch is below the lowest
  open string (or otherwise unreachable on every string of the standard
  tuning), `str-lowest-fret-string` correctly returns `#f` and the
  engraver correctly skips transposing it — but did so completely
  silently, so a composer with a stray out-of-range note in a scordatura
  passage would see it render at written pitch with no explanation of
  why. The unknown-instrument path already warned
  (`ly:warning ... "unknown instrument"`); this was the same class of
  gap on the pitch side. Added a matching `ly:warning` naming the
  unreachable pitch. Re-check: `test-suite.ly` score 6g (check the
  compile log for both warnings, not just the page — neither error path
  is visually distinguishable from a normal note by design, since both
  correctly leave the note at its written position).

- **2026-07-15 — `frame-engraver.ily` never activated its own grob
  types.** `\frameStart`/`\frameEnd` failed with "No grob definition
  found for `Frame`" unless something else (previously, an unrelated
  line in the project's `style.ily`) also applied
  `\grobdescriptions #all-grob-descriptions` to `\Global`. Fixed by
  moving that activation into `frame-engraver.ily` itself,
  self-contained. Re-check: `test-suite.ly` score 10.

- **2026-07-15 — explicit `\N` string numbers were silently ignored by
  scordatura/string-color engravers.** Both engravers read
  `'string-number` directly off the note event, but LilyPond represents
  an explicit `\4` as a separate `StringNumberEvent` living in the
  note's articulations list — the direct read always returned `#f`, so
  every explicit-string-number code path silently fell through to the
  pitch-guessing heuristic instead. (Scordatura transposition still
  looked right in casual testing because the heuristic happened to agree
  for open-string pitches; string coloring by explicit number was
  visibly broken — always black, never colored.) Fixed via
  `str-explicit-string-number` in `strings.ily`, which reads the
  `StringNumberEvent` correctly. Re-check: `test-suite.ly` score 7
  (first note should be red, not black).

- **2026-07-15 — scordatura sounding-mode accidentals, alto/tenor clef
  staff position: previously flagged "unverified," now verified
  working.** Confirmed empirically (not just by reading the code):
  transposed accidentals render correctly including same-measure
  suppression and sharp-cancelled-to-natural; alto-clef staff position
  matches a plain (non-scordatura) scale note-for-note. No code change
  was needed for either — they already worked. Re-check: `test-suite.ly`
  scores 4, 5, 6.

- **2026-07-15 — suffix contact articulations (`\squareHead`,
  `\halfHarmonic`, `\air`) implemented, in two passes — the first pass
  had a real bug that a visual check missed.** Pass 1: registered the
  custom articulation types into `scriptDefinitions` with a no-op
  stencil so the built-in Script engraver doesn't also try (and fail) to
  interpret them — this got chords working
  (`<c\squareHead g\halfHarmonic e>`) and *looked* like it got bare
  (non-chord) notes working too. It hadn't: the visual check used
  quarter notes, and our filled-box override is nearly indistinguishable
  from a default filled quarter notehead at a glance, so a completely
  broken bare-note path went unnoticed. Confirmed broken via
  `\displayMusic` and an instrumented engraver: LilyPond folds a chord
  member's articulation into that specific note's own `'articulations`,
  but a bare note's articulation instead broadcasts as an independent
  event and is absent from the note's own cause — two different
  delivery mechanisms depending on syntax, not a variation of the same
  one. Pass 2 (the actual fix): `contactNoteheadsEngraver` now also
  listens for the independent broadcast and stages it for the very next
  note-head in the same timestep. See the design note and the
  engraver's own comment in `lib/core/strings.ily`. Re-check:
  `test-suite.ly` score 2b — bare whole notes (visually distinct from
  default noteheads, unlike quarter notes) for all three types, a chord
  with three independently contact-marked members, and real
  articulations/dynamics coexisting in the same passage. General
  takeaway logged here because it'll apply beyond this one bug: when
  visually verifying a notehead override, pick a duration where the
  override doesn't resemble the default (turned out quarter notes DO
  distinguish fine — square corners vs. oval curve — but only if you
  zoom in enough to see the outline; a glance at a whole page won't
  show it).

- **2026-07-15 — contact articulations on bare notes in a multi-Voice
  Staff silently mis-set to the wrong shape.** Direct consequence of the
  pass-2 fix above: `contactNoteheadsEngraver`'s `pending` staging is a
  single queue. Staff-scoped (its original placement, alongside
  scordatura/string-colors), two simultaneous Voices sharing one queue
  both resolved to whichever articulation type had higher priority —
  confirmed by rendering two Voices with different bare articulations
  and getting two identical shapes instead of two different ones. Fixed
  by moving the engraver onto a new StringVoice context (Voice-derived,
  mirroring how StringStaff derives from Staff) so each Voice gets its
  own `pending` closure. `StringStaff`'s `\defaultchild` is `StringVoice`
  so this is transparent for ordinary single-voice writing (which is
  100% of current usage) — multi-voice StringStaff content needs
  `\new StringVoice` instead of `\new Voice` to get contact-articulation
  support per voice. Re-check: `test-suite.ly` score 2e.

- **2026-07-15 — invisible Script grobs (from the scriptDefinitions
  no-op stencil trick) warned during slur layout.** "Ignoring grob for
  slur: Script. avoid-slur not set?" the first time a slur or tie
  crossed a contact-articulated note — the empty-stencil Script grob
  still participated in slur-avoidance calculations. Fixed by adding
  `(avoid-slur . ignore)` to each entry in `contactScriptDefinitions`.
  Re-check: `test-suite.ly` score 2d (ties and slurs across
  contact-articulated notes, previously warned, now silent).

- **2026-07-15 — a tie across two scordatura-transposed sounding-mode
  notes rendered with NO tie curve at all** (not just a warning — this
  one was visually broken, caught during a from-scratch integration test
  built specifically to exercise real musical combinations, not isolated
  features). Root cause: `Tie_engraver` is Voice-scoped and was already
  in Voice's default consist list before `scordaturaEngraver`'s
  Staff-level `\consists` — so on any given pair of tied notes,
  `Tie_engraver` compared the first note's cause pitch (already mutated
  to the sounding pitch, since our engraver had already run for that
  note) against the second note's cause pitch (not yet mutated at the
  point `Tie_engraver` read it) and never found a match. Fixed by moving
  `scordaturaEngraver` onto the `StringVoice` context (alongside
  `contactNoteheadsEngraver`) with `Tie_engraver` explicitly removed and
  re-added afterward, so it always sees both notes post-mutation.
  Re-check: `test-suite.ly` score 6j.

  Two more bugs surfaced applying that fix, both caught before shipping
  by recompiling immediately rather than trusting the edit:
  - `scordaturaEngraver` ended up `\consist`ed on *both* `StringStaff`
    and `StringVoice` (forgot to delete the old one), so every note got
    transposed twice — first correctly, then again by the second
    acknowledgment, using the already-transposed pitch as if it were the
    written one. Symptom: spurious "written pitch F# is not reachable"
    warnings on notes that were never written as F# — the engraver was
    looking at its own prior output. Fixed by deleting the stale
    `\consists \scordaturaEngraver` off `StringStaff`.
  - While moving the engraver, `scordaturaMode`/`scordaturaActive`/etc.
    were briefly given their own default values on `StringVoice` too.
    Confirmed empirically (see `strings.ily`'s comment on this) that a
    context's own default for a property shadows a parent's `\set`
    entirely — `\set Staff.scordaturaMode = #'sounding` would have
    silently done nothing, because `StringVoice` had its own `'fingered`
    default that `ly:context-property` found first without ever walking
    up to Staff. Fixed by declaring these properties exactly once, on
    `StringStaff`, and leaving `StringVoice` to inherit them.

- **2026-07-15 — test-tuning hygiene: several cello scordatura test
  tunings had wrong octave marks on strings 1/2/3** (e.g. `a,` instead of
  `a` for string 1's override pitch). Never affected any actual rendered
  result — string assignment (explicit or heuristic) always resolves
  against the real built-in tuning, not the user-supplied tuning-music
  argument, so the octave error only would have mattered for a note
  actually assigned to string 1 or 2, which no test exercised. Fixed for
  hygiene/clarity anyway, since a future reader could easily copy the
  wrong pattern.
