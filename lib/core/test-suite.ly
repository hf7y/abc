%%% lib/core/test-suite.ly
%%% Visual smoke test for lib/core/. Compiles standalone — no
%%% dependency on lib/project/. Run after changing anything in core/:
%%%
%%%   lilypond lib/core/test-suite.ly
%%%
%%% Each \score is preceded by a wrapped \markup naming what to look
%%% for -- deliberately short so it never runs off the page edge.
%%% Deeper rationale (why a check exists, what bug it caught) lives in
%%% strings.ily's comments and TODO.md, not here.

\version "2.24.0"
\include "includes.ily"

\header {
  title = "core/ test suite"
}

%%% \wordwrap-lines only wraps BETWEEN markup-list items, not within one --
%%% a single quoted string is one atomic item. This splits a plain Scheme
%%% string into one-word markups so it actually reflows to the page width.
%%% Also: \wordwrap-lines is a markup-LIST command, so it needs the
%%% \markuplist entry point (not \markup) and \override-lines (not
%%% \override) if you ever need to change its line-width -- confirmed by
%%% testing directly, both of those wrong-but-plausible-looking guesses
%%% silently produced unwrapped, page-clipped text with no error at all.
#(define (wordwrap-text str)
   (map (lambda (w) (markup #:normal-text w)) (string-split str #\space)))

%%% Frame engraver needs \consists \frameEngraver in a Voice context to
%%% activate (project/style.ily does this for the real score; the test
%%% suite has no project/ dependency, so score 10 activates it locally).

\book {

  \markuplist \wordwrap-lines #(wordwrap-text "1. Notation vocabulary. Expect: pont./ord./tasto/sim. markups; circled-tip hairpins; arrow-span text spanner with arrow; \\ss removes staff+ledger lines for 4 notes; repeat barlines .|: :|.; 'scord.' text label 'ADGD'.")
  \score {
    \header { piece = "1" }
    \new Staff \relative c' {
      \cueLabel "T1"
      c4^\sp d^\ord e^\st f^\sim |
      g1~\daln | g1~\aln g1\! |
      a1^\arrowSpan #"(tasto)" #"(ord.)" b1\stopTextSpan |
      \ss { c4 d e f } |
      \staffRepeat { g1 } |
      a1\scord "ADGD" |
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "2. Legacy \\square / \\half-harmonic (prefix). Expect: diamond, square, square (inside \\ss, no staff lines), then a chord where BOTH notes go square -- no per-note independence, that's the known limitation of the legacy prefix form (see score 2b for the fix).")
  \score {
    \header { piece = "2" }
    \new Staff {
      \clef bass
      \half-harmonic c,1 | \square d,1 |
      \ss \square e,1 |
      \square <g, c>1 |
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "2b. New suffix \\squareHead / \\halfHarmonic / \\air. Expect: square, diamond, square, then dot/accent/downbow/f render normally alongside, then a chord = oval + diamond + square all independent.")
  \score {
    \header { piece = "2b" }
    \new StringStaff {
      \clef bass
      c,1\squareHead | d,1\halfHarmonic | e,1\air |
      f,4-.\p g,4-> a,4\downbow b,4\f |
      <g,\squareHead c\halfHarmonic e>1 |
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "2c. Duration matrix (quarter/half/whole). Expect: quarter = filled square vs. filled oval -- compare SHARP CORNERS to a ROUND curve, ink alone looks similar. Half/whole = open square vs. open oval. Diamonds stay filled at every duration (harmonic convention).")
  \score {
    \header { piece = "2c" }
    \new StringStaff {
      \clef bass
      c,4\squareHead d,4 e,4\air f,4 |
      c,2\squareHead d,2 |
      e,1\squareHead |
      c,4\halfHarmonic d,4\halfHarmonic e,4 f,4 |
      c,2\halfHarmonic d,2 |
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "2d. \\ss and ties/slurs across contact articulations. Expect: tiny square with NO staff/ledger lines around it; two squares joined by a TIE curve; two diamonds joined by a SLUR curve.")
  \score {
    \header { piece = "2d" }
    \new StringStaff {
      \clef bass
      \ss { c,1\squareHead } |
      c,1~\squareHead c,1\squareHead |
      d,1(\halfHarmonic e,1)\halfHarmonic |
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "2e. Two StringVoices, different articulations, same instant. Expect: TOP = square, BOTTOM = diamond -- two DIFFERENT shapes. If both notes show the same shape, the per-Voice fix has regressed (see strings.ily).")
  \score {
    \header { piece = "2e" }
    \new StringStaff <<
      \new StringVoice { \voiceOne \clef bass a1\squareHead }
      \new StringVoice { \voiceTwo \clef bass e,1\halfHarmonic }
    >>
  }

  \markuplist \wordwrap-lines #(wordwrap-text "3. Scordatura, fingered mode (default). Expect: plain notes, NO accidental, string numbers 4/3 shown above.")
  \score {
    \header { piece = "3" }
    \new StringStaff {
      \clef bass
      \withScordatura #'cello { a d g, des, } {
        c,1\4 g,1\3
      }
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "4. Scordatura, sounding mode. Expect, left to right: FLAT; FLAT then NO accidental (same-measure repeat suppressed); NO accidental (written sharp cancelled to natural by the retuning); plain (string 3 untouched).")
  \score {
    \header { piece = "4" }
    \new StringStaff {
      \clef bass
      \set Staff.scordaturaMode = #'sounding
      \withScordatura #'cello { a d g, des, } {
        c,1\4
        c,2\4 c,2\4
        cis,1\4
        g,1\3
      }
      \set Staff.scordaturaMode = #'fingered
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "5. Viola, alto clef, plain scale. Baseline for score 6 -- no scordatura involved.")
  \score {
    \header { piece = "5" }
    \new StringStaff \relative c' {
      \clef alto
      c d e f g a b c'
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "6. Same scale, identity-tuning scordatura. Expect: positions IDENTICAL to score 5, note for note.")
  \score {
    \header { piece = "6" }
    \new StringStaff \relative c' {
      \clef alto
      \withScordatura #'viola { a' d' g c } {
        c d e f g a b c'
      }
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "6b. Violin scordatura, string 4 G->F# (treble clef). Expect: bar 1 (fingered) plain G. Bar 2 (sounding) SHIFTS DOWN one staff step AND shows a SHARP -- notename changes, not just the accidental.")
  \score {
    \header { piece = "6b" }
    \new StringStaff {
      \clef treble
      \withScordatura #'violin { e'' a' d' fis } {
        g1
      }
      \set Staff.scordaturaMode = #'sounding
      \withScordatura #'violin { e'' a' d' fis } {
        g1
      }
      \set Staff.scordaturaMode = #'fingered
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "6c. Bass scordatura, string 4 E->Eb (bass clef). Expect: bar 1 (fingered) plain E. Bar 2 (sounding) SAME staff position, only a FLAT appears -- same notename, unlike 6b.")
  \score {
    \header { piece = "6c" }
    \new StringStaff {
      \clef bass
      \withScordatura #'bass { g, d, a,, ees,, } {
        e,,1\4
      }
      \set Staff.scordaturaMode = #'sounding
      \withScordatura #'bass { g, d, a,, ees,, } {
        e,,1\4
      }
      \set Staff.scordaturaMode = #'fingered
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "6d. Cello, tenor clef, plain scale. Baseline for score 6e -- tenor clef was untested before this session.")
  \score {
    \header { piece = "6d" }
    \new StringStaff \relative c' {
      \clef tenor
      c d e f g a b c'
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "6e. Same scale, tenor clef, identity-tuning scordatura. Expect: positions IDENTICAL to score 6d, note for note.")
  \score {
    \header { piece = "6e" }
    \new StringStaff \relative c' {
      \clef tenor
      \withScordatura #'cello { a d g, c, } {
        c d e f g a b c'
      }
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "6f. Explicit \\N must override the heuristic, not just decorate it. Cello, string 2 retuned D->Db, string 1 untouched. Both notes are the SAME written pitch (a). Expect: bar 1 (no string#, heuristic picks string 1) plain A. Bar 2 (explicit \\2, forces the retuned string) a FLAT -- a DIFFERENT result, proving the override changes the actual transposition.")
  \score {
    \header { piece = "6f" }
    \new StringStaff {
      \clef bass
      \set Staff.scordaturaMode = #'sounding
      \withScordatura #'cello { a des g, c, } {
        a1 |
        a1\2 |
      }
      \set Staff.scordaturaMode = #'fingered
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "6g. Error paths: unknown instrument, unreachable pitch. Expect: two plain notes, NO crash. Check the COMPILE LOG (not this page) for two warnings -- unknown instrument, unreachable pitch -- since both error paths correctly leave the note looking like a normal one.")
  \score {
    \header { piece = "6g" }
    \new StringStaff {
      \clef bass
      \withScordatura #'guitar { a, d, g, c, } {
        c,1
      }
      \set Staff.scordaturaMode = #'sounding
      \withScordatura #'cello { a d g, c, } {
        b,,1
      }
      \set Staff.scordaturaMode = #'fingered
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "6h. Two instruments, two Staves, simultaneously. Different scordatura on violin (top) and cello (bottom), both sounding mode at once. Expect: TOP a SHARP, BOTTOM a FLAT -- independent, no leakage between Staves.")
  \score {
    \header { piece = "6h" }
    \new StaffGroup <<
      \new StringStaff {
        \clef treble
        \set Staff.scordaturaMode = #'sounding
        \withScordatura #'violin { e'' a' d' fis } {
          g1
        }
      }
      \new StringStaff {
        \clef bass
        \set Staff.scordaturaMode = #'sounding
        \withScordatura #'cello { a d g, des, } {
          c,1
        }
      }
    >>
  }

  \markuplist \wordwrap-lines #(wordwrap-text "6i. Explicit \\unscordatura clears the effect mid-block. Expect: bar 1 a FLAT. Bar 2 (right after \\unscordatura, still inside \\withScordatura) PLAIN -- no flat -- even though the string-4 circle keeps showing (that's just the \\N glyph, independent of scordatura state).")
  \score {
    \header { piece = "6i" }
    \new StringStaff {
      \clef bass
      \set Staff.scordaturaMode = #'sounding
      \withScordatura #'cello { a d g, des, } {
        c,1\4
        \unscordatura
        c,1\4
      }
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "6j. Tie across two scordatura-transposed notes. Expect: a visible TIE CURVE connecting the two flat notes. (Previously rendered with no curve at all -- see strings.ily/TODO.md.)")
  \score {
    \header { piece = "6j" }
    \new StringStaff {
      \clef bass
      \set Staff.scordaturaMode = #'sounding
      \withScordatura #'cello { a d g, des, } {
        c,1\4~
        c,1\4
      }
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "7. String colors, explicit numbers only. Expect: RED, black, black -- the third note has no string number (inference is off by default), so it stays the default color even though it's the same pitch class pattern as the others.")
  \score {
    \header { piece = "7" }
    \new StringStaff {
      \clef bass
      \set Staff.stringColorList = #strings-highlight-4
      \withStringColors {
        c,1\4 g,1\3
        d,1
      }
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "7b. Every built-in color scheme, plus one custom list. One row each, string 4/3/2/1 left to right: all-black, highlight-1, -2, -3, -4, highlight-1-4, highlight-all, rainbow, then a custom DeepPink/Gold/black/Cyan4 list. Expect each row's colors to match strings.ily's scheme definitions -- confirmed earlier via exact pixel RGB sampling, not just eyeballing.")
  \score {
    \header { piece = "7b (all-black)" }
    \new StringStaff {
      \clef bass
      \set Staff.stringColorList = #strings-all-black
      \withStringColors { c,1\4 d,1\3 e,1\2 f,1\1 }
    }
  }
  \score {
    \header { piece = "7b (highlight-1)" }
    \new StringStaff {
      \clef bass
      \set Staff.stringColorList = #strings-highlight-1
      \withStringColors { c,1\4 d,1\3 e,1\2 f,1\1 }
    }
  }
  \score {
    \header { piece = "7b (highlight-2)" }
    \new StringStaff {
      \clef bass
      \set Staff.stringColorList = #strings-highlight-2
      \withStringColors { c,1\4 d,1\3 e,1\2 f,1\1 }
    }
  }
  \score {
    \header { piece = "7b (highlight-3)" }
    \new StringStaff {
      \clef bass
      \set Staff.stringColorList = #strings-highlight-3
      \withStringColors { c,1\4 d,1\3 e,1\2 f,1\1 }
    }
  }
  \score {
    \header { piece = "7b (highlight-4)" }
    \new StringStaff {
      \clef bass
      \set Staff.stringColorList = #strings-highlight-4
      \withStringColors { c,1\4 d,1\3 e,1\2 f,1\1 }
    }
  }
  \score {
    \header { piece = "7b (highlight-1-4)" }
    \new StringStaff {
      \clef bass
      \set Staff.stringColorList = #strings-highlight-1-4
      \withStringColors { c,1\4 d,1\3 e,1\2 f,1\1 }
    }
  }
  \score {
    \header { piece = "7b (highlight-all)" }
    \new StringStaff {
      \clef bass
      \set Staff.stringColorList = #strings-highlight-all
      \withStringColors { c,1\4 d,1\3 e,1\2 f,1\1 }
    }
  }
  \score {
    \header { piece = "7b (rainbow)" }
    \new StringStaff {
      \clef bass
      \set Staff.stringColorList = #strings-rainbow
      \withStringColors { c,1\4 d,1\3 e,1\2 f,1\1 }
    }
  }
  \score {
    \header { piece = "7b (custom: DeepPink/Gold/black/Cyan4)" }
    \new StringStaff {
      \clef bass
      \set Staff.stringColorList = #(list (cons 1 (x11-color 'DeepPink))
                                           (cons 2 (x11-color 'Gold))
                                           (cons 3 black)
                                           (cons 4 (x11-color 'Cyan4)))
      \withStringColors { c,1\4 d,1\3 e,1\2 f,1\1 }
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "8. String colors with inference, all 4 strings. Expect: RED, RED (both only reachable on string 4), black, black (both only reachable on string 3) -- confirmed by hand fret arithmetic, not just eyeballing.")
  \score {
    \header { piece = "8" }
    \new StringStaff {
      \clef bass
      \set Staff.stringColorList = #strings-highlight-4
      \withScordatura #'cello { a d g, c, } {
        \withStringColorsInferred {
          c,1 d,1 g,1 a,1
        }
      }
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "9. Scordatura + string colors + contact articulations together. Expect: a RED square (transposed AND colored AND squareHead, all on one note), then a black diamond (unchanged, colored, halfHarmonic).")
  \score {
    \header { piece = "9" }
    \new StringStaff {
      \clef bass
      \set Staff.scordaturaMode  = #'sounding
      \set Staff.stringColorList = #strings-highlight-4
      \withScordatura #'cello { a d g, des, } {
        \withStringColors {
          \square c,1\4
          \half-harmonic g,1\3
        }
      }
      \set Staff.scordaturaMode = #'fingered
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "10. Frame engraver: box + extender line. Expect: a box around the first group of notes, then an arrow-tipped extender line continuing to the right.")
  \score {
    \header { piece = "10" }
    \new Staff \relative c' {
      \frameStart c4 d e \frameEnd f |
      g4 a \frameExtenderEnd b c |
    }
    \layout {
      \context {
        \Voice
        \consists \frameEngraver
      }
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "10b. Frame with a text label. Expect: the same box, with '3' printed above the bracket.")
  \score {
    \header { piece = "10b" }
    \new Staff \relative c' {
      \once \override FrameBracket.text = \markup { "3" }
      \frameStart c4 d e \frameEnd f | g4 a b \frameExtenderEnd c |
    }
    \layout {
      \context {
        \Voice
        \consists \frameEngraver
      }
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "10c. Frame in repeat-barlines mode. Expect: repeat barlines ( .|: :|. ) around the group instead of a box.")
  \score {
    \header { piece = "10c" }
    \new Staff \relative c' {
      \once \override Frame.repeat-barlines = ##t
      \frameStart c4 d e \frameEnd f | g4 a b \frameExtenderEnd c |
    }
    \layout {
      \context {
        \Voice
        \consists \frameEngraver
      }
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "10d. Frame with no-bracket (this project's house-style default). Expect: box + extender line, but NO bracket line and NO text above it.")
  \score {
    \header { piece = "10d" }
    \new Staff \relative c' {
      \override FrameBracket.no-bracket = ##t
      \frameStart c4 d e \frameEnd f | g4 a b \frameExtenderEnd c |
    }
    \layout {
      \context {
        \Voice
        \consists \frameEngraver
      }
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "10e. Frame wrapping StringStaff contact-articulated notes. Matches the actual pattern used in 1m2.ily (\\frameStart ... \\square ... \\frameEnd). Expect: a box around a square + diamond notehead, extender line continuing after.")
  \score {
    \header { piece = "10e" }
    \new StringStaff {
      \clef bass
      \override FrameBracket.no-bracket = ##t
      \frameStart c,2\squareHead d,2\halfHarmonic \frameEnd e,2 f,2 |
      g,2 a,2 \frameExtenderEnd b,2 c,2 |
    }
    \layout {
      \context {
        \Voice
        \consists \frameEngraver
      }
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "11. Integration: realistic multi-instrument passage. StaffGroup Vn/Vc (StringStaves) + Cb (plain Staff), standalone from project/. Expect, Vn: tie+arrow-span, then a diamond, then a frame box, then a square with accent/downbow/f. Expect, Vc: a RED square (color + squareHead together) tied across the barline, then a black diamond, then a note with \\ss. Expect, Cb: repeat barlines, a suppressed rest, then two dynamics.")
  \score {
    \header { piece = "11" }
    \new StaffGroup <<
      \new StringStaff \with { instrumentName = "Vn" } \relative c' {
        \clef treble
        \override FrameBracket.no-bracket = ##t
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
            g,1\3\halfHarmonic\aln |
            \ss d,1\3\! |
          }
        }
        \set Staff.scordaturaMode = #'fingered
      }
      \new Staff \with { instrumentName = "Cb" } {
        \clef bass
        \staffRepeat { g,1\pp } |
        \ss { R1 } |
        c,1\sim |
        d,1\f |
      }
    >>
  }

}
