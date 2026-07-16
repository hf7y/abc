# The core/ library manual (for humans, not engravers)

This is a plain-language guide to `lib/core/` — the generic notation
library (no assumptions about this specific piece or ensemble). If
you're editing or extending the library itself, read the header comments
in each `.ily` file instead — they explain *why* things work the way
they do, including some real LilyPond quirks discovered along the way.
This document is the "I just want to use it" version, with
copy-pasteable examples. Every example below is real, working code
lifted from (or directly modeled on) `lib/core/test-suite.ly`, which you
can compile yourself at any time to see all of this rendered:

```
lilypond lib/core/test-suite.ly
```

Everything below is already loaded automatically by `\include
"./lib/includes.ily"` at the top of a score file.

---

## 1. What's in here

| File | What it gives you |
|---|---|
| `notation.ily` | General notation shorthand: technique text, hairpins, a text spanner, staff-line suppression, repeat barlines, a scordatura text label, cue labels |
| `strings.ily` | Everything string-instrument-specific: contact articulations (square/diamond noteheads), a full transposing scordatura system, string-number coloring |
| `frame-engraver.ily` | Boxes/repeat-barlines around a passage, with an extender line and optional bracket+text |
| `noteheads.ily` | Internal plumbing (notehead shapes) — you won't call anything in this file directly |

---

## 2. Quick start

```lilypond
\include "./lib/includes.ily"

\score {
  \new StringStaff \relative c' {
    c4^\sp d^\ord e^\st f^\sim |     % technique text
    g1~\daln | g1~\aln g1\! |        % dal niente / al niente hairpins
    a1\squareHead b1\halfHarmonic |  % contact-articulation noteheads
  }
}
```

`StringStaff` (instead of plain `Staff`) is what turns on the
string-specific features (contact articulations, scordatura, string
colors) — it behaves exactly like a normal `Staff` otherwise (clefs,
key signatures, dynamics, everything works as usual).

---

## 3. Notation vocabulary (`notation.ily`)

### Technique text: `\sp` `\ord` `\st`

Short italic labels for bow position (*pont.* / *ord.* / *tasto*).
**These need an explicit direction indicator** (`^`, `_`, or `-`) — they
are plain text, not a self-attaching event:

```lilypond
c4^\sp d^\ord e^\st |     % correct
c4\sp                     % WRONG -- silently does nothing, no warning shown on the page
                           % (compile log says "Ignoring non-music expression")
```

### `\sim` — a "sim." dynamic mark

Styled like a dynamic (aligns with hairpins). This one *is* a real
event, so it attaches on its own without a direction indicator, though
`^`/`_` still work if you want to force which side it prints on:

```lilypond
f4\sim
```

### `\daln` / `\aln` — circled-tip hairpins

*Dal niente* (grows from nothing) / *al niente* (fades to nothing) —
ordinary `\<`/`\>` hairpins with a small circle at the closed end:

```lilypond
g1~\daln | g1~\aln g1\! |
```

### `\arrowSpan` — a two-sided labelled spanner

A horizontal line with text at both ends and an arrowhead on the right,
commonly used for things like "(tasto) ---------> (ord.)":

```lilypond
a1^\arrowSpan #"(tasto)" #"(ord.)" b1\stopTextSpan |
```

Note the two arguments are Scheme strings (`#"..."`), and you have to
end it yourself with `\stopTextSpan` on whatever note you want the
spanner to reach.

### `\ss` — temporarily hide the staff

Wraps a chunk of music with the staff lines and ledger lines invisible,
then restores them:

```lilypond
\ss { c4 d e f }
```

### `\staffRepeat` — repeat barlines around one measure

```lilypond
\staffRepeat { g1 }
```

### `\scord "ADGD"` — a text-only scordatura label

Just prints a small "*scord.* ADGD" marking — no actual retuning. (For
the real transposing scordatura system, see section 5 below.)

```lilypond
a1\scord "ADGD"
```

### `\cueLabel "1M1"` — a boxed rehearsal-style mark

Meant for the start of a film cue:

```lilypond
\cueLabel "1M1"
```

This is purely a visual mark. If you also want the cue's *timecode*
tracked and listed automatically, that's `lib/project/timing.ily`'s
`\cueTocEntry`/`\cueTimeline` — see `lib/project/TIMING-MANUAL.md`. The
two are independent; use either or both.

---

## 4. String techniques (`strings.ily`) — contact articulations

Three suffix articulations, usable inside a `StringStaff`:

```lilypond
\new StringStaff {
  \clef bass
  c,1\squareHead | d,1\halfHarmonic | e,1\air |
}
```

| Command | Notehead |
|---|---|
| `\squareHead` | filled square (quarter+), open square (half/whole) |
| `\halfHarmonic` | filled diamond, at every duration |
| `\air` | same shape as `\squareHead` (extreme *sul ponticello*, beyond contact) |

They coexist fine with ordinary articulations, dynamics, and bowings in
the same passage:

```lilypond
f,4-.\p g,4-> a,4\downbow b,4\f
```

**Chords get independent shapes per note** — this is the whole reason
the suffix form exists instead of the older prefix form:

```lilypond
<g,\squareHead c\halfHarmonic e>1   % three different noteheads, one chord
```

**Multi-voice caveat:** if you write two simultaneous `\new Voice`s
inside one `StringStaff` and give each a different contact articulation
at the same beat, use `\new StringVoice` instead of `\new Voice` for
each one — otherwise both voices can resolve to the same (wrong) shape:

```lilypond
\new StringStaff <<
  \new StringVoice { \voiceOne \clef bass a1\squareHead }
  \new StringVoice { \voiceTwo \clef bass e,1\halfHarmonic }
>>
```

(A single-voice `StringStaff`, which is the overwhelming majority of
real usage, needs none of this — it works automatically.)

### The old prefix form (`\square`, `\half-harmonic`) — legacy only

You'll see this in some existing cue files. It still works, in *any*
`Staff` (not just `StringStaff`), but chord members can't be
independent — the whole chord gets the same shape:

```lilypond
\half-harmonic c,1 | \square d,1 |
\square <g, c>1     % BOTH notes go square -- no per-note control
```

Prefer the suffix forms (`\squareHead` etc.) for anything new.

---

## 5. Scordatura (`strings.ily`) — real transposition

This is a full "retune the strings, see the difference on the page"
system: write in the instrument's *normal* tuning, and the library shows
you either the written (fingered) pitch or the true sounding pitch under
a different tuning.

### Basic usage

```lilypond
\new StringStaff {
  \clef bass
  \withScordatura #'cello { a d g, des, } {
    c,1\4 g,1\3
  }
}
```

- The instrument symbol (`#'cello`, `#'violin`, `#'viola`, `#'bass`) tells
  it which built-in tuning to compare against.
- The tuning list is **string 1 (highest) to string N (lowest)**, with
  explicit octaves (`des,` not `des`).
- `\4`/`\3` are ordinary LilyPond string-number indicators — same syntax
  you'd use for guitar/violin fingering. They tell the library exactly
  which string a note is on, instead of it having to guess.

### Fingered vs. sounding display

By default (**fingered mode**) you see exactly what you wrote — no
transposition is shown, only the string numbers, which is what a
performer reading from scordatura notation actually wants:

```lilypond
\withScordatura #'cello { a d g, des, } {
  c,1\4     % prints as plain C, no accidental
}
```

Switch to **sounding mode** to see (for your own reference, or a score
for someone reading concert pitch) what note actually comes out:

```lilypond
\set Staff.scordaturaMode = #'sounding
\withScordatura #'cello { a d g, des, } {
  c,1\4     % now shows the TRANSPOSED pitch, with correct accidentals
}
\set Staff.scordaturaMode = #'fingered   % switch back when you're done
```

### `\unscordatura` — turn it off mid-block

If you need a few notes inside a `\withScordatura` block to NOT be
transposed:

```lilypond
\withScordatura #'cello { a d g, des, } {
  c,1\4
  \unscordatura
  c,1\4    % this one prints plain again
}
```

### Explicit string number always wins

If you don't give an explicit `\N`, the library *guesses* which string a
note is on (lowest fret that reaches it). This is a convenience, not a
substitute for telling it directly when it matters — give an explicit
`\N` whenever the guess could be ambiguous (e.g., a pitch reachable on
more than one string, or specifically on a string you've retuned).

### If something's misspelled

Unknown instrument symbol, or a written pitch that isn't reachable on
any string of the standard tuning: you get a clear warning in the
compile log and the note renders at its plain written pitch (no crash,
no silent wrong transposition).

---

## 6. String colors (`strings.ily`)

Color noteheads by which string they're on.

### By explicit string number

```lilypond
\set Staff.stringColorList = #strings-highlight-4   % string 4 = red, rest black
\withStringColors {
  c,1\4 g,1\3   % first note red, second stays black (no number = no color)
}
```

### By inference (needs a scordatura tuning in scope)

```lilypond
\withScordatura #'cello { a d g, c, } {
  \withStringColorsInferred {
    c,1 d,1 g,1 a,1   % colored by the SAME lowest-fret guess used elsewhere
  }
}
```

### Built-in color schemes

`strings-all-black`, `strings-highlight-1` (string 1 = red),
`strings-highlight-2`, `-3`, `-4`, `strings-highlight-1-4` (1 and 4 both
red), `strings-highlight-all`, `strings-rainbow` (default — black, royal
blue, forest green, dark orchid for strings 1-4).

### Custom colors

```lilypond
\set Staff.stringColorList = #(list (cons 1 (x11-color 'DeepPink))
                                     (cons 2 (x11-color 'Gold))
                                     (cons 3 black)
                                     (cons 4 (x11-color 'Cyan4)))
```

---

## 7. Frame notation (`frame-engraver.ily`)

Draws a box (or repeat-barlines) around a passage, with a line
continuing after it (optionally arrow-tipped).

**One-time setup** — this needs an engraver added to `Voice`. This
project's own house style (`project/style.ily`) already does this
everywhere; if you're using `core/` standalone (no `project/`), do it
yourself once:

```lilypond
\layout {
  \context {
    \Voice
    \consists \frameEngraver
  }
}
```

### Basic usage

```lilypond
\frameStart c4 d e \frameEnd f |
g4 a \frameExtenderEnd b c |
```

`\frameStart ... \frameEnd` draws the box. `\frameExtenderEnd` marks
where the line after it should stop.

### Options

```lilypond
\once \override FrameBracket.text = \markup { "3" }   % text above the bracket
\once \override Frame.repeat-barlines = ##t            % repeat barlines instead of a box
\override FrameBracket.no-bracket = ##t                % box + line, no bracket/text at all
                                                         % (this project's house-style default)
```

Frames work fine wrapping contact-articulated `StringStaff` notes too —
that's their most common real use in this project's cue files.

---

## 8. Putting it together

A realistic multi-instrument passage, combining several features at
once (this is `test-suite.ly` score 11, simplified):

```lilypond
\new StaffGroup <<
  \new StringStaff \with { instrumentName = "Vn" } \relative c' {
    \clef treble
    a1~\daln^\arrowSpan #"(tasto)" #"(ord.)" | a1\halfHarmonic\stopTextSpan\! |
    \frameStart b4 c d \frameEnd e | f4 g \frameExtenderEnd a b |
    c1\squareHead\aln\f\downbow | d1\!\downbow |
  }
  \new StringStaff \with { instrumentName = "Vc" } {
    \clef bass
    \set Staff.scordaturaMode  = #'sounding
    \set Staff.stringColorList = #strings-highlight-4
    \withScordatura #'cello { a d g, des, } {
      \withStringColors {
        c,1\4\squareHead~\p |
        c,1\4\squareHead |
      }
    }
    \set Staff.scordaturaMode = #'fingered
  }
  \new Staff \with { instrumentName = "Cb" } {
    \clef bass
    \staffRepeat { g,1\pp } |
  }
>>
```

Everything here stacks cleanly: scordatura + string colors + contact
articulations on the same note, frames around contact-articulated notes,
ties and slurs across scordatura-transposed notes, technique text
alongside hairpins and spanners.

---

## 9. Troubleshooting / FAQ

**"My `\sp`/`\ord`/`\st` isn't showing up, no error either."**
You need a direction indicator: `c4^\sp`, not `c4\sp`. See section 3.

**"My contact articulations aren't doing anything."**
Are you inside a `StringStaff`? These only activate there, on purpose —
a plain `Staff` ignores them (they don't error, they just do nothing, so
this is easy to miss).

**"Two simultaneous contact-articulated notes in different voices show
the same shape, and they shouldn't."**
Use `\new StringVoice` for each voice instead of `\new Voice` — see the
multi-voice caveat in section 4.

**"Scordatura doesn't seem to be transposing anything."**
Check `Staff.scordaturaMode` — the default is `#'fingered`, which
deliberately shows the *written* pitch with no transposition (that's
what a performer reading scordatura notation wants). Switch to
`#'sounding` if you want to see the transposed pitch.

**"I set an explicit `\N` string number and it didn't change anything."**
Explicit string numbers only affect scordatura transposition and string
coloring — they don't do anything by themselves outside those systems.

**"Frame notation gives 'No grob definition found for `Frame`'."**
You (or something you're including) needs `\consists \frameEngraver` on
a `Voice` context — see section 7. This project's `project/style.ily`
already does this everywhere; if you're using `core/` on its own,
without `project/`, you need to add it yourself.

**"An unknown scordatura instrument or an unreachable pitch — is that a
crash?"**
No — check the compile log for a warning; the note itself renders at its
plain written pitch either way.

---

## 10. Quick reference

| Command | File | What it does |
|---|---|---|
| `\sp` `\ord` `\st` (needs `^`/`_`) | notation | bow-position technique text |
| `\sim` | notation | "sim." dynamic-style mark |
| `\daln` / `\aln` | notation | circled-tip dal/al niente hairpins |
| `\arrowSpan #"a" #"b"` ... `\stopTextSpan` | notation | two-sided labelled arrow spanner |
| `\ss { music }` | notation | hide staff/ledger lines for `music` |
| `\staffRepeat { music }` | notation | repeat barlines around `music` |
| `\scord "ADGD"` | notation | text-only scordatura label |
| `\cueLabel "1M1"` | notation | boxed rehearsal-style mark |
| `\squareHead` / `\halfHarmonic` / `\air` | strings | suffix contact articulations, `StringStaff`-only, chord-independent |
| `\square` / `\half-harmonic` | strings | legacy prefix forms, any `Staff`, NOT chord-independent |
| `\withScordatura #'inst { tuning } { music }` | strings | transposing scordatura |
| `Staff.scordaturaMode = #'fingered` / `#'sounding` | strings | which pitch to display |
| `\unscordatura` | strings | clear scordatura mid-block |
| `\withStringColors { music }` | strings | color by explicit `\N` |
| `\withStringColorsInferred { music }` | strings | color by explicit `\N`, or guessed if absent |
| `Staff.stringColorList = #scheme` | strings | which color scheme to use |
| `\frameStart ... \frameEnd ... \frameExtenderEnd` | frame-engraver | box/repeat-barlines + extender line |
| `FrameBracket.text` / `.no-bracket`, `Frame.repeat-barlines` | frame-engraver | frame display options |

See also `lib/project/TIMING-MANUAL.md` for the film-cue timing system
(`\cueTime`, `\cueStartTime`, `\cueGapTo`, ...), which is project-specific
rather than part of `core/`.
