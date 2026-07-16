# The timing.ily manual (for humans, not engravers)

This is a plain-language guide to `lib/project/timing.ily` — the part of
the library that tracks *movie time* (real seconds/minutes into the
film) as you write music, so you can print timecodes on the page, leave
correctly-sized silent gaps, and build a cue list automatically.

If you just want the terse "why does this work this way" version, read
the comments at the top of `timing.ily` itself. This document is the
"I just want to use it" version, with copy-pasteable examples.

Everything below is already loaded automatically — `\include
"./lib/includes.ily"` at the top of any score file (which every reel
file already has) gives you all of these commands for free.

---

## 1. The one idea you need before anything else

**A "reel" file (`1m.ly`, `2m.ly`, ...) is one continuous timeline. A
"cue" file (`1m1.ily`, `1m2.ily`, ...) is just a chunk of music that gets
pasted into that timeline.**

Concretely: `1m.ly` does this (simplified):

```lilypond
\include "./1m1.ily"
\include "./1m2.ily"

vnTrack = { \oneMone_vn  \oneMtwo_vn }   % 1M1's music, then 1M2's music
```

Because `1M2`'s music comes right after `1M1`'s in the same `Staff`,
LilyPond already knows exactly how much time separates them — it's just
"however long 1M1's notes take to play." **Concatenation is all the
bookkeeping timing.ily needs.** You never have to tell it "1M2 starts 47
seconds in" — it works that out from the actual notes, automatically.

This has one big consequence:

> **`\cueStartTime` (see below) goes in the *reel* file, called exactly
> once. Never inside an individual cue's `.ily` file.**

If every cue file tried to set its own start time, pasting them together
would make the second one silently stomp on the first one's real,
accumulated position. One reel, one `\cueStartTime`.

---

## 2. Quick start

Here's the smallest useful example — a cue that starts 3 minutes and 12.5
seconds into the film, with a timecode printed above a couple of notes:

```lilypond
\include "./lib/includes.ily"

\score {
  \new Staff \relative c' {
    \cueStartTime "3:12.5"   % this staff's own 0:00 = 3:12.5 in the movie
    \tempo 4 = 60
    c4\cueTime d e f |       % \cueTime prints the timecode at THIS note
    g4 a b c'\cueTime |
  }
}
```

Compile that and you'll see `3:12.500` above the first note and
`3:16.500` above the last one (4 quarter notes/second at 60bpm = 4
seconds later). That's the whole idea. Everything else in this manual is
a variation or an extension of this.

---

## 3. The commands

### `\cueTime` — "what time is it right now?"

Attach it to any note, chord, or rest (as a suffix, like an articulation)
and it prints the elapsed movie time at that exact point:

```lilypond
c4\cueTime d e f |
<c e g>1\cueTime |    % chords get ONE label, not one per note — correct
r1\cueTime |          % works on rests too
```

It reads whatever tempo you've marked with `\tempo` up to that point. If
you never write a `\tempo` at all, it assumes quarter = 60 (same default
LilyPond itself uses for MIDI).

**You don't need to do anything to activate this** — every `\Score`
already has the clock running in the background.

### `\cueStartTime "M:SS"` — "this is where the reel begins in the movie"

Put this at the very start of the music, in the reel file, once:

```lilypond
\cueStartTime "3:12.5"      % minutes:seconds
\cueStartTime "1:02:03.5"   % or hours:minutes:seconds, if you're past an hour
```

You can call it again *later* in the same piece if you need to manually
correct drift (say, you realize partway through that your estimate was
off by half a second) — the new value takes over from that point
forward, and anything printed earlier stays exactly as it was.

### `\cueTotalTime` — "how long is this whole reel?"

Same clock as `\cueTime`, but styled to stand out (bold, boxed), meant
for the very end of a reel so you can see its total runtime at a glance.

**Important:** attach it to a tiny *spacer* right after your last real
note, not to the last note itself — otherwise it reports the time at the
*start* of that note, not after it finishes:

```lilypond
c4 d e f |
s4\cueTotalTime     % <- spacer (silent, invisible), NOT the last real note
```

Any short duration works for the spacer (`s4`, `s8`, whatever) — it's
never actually seen or heard. (One thing that does NOT work: a
zero-length spacer like `s1*0` — LilyPond never creates a real position
for it, so the label silently fails to appear. Use a real, if tiny,
duration.)

### `\cueTocEntry "1M1" "Coin"` + `\cueTimeline` — building a cue list

`\cueTocEntry` is like `\cueTime`, except it doesn't print anything on
the page — instead it silently adds a line ("1M1 -- Coin -- 3:12.500")
to a list. `\cueTimeline` prints that whole list, usually at the front of
the reel:

```lilypond
\book {
  \markuplist \cueTimeline    % <- the cue list appears here

  \score {
    \new Staff \relative c' {
      \cueStartTime "3:12.5"
      c4\cueTocEntry "1M1" "Coin" d e f |
      ...
      \tempo 4 = 120
      d4\cueTocEntry "1M2" "Water" e f g |
      ...
    }
  }
}
```

This will print, at the top of the book:

```
1M1 -- Coin -- 3:12.500
1M2 -- Water -- 3:20.500
```

`\cueTocEntry` doesn't print a mark in the music itself — if you *also*
want the boxed rehearsal-style label in the score (like `\mark`), add
`\cueLabel "1M1"` right alongside it (that one comes from
`core/notation.ily`, not from here — they're independent, use either or
both).

**One gotcha:** if you put `\cueTocEntry` inside a `\repeat unfold`
block, it fires once *per repetition*, each with a different (correct)
time but the *same* label text — you'll get several identical-looking
lines. If you want one entry for the whole repeated passage, put the
`\cueTocEntry` outside/before the `\repeat`, not inside it.

### `\cueGapTo "reelStart" "target" \precedingMusic` — computed silence

Use this when the movie has a stretch with **no music** (dialogue, a
quiet scene, whatever) and you know exactly what timecode the next cue
needs to start at. Instead of you counting measures by hand, this
computes the silence for you and shows it as a normal, countable rest.

```lilypond
partA = { \tempo 4 = 60 c4 d e f | g4 a b c' | }   % 8 seconds of music
partB = { d4 e f g }   % no trailing "|" -- see note below

track = {
  \cueStartTime "0:00"
  \partA
  \cueGapTo "0:00" "1:15.0" \partA   % <- fill in silence up to 1:15.0
  \partB
}
```

(No `|` after `partB`'s notes: a gap like this will generally NOT land
exactly on a barline — that's the whole point of the invisible exact
remainder described below — so a bar check right after it would produce
a spurious "barcheck failed" warning. Harmless, but worth knowing about
before you see it.)

Both arguments to `\cueGapTo` are strings, and the third argument is
**everything already written since the reel started** — in the example
above, that's just `\partA`, because that's all that's happened so far.
If there were a `\partAA` before it too, you'd write `{ \partA \partAA
}`.

What you get: a normal multi-measure rest (with the measure count printed
above it, like `5`), long enough to land the very next note exactly on
your target timecode — even if that means a fraction of a measure is
silently absorbed as an invisible remainder you'll never see or hear.

**If you use this in a multi-instrument score** (violin + cello + bass,
say), call `\cueGapTo` separately in *each* staff, each time passing
*that staff's own* preceding music. Don't assume one call somehow covers
every instrument — LilyPond requires every simultaneous staff to agree on
duration at each barline anyway, so this is really the only way it can
work, but it's easy to forget when you're only thinking about one staff.

**If you mistype the target** (or the previous cue's music runs longer
than you expected, past the target), you'll get a clear warning in the
compile log and a harmless zero-length "gap" instead of a crash or a
silently wrong score. Fix the timecode (or shorten the preceding music)
and recompile.

### `\cueTempoTo unit "start" "target" \music` — computed tempo

The mirror image of `\cueGapTo`: use this when you've already written a
passage and it needs to land in a **fixed-length window** — a scene, an
action beat — no matter what tempo that turns out to require. Instead of
you doing the arithmetic (count the beats, divide by the seconds, do the
BPM math), this prints the `\tempo` mark for you:

```lilypond
partA = { c4 d e f | g4 a b c' | }   % 8 quarter notes, no \tempo yet

track = {
  \cueTempoTo 4 "0:00" "0:10" \partA   % 8 quarters must fit in 10s
}
```

This prints `\tempo 4 = 48` right before `partA`'s music (8 quarters in
10 seconds is 48bpm), so the passage plays out in exactly 10 seconds.

`unit` is a plain note-value duration, written exactly like the left
side of a normal `\tempo` command — `4` for quarter notes, `4.` for a
dotted quarter (compound meters), `8` for eighth notes, whichever your
passage's beat actually is. The two timecodes are a window's start and
end (same `"M:SS"` / `"H:MM:SS"` format as everywhere else in this
file); `\music` is the already-written passage that has to fit inside
that window.

**Metronome marks are whole numbers, so the computed tempo is rounded.**
For a short passage, that rounding can be an actually-noticeable amount
of drift — if rounding would put the passage's real duration more than
20ms off the target, you'll see an informational message in the compile
log reporting both numbers, e.g.:

```
cueTempoTo: rounded to 51 -- actual duration 9.412s vs. target 9.500s (drift 0.088s)
```

That's not a warning (nothing's wrong — this is just what whole-number
metronome marks cost you), just visibility into the actual number,
instead of a silent, invisible few-hundredths-of-a-second discrepancy.

**If `\music` already has its own `\tempo` mark inside it** (usually
from being copy-pasted out of a cue that had one), you'll get a real
warning: the mark `\cueTempoTo` prints will be overridden partway
through by the pre-existing one, so the passage won't uniformly take the
target duration past that point. Delete the stray `\tempo` from
`\music` (or, if it's deliberate — an intentional tempo change partway
through the passage — ignore the warning, but be aware the "fits exactly"
guarantee only holds up to that point).

**If the target isn't after the start, or `\music` has no notes in it
at all**, you'll get a warning and the music comes back completely
unmodified (no `\tempo` mark inserted) — same "loud failure, not a
silently wrong score" shape as `\cueGapTo`'s own negative-gap case.

### `\cueUseSmpteFps 24` — switch to film-style timecode

By default, timecodes look like `3:12.500` (minutes:seconds.milliseconds).
If you'd rather see standard SMPTE frame-based timecode
(`HH:MM:SS:FF`, matching what a picture editor or DAW shows), turn it on:

```lilypond
\cueUseSmpteFps 24     % 24 frames per second (film standard)
c4\cueTime d4\cueTime  % now prints 00:00:00:00, 00:00:01:00, ...

\cueUseSmpteFps ##f    % switch back to decimal M:SS.mmm
```

Common rates: `24`, `25`, `30`, `29.97`, `23.976`. This is plain frame
counting at whatever rate you give it — it does **not** implement
"drop-frame" timecode's skipped-frame-number convention used by some
NTSC workflows. Good enough to cross-reference against a spotting sheet;
not a substitute for exact drop-frame math if a specific delivery spec
requires it.

---

## 4. Putting it all together

This mirrors the real structure this project uses (see
`lib/project/reel-template.ly` for a fill-in-the-blanks copy of exactly
this):

```lilypond
\include "./lib/includes.ily"
\include "./3m1.ily"
\include "./3m2.ily"

vnTrack = { \threeMone_vn \threeMtwo_vn }
% ...same idea for vci/vcii/cb tracks

\book {
  \header { title = "Plunge"  composer = "Z.V. Pine" }

  \markuplist \cueTimeline

  \score {
    \new StaffGroup <<
      \new Staff \with { instrumentName = "Vn" } \relative c' {
        \cueStartTime "12:00"       % this reel starts at 12:00:00 in the film

        \cueLabel "3M1"
        \threeMone_vn

        %% dialogue scene here, no music, until 12:45
        \cueGapTo "12:00" "12:45" { \threeMone_vn }

        \cueLabel "3M2"
        \threeMtwo_vn

        s4\cueTotalTime
      }
      %% ...other staves, same tracks as always
    >>
  }
}
```

---

## 5. Troubleshooting / FAQ

**"My timecodes are all wrong / way too small or too large."**
Check whether you actually wrote a `\tempo` command. If there's none
anywhere, everything defaults to quarter = 60 — which might not be your
real tempo. Add the `\tempo` marking you actually intend.

**"I put `\cueStartTime` in my cue file (`3m1.ily`) and it seemed to
work, but something's off once I add a second cue."**
Move it to the reel file, called once, before the first cue's music. See
section 1 above — this is the single most important rule in this whole
system.

**"`\cueTotalTime` shows a time that's too early — missing the last
note's own length."**
You attached it to the last note itself, not to a spacer after it.
`\cueTime`/`\cueTotalTime` always report the time *at the start* of
whatever they're attached to. See the `\cueTotalTime` section above.

**"`\cueGapTo` isn't showing the number of measures I expected."**
Double-check the third argument is *exactly* everything played since the
reel's `\cueStartTime` — not just the most recent cue, if there were
earlier ones too.

**"I get a warning about a negative gap."**
Your target timecode is earlier than where the music has already
reached. Either the target is wrong, or the preceding music runs longer
than you thought it would — the warning is telling you these two numbers
disagree; that's real information, not just noise.

**"Can two different cue timelines run at once (like two independent
clocks in the same score)?"**
No — one clock per `\Score`, shared by every staff in it. If you
genuinely need that, this library doesn't support it as-is; ask before
assuming it's easy to add.

---

## 6. Quick reference

| Command | Where | What it does |
|---|---|---|
| `\cueTime` | suffix on a note/chord/rest | prints elapsed movie time |
| `\cueTotalTime` | suffix on a trailing spacer | prints the running total, styled to stand out |
| `\cueStartTime "M:SS"` | once, top of the reel | sets this reel's absolute start in the movie |
| `\cueTocEntry "label" "desc"` | suffix on a note | silently registers a line in the cue timeline |
| `\markuplist \cueTimeline` | anywhere in the `\book` | prints every `\cueTocEntry` registered so far |
| `\cueGapTo "start" "target" \music` | between cues | inserts exact silence to reach a known timecode |
| `\cueTempoTo unit "start" "target" \music` | before a passage | computes/prints the `\tempo` mark needed so `\music` fits the window |
| `\cueUseSmpteFps 24` / `##f` | anywhere | switches timecode display to/from SMPTE `HH:MM:SS:FF` |

See also: `\cueLabel "1M1"` (a plain boxed rehearsal mark, from
`core/notation.ily` — independent of everything above, but usually used
alongside `\cueTocEntry`).
