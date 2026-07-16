# Multi-reel / multi-film compatibility checking — spec (draft, no code yet)

This is a design spec, not an implementation. Nothing in this file is
`\include`d by anything. It exists to write down what was actually
tested and confirmed while investigating the feature, so a future
implementation pass doesn't have to re-derive it, and so the real
constraints (some of them hard LilyPond/MIDI limitations, not just
"needs more code") are visible before committing to an approach.

**Context:** this project is eventually intended to be multi-channel —
several films, each with their own reel/score today, playing
*simultaneously* (e.g. a multi-screen installation). That raises a new
question none of the current library addresses: given Film 1's reel and
Film 2's reel, each independently composed with its own `\cueStartTime`
and its own tempo, how do you check that their soundtracks actually work
*together* when played at once?

Two use cases were named:

1. **"Unite"** — import/align music from one reel into another by
   matching absolute movie timecode, to inspect (visually, and/or by
   ear) whatever is sounding across films at the same real moment.
2. **Splitting one multi-instrument score into per-film reels** by
   which layer/film each instrument belongs to.

Use case 2 needs no new design: this is exactly what LilyPond's own tag
system (`\tag`/`\keepWithTag`/`\removeWithTag`) and its part-extraction
conventions already do — tag each instrument's music by which film it
belongs to, then build each film's reel/`\score` keeping only its own
tag. Nothing here is project-specific; it's textbook LilyPond. The rest
of this document is entirely about use case 1.

---

## 1. What was actually tested

Everything below was compiled and checked (rendered PDF and/or parsed
MIDI bytes directly), not just read about — same standard as the rest of
this library's design notes.

### 1a. `\quoteDuring`/`\cueDuring` align by absolute moment from the top
of each score — not by a sequential "consumed so far" cursor

Confirmed with a source quote of five one-measure-long, distinctly
pitched whole notes (C, D, E, F, G) and a destination with rests then
two separate `\quoteDuring` calls (one for 2 measures, a gap, then one
for 1 more measure). If `\quoteDuring` tracked "how much of this quote
have I consumed so far, across all calls," the second call would
continue where the first left off (predicting F). It didn't — it
produced G. Checking the actual destination-moment position at each
call (1 measure of leading rest, then the 2-measure call, then another
1-measure rest, then the 1-measure call) lines up exactly with reading
the **same absolute position** out of the source: destination position
4 (in whole notes from the top of the destination score) pulled source
measure 5. In other words: `\quoteDuring "name" music` reads the quoted
material at *whatever moment position the calling context has already
reached from its own top*, using that as a direct index into the quote's
own top-relative timeline. It is not a bookmark/cursor system; it's pure
positional alignment.

This matters a great deal here: it means `\quoteDuring`/`\cueDuring`
only line up two different pieces of music correctly if **both sides
already share the same moment-from-top axis** — true by construction for
the textbook use case (cueing another instrument's line into a rest in
the *same* score), false in general for two independently composed
reels with different `\cueStartTime` offsets and different tempos.

### 1b. Two simultaneous staves with independent `\tempo` marks conflict
by default — confirmed, and confirmed fixable

```lilypond
\new StaffGroup <<
  \new Staff { \tempo 4 = 60  ... \tempo 4 = 90  ... }
  \new Staff { \tempo 4 = 72  ... \tempo 4 = 100 ... }
>>
```
produces `warning: conflict with event: tempo-change-event` /
`discarding event` — LilyPond's `Metronome_mark_engraver` is `\Score`-
scoped by default, so only one staff's tempo marks actually get engraved
when two fire at once. Moving it to `\Staff` fixes the *visual* problem
completely (confirmed: both staves then show their own independent
tempo marks, no warnings):
```lilypond
\layout {
  \context { \Score \remove "Metronome_mark_engraver" }
  \context { \Staff \consists "Metronome_mark_engraver" }
}
```

### 1c. MIDI export does NOT preserve two simultaneous, independently-
tempo'd staves — this is a hard Standard MIDI File constraint, not a
LilyPond bug, and 1b's fix does not touch it

Built a two-staff score: "Film A" padded to start at 0:10 (`\tempo 4 =
60`), "Film B" padded to start at 0:04 (`\tempo 4 = 90`), applied 1b's
per-staff engraver fix, exported `\midi{}`, and parsed the raw bytes.
The note *onset ticks* were correct proof that the padding/alignment
idea itself works (Film A's first note-on lands at tick 3840, Film B's
at tick 1536 — exactly 10s and 4s respectively **at each staff's own
declared tempo**). But the tempo *meta-events* from both staves all
landed in a single shared track 0, merged in tick order (60bpm at t=0,
90bpm at t=1536, 60bpm again at t=3840) — meaning a MIDI player applies
**one global tempo timeline to the whole file**, not one per staff.
Practical effect: playing this MIDI back would NOT sound like Film A
staying at 60bpm throughout while Film B stays at 90bpm — it would sound
like the whole piece changing tempo globally at each of those tick
positions, since Standard MIDI File tempo meta-events are global by
format, regardless of which track/channel they came from. There is no
per-staff or per-track tempo override to reach for here; this isn't
solvable by any engraver trick, because it isn't a LilyPond limitation —
it's how the SMF format works.

### 1d. Consequence: a single combined `\Score` is only really valid
**near an explicit alignment point** — not for a whole piece

LilyPond requires every simultaneous staff in one `\Score` to agree on
notated duration at each barline (that's fundamental, not
project-specific). The leading-`\skip` alignment trick (see §2) gets the
*start* of two reels correctly lined up in real time. But after that,
each staff advances at its own tempo, and nothing keeps two
independently-tempo'd staves' *later* barlines corresponding to the same
real second unless the two reels' tempi happen to relate simply enough
across the same notated span (essentially never true for two
independently composed films). So: a combined score is a legitimate,
useful tool for eyeballing/spot-checking *around* a known moment (a cue
point, a hit, a shared silence) — not a trustworthy full-piece
"real-time accurate" rendering. This caveat needs to travel with the
feature, not just live in this file.

---

## 2. Proposed feature, part 1 — alignment padding (MVP, buildable today, near-zero new code)

The "line up reel B's start against a shared composite clock" half of
this problem is **already solved** by the existing `\cueGapTo` machinery
— it just needs a new, very small usage pattern, not new engraver/Scheme
code. `\cueGapTo "compositeEpoch" "reelOwnStart" {}`, called with **empty
preceding music**, is exactly "how much silence gets us from the
composite's epoch to this reel's own real start" — which is precisely
the alignment pad needed:

```lilypond
%% compositeEpoch is any shared reference instant you pick — e.g. "0:00"
%% for whatever moment both films' projectors/players start rolling together.
\new StaffGroup <<
  \new Staff \with { instrumentName = "Film 1" } {
    \cueGapTo "0:00" "12:00" {}   % Film 1's reel starts at composite 12:00
    \reelOneMusic
  }
  \new Staff \with { instrumentName = "Film 2" } {
    \cueGapTo "0:00" "12:05.5" {} % Film 2's reel starts at composite 12:05.5
    \reelTwoMusic
  }
>>
```

Confirmed end-to-end in §1c's test (the tick-position math was exactly
right). A thin convenience wrapper (`\cueUniteAlign` or similar, just
`\cueGapTo` with a fixed empty third argument) would be a nice-to-have
so callers don't need to remember the empty-`{}` idiom, but isn't
functionally necessary — this is genuinely a documentation/UX detail,
not new logic.

**Also required, every time this pattern is used:** the per-staff
`Metronome_mark_engraver` context mod from §1b, or the second (and any
later) reel's tempo marks silently vanish with a warning.

**Explicitly out of scope for this to "just work":** `\cueTime` itself.
`TIMING-MANUAL.md`'s own FAQ already documents that this library's clock
is one-per-`\Score`, shared by every staff in it — confirmed still true,
and now doubly relevant, since a composite score has *multiple*
independently-offset reels that each want their own clock. Don't expect
`\cueTime` to give correct per-film timecodes inside a composite score
without new engraver work (see §5).

---

## 3. Proposed feature, part 2 — spot-quoting a short excerpt (secondary tool, more new code, more limited scope by design)

For "what is Film 2 doing during this specific 8 bars of Film 1,"
`\quoteDuring`/`\cueDuring` (§1a) are the right primitive — but only if
we do the alignment math ourselves before handing them a moment
position, since they won't do it for us. New Scheme needed, essentially
the mirror image of `cue-gap-elapsed-seconds` (which converts "how much
notated music" → "how many real seconds, given a tempo map"): this needs
"how many real seconds *into a target reel*" → "how much notated moment
that corresponds to," i.e. walking the target reel's own tempo map
forward accumulating real seconds until reaching the requested target,
then reporting the notated moment reached. Call it (working name)
`cue-quote-moment-at` — same tree-walk shape as `cue-gap-elapsed-seconds`
in `timing.ily`, run in the opposite direction.

Proposed usage (a NEW, throwaway/spot-check file — not inside a real
reel):
```lilypond
\addQuote "film2-vn" \film2ReelVn

\new Staff {
  \cueQuoteAt "film2-vn" "<<film2's own cueStartTime>>" "<<target composite timecode>>" { R1*4 }
}
```
`\cueQuoteAt` would: parse both timecodes, compute the elapsed-seconds
target relative to film 2's own start, walk film 2's registered quote
music to find the matching notated moment (the new "inverse" walker
above), emit a leading `\skip` of that many moments (so `\quoteDuring`'s
own top-of-score alignment, §1a, lines up on the right spot), then call
`\quoteDuring`/`\cueDuring` with the caller-given placeholder rhythm.

This is deliberately scoped to short, one-off excerpts in a dedicated
checking file, not something meant to run live inside a production reel
— the moment this file's own position stops being "a handful of rests
leading up to one quote," the alignment-drift problem from §1d applies
here too.

**Free bonus, not yet needed:** `\quoteDuring`/`\transposedCueDuring`
already auto-transpose a quoted line by the difference between the
quoted material's own registered `instrumentTransposition` and the
calling context's — relevant once this project's winds
(`instruments.ily`) actually get used, no extra work required for that
part.

---

## 4. Recommended primary workflow for actual audio compatibility checking: don't combine in LilyPond at all

Given §1c (SMF tempo tracks are global, full stop), the most reliable
way to actually **hear** whether two films' soundtracks clash is *not* a
combined LilyPond score's MIDI export. Each reel today already renders
its own `\midi{}` correctly, independently, using its own real tempo
map. The robust approach is:

1. Render each film's reel to its own MIDI (already possible, no new
   code) or eventually audio.
2. Combine them **outside LilyPond** (a script, or dropping both files
   into a DAW/timeline tool), placing each file's start at its own
   `\cueStartTime` offset on a shared real-time axis.

This sidesteps the SMF single-tempo-track limitation entirely, because
mixing pre-rendered audio/MIDI on a real-time axis doesn't care about
notated moments or tempo maps at all — only wall-clock seconds, which
each reel already gets right on its own. This should be the headline
recommendation for "does the combined soundtrack work," with the
combined-`\Score` approach (§2) positioned as a notation-level spot-check
tool, not the thing that answers that question end to end.

---

## 5. Explicitly speculative / not scoped yet

- **Automated clash detection** (e.g. a Scheme pass flagging simultaneous
  `ff` dynamics across films, overlapping pitch classes, both films
  silent at once, etc.) — plausible given this library's existing
  warning-driven style, but needs a concrete definition of "clash" from
  whoever's actually reviewing these scores before it's worth building.
  Not attempted here.
- **A genuinely multi-clock `\cueTimeEngraver`** so `\cueTime` works
  correctly per-staff inside a composite score — `timing.ily`'s own
  design note already flags "one clock per Score" as a known limitation,
  not something this spec resolves. Would need real engraver work
  (likely: move it from `\Score` to `\Staff`, same shape as §1b's fix,
  then re-verify every case in `timing-test-suite.ly` still holds
  per-staff) — worth doing only if the composite score itself becomes a
  real deliverable rather than a spot-check tool.
- **Full real-time-accurate notated composite** (re-notating both reels'
  rhythms onto one shared moment axis so barlines stay real-time-exact
  for the whole piece, not just at the initial pad) — technically
  possible (a bigger version of the "inverse tempo-map walk" from §3)
  but a substantial undertaking; not recommended unless a literal
  synchronized paper score (not just an audio check) turns out to be a
  real requirement.

## 6. Open questions for whoever's actually running the installation

- Do the films' clocks drift independently once started (in which case
  even "aligned at 0:00" reels go out of sync over a long piece, and no
  amount of LilyPond engineering fixes that — it's a projection/hardware
  sync question), or is there a hard shared clock across channels? This
  changes how much precision part 1/2 above are even worth chasing.
- Is a literal notated composite score actually wanted by anyone (a
  conductor, an installer double-checking against a spec), or is
  "renders to correct MIDI/audio, mixed externally" (§4) sufficient?
  That answer decides whether §5's harder items are worth ever picking
  up.
