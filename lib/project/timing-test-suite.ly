%%% lib/project/timing-test-suite.ly
%%% Visual smoke test / feature showcase for lib/project/timing.ily.
%%% Compiles standalone (includes the full public library, since
%%% timing.ily is project-scoped and this exercises it the way a real
%%% cue file would). Run after changing anything in timing.ily:
%%%
%%%   lilypond lib/project/timing-test-suite.ly
%%%
%%% Each \score is preceded by a wrapped \markup naming the exact
%%% timecodes to expect, so the PDF is self-verifiable at a glance --
%%% same convention as lib/core/test-suite.ly (see that file's comment
%%% for why \wordwrap-lines needs the wordwrap-text helper below).

\version "2.24.0"
\include "../includes.ily"

\header {
  title = "timing.ily test suite"
}

#(define (wordwrap-text str)
   (map (lambda (w) (markup #:normal-text w)) (string-split str #\space)))

%%% Used by scores 9 and 10, simulating a reel's cue concatenation.
cueOneDemo = { c4 d e f | g4 a b c' | }
cueTwoDemo = { \tempo 4 = 120 d4 e f g | }

\book {

  \markuplist \wordwrap-lines #(wordwrap-text "1. Basic elapsed time, steady tempo 60. Expect: 0:00.000, 0:01.000, 0:02.000, 0:03.000 -- one second per quarter note.")
  \score {
    \header { piece = "1" }
    \new Staff \relative c' {
      \tempo 4 = 60
      c4\cueTime d4\cueTime e4\cueTime f4\cueTime |
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "2. Tempo change mid-cue, 60 then 120. Expect: 0:03.000 on the last note of measure 1 (3 quarters @ 60bpm); 0:05.500 on the last note of measure 2 (+1s @ 60bpm to the barline, then 3 quarters @ 120bpm).")
  \score {
    \header { piece = "2" }
    \new Staff \relative c' {
      \tempo 4 = 60
      c4 d e f\cueTime |
      \tempo 4 = 120
      g4 a b c'\cueTime |
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "3. Metronome range 60-72 (averages to 66). Expect: 0:00.000, then 0:00.909 -- one quarter note at 66bpm is 60/66 = 0.909s.")
  \score {
    \header { piece = "3" }
    \new Staff \relative c' {
      \tempo 4 = 60-72
      c4\cueTime d4\cueTime r4 r4 |
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "4. Text-only tempo mark. Expect: 0:00.000, then 0:02.000, 0:03.000 -- 'Andante' has no metronome count, so the numeric tempo (60) established earlier keeps being used across it, not a crash and not a silent reset to a default.")
  \score {
    \header { piece = "4" }
    \new Staff \relative c' {
      \tempo 4 = 60
      c4\cueTime d4
      \tempo "Andante"
      e4\cueTime f4\cueTime |
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "5. Rests and chords. Expect: 0:00.000 on the whole-note rest itself (not after it); 0:04.000 on the chord -- ONE label for the whole chord, not one per note.")
  \score {
    \header { piece = "5" }
    \new Staff \relative c' {
      \tempo 4 = 60
      r1\cueTime |
      <c e g>1\cueTime |
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "6. Multi-staff sharing. Tempo is marked only in the top staff; \\cueTime is used only in the bottom staff. Expect the bottom staff's timecodes to match score 2 exactly: 0:03.000, then 0:05.500 -- one shared clock for the whole StaffGroup, not a per-staff clock.")
  \score {
    \header { piece = "6" }
    \new StaffGroup <<
      \new Staff \relative c' {
        \tempo 4 = 60
        c4 d e f |
        \tempo 4 = 120
        g4 a b c' |
      }
      \new Staff \relative c {
        c4 d e f\cueTime |
        g4 a b c'\cueTime |
      }
    >>
  }

  \markuplist \wordwrap-lines #(wordwrap-text "7. \\cueStartTime -- absolute movie timecode. This cue starts at 3:12.5 into the film. Expect: 3:12.500 on the first note, 3:13.500 on the second (+1s @ 60bpm).")
  \score {
    \header { piece = "7" }
    \new Staff \relative c' {
      \cueStartTime "3:12.5"
      \tempo 4 = 60
      c4\cueTime d4\cueTime r4 r4 |
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "8. Hour rollover. This cue starts at 59:58 into the film. Expect: 59:58.000, 59:59.000, then 1:00:00.000 -- the display format switches from M:SS to H:MM:SS exactly at the one-hour mark, mid-cue.")
  \score {
    \header { piece = "8" }
    \new Staff \relative c' {
      \cueStartTime "59:58"
      \tempo 4 = 60
      c4\cueTime d4\cueTime e4\cueTime r4 |
    }
  }

  \pageBreak
  \markuplist \wordwrap-lines #(wordwrap-text "9. \\cueTotalTime -- reel total, simulating two concatenated cues (cueOneDemo then cueTwoDemo, the way a real reel concatenates 1M1 then 1M2). Expect: a boxed, bold 'Total: 0:12.000' after the last real note -- 8 quarters @ 60bpm (cueOneDemo) + 4 quarters @ 120bpm (cueTwoDemo) = 8 + 2 = 10s, plus this reel's own 0:02 offset. Attached to a trailing spacer, not the last note itself -- see the design note in timing.ily for why.")
  \score {
    \header { piece = "9" }
    \new Staff \relative c' {
      \cueStartTime "0:02"
      \tempo 4 = 60
      \cueOneDemo
      \cueTwoDemo
      s4\cueTotalTime
    }
  }

  \markuplist \wordwrap-lines #(wordwrap-text "10. \\cueTocEntry / \\cueTimeline -- chronological cue timeline bridging LilyPond's own toc-init.ly machinery (add-toc-item!/toc-items, the same functions \\tocItem uses) to live computed timecodes instead of page numbers. Simulates a two-cue reel again, tagged with \\cueTocEntry on each cue's first note. The timeline listing appears right below this text -- expect two lines: '1M1 -- Coin -- 0:00.000' and '1M2 -- Water -- 0:08.000' (cue 1M1 is 8 quarters @ 60bpm). Nothing prints in the music itself -- \\cueTocEntry is invisible by design (see timing.ily); pair it with \\cueLabel if you also want a boxed mark in the score too.")
  \score {
    \header { piece = "10" }
    \new Staff \relative c' {
      \tempo 4 = 60
      c4\cueTocEntry "1M1" "Coin" d e f |
      g4 a b c' |
      \tempo 4 = 120
      d4\cueTocEntry "1M2" "Water" e f g |
    }
  }

  \markuplist \cueTimeline

  \pageBreak
  \markuplist \wordwrap-lines #(wordwrap-text "11. \\cueGapTo -- delayed cue start with computed silence, for a movie gap where no music plays (e.g. a dialogue scene). partA is 8 quarters @ 60bpm (8s); target is 0:30, so the gap must be exactly 22s = 5.5 whole notes @ 60bpm. Expect a compressed multi-measure rest showing '5', then the next note landing at exactly 0:30.000 -- the leftover half-measure is an exact but invisible \\skip, not rounded away. See the design note and the real LilyPond bug report in timing.ily.")
  \score {
    \header { piece = "11" }
    \new Staff \relative c' {
      \cueStartTime "0:00"
      \cueOneDemo
      \cueGapTo "0:00" "0:30" \cueOneDemo
      d4\cueTime e f g
      % no trailing "|" bar check here -- the gap deliberately lands
      % mid-measure (5.5 measures of rest, not a whole number), so this
      % point is not a barline and a bar check would false-positive
    }
  }

  \pageBreak
  \markuplist \wordwrap-lines #(wordwrap-text "12. \\cueUseSmpteFps -- SMPTE HH:MM:SS:FF display. Expect: 00:00:00:00, 00:00:01:00, 00:00:02:00, 00:00:03:00 at 24fps (one second per quarter note = exactly 24 frames, 0 remainder each time), then a switch back to decimal (##f) showing 0:04.000 on the fifth note.")
  \score {
    \header { piece = "12" }
    \new Staff \relative c' {
      \cueUseSmpteFps 24
      \tempo 4 = 60
      c4\cueTime d4\cueTime e4\cueTime f4\cueTime |
      \cueUseSmpteFps ##f
      g4\cueTime
    }
  }

  \pageBreak
  \markuplist \wordwrap-lines #(wordwrap-text "13. \\cueTempoTo -- computed tempo, the inverse of \\cueGapTo: cueOneDemo is 8 quarter notes with no \\tempo of its own, and must fit exactly 10 seconds. Expect a printed '\\tempo 4 = 48' before the notes (8 quarters / 10s = 48bpm, an exact fit -- no rounding-drift message in the log for this one), then \\cueTime confirming the last note lands at 0:10.000 (well, the START of the 8th note -- see \\cueTime's own always-report-the-onset behavior above).")
  \score {
    \header { piece = "13" }
    \new Staff \relative c' {
      \cueTempoTo 4 "0:00" "0:10" \cueOneDemo
      s4\cueTime
    }
  }

}
