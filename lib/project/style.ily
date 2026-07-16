%%% lib/project/style.ily
%%% Project-specific house style for abc: layout contexts, spacing,
%%% paper, page headers. Implementation detail. Do not include
%%% directly; use lib/includes.ily.
%%%
%%% A top-level \layout block here applies automatically to every \score.
%%% A top-level \paper block merges with any \paper block in the reel.


%%% ── LAYOUT ──────────────────────────────────────────────────────────
%%% Overrides here apply to all scores in all reels.
%%% Reel-level layout exceptions go in that reel's own file (e.g. 1m.ly --
%%% see lib/README.md's "Reel & cue conventions" section) inside a local
%%% \layout block nested in its \score.

\layout {
  indent       = 0.5\in
  short-indent = 0.25\in

  \context {
    \Global
    \grobdescriptions #all-grob-descriptions
  }

  \context {
    \Score

    %%% Proportional notation — strong global choice: horizontal spacing
    %%% is proportional to real duration (a 1/8 note's worth of space is
    %%% the unit) rather than the default spacing-by-notated-shape. No
    %%% rationale for THIS choice specifically is recorded elsewhere in
    %%% this repo -- if the reasoning behind it ever surfaces (worth
    %%% capturing if so), it belongs here.
    %%% If a reel needs non-proportional, override in that reel's own
    %%% \score (see lib/README.md's "Reel & cue conventions"):
    %%%   \score { \layout { \context { \Score
    %%%     proportionalNotationDuration = ##f } } }
    proportionalNotationDuration = #(ly:make-moment 1/8)

    %%% House barline style: every ordinary barline is replaced by "'",
    %%% LilyPond's short-tick-above-the-staff bar glyph, instead of a
    %%% full-height line -- confirmed empirically (compiling with/without
    %%% this and comparing) that measureBarType alone, inherited down
    %%% into every Staff, is what produces this; nothing needs removing
    %%% for it to take effect. An earlier `\remove Bar_engraver` line
    %%% lived here too, but it was dead code: Bar_engraver lives on the
    %%% Staff context by default, not Score, so removing it from \Score
    %%% here never actually touched anything (LilyPond's own \remove
    %%% silently no-ops on an engraver that isn't present, with no
    %%% warning) -- confirmed by compiling with that line present, absent,
    %%% and with it moved to \Staff (which DOES suppress barlines
    %%% entirely, a visibly different and not what this project wants).
    measureBarType = "'"

    %%% Bar numbers pushed above staff
    \override BarNumber.extra-offset = #'(0 . 3)

    %%% Hairpins run through barlines
    \override Hairpin.to-barline = ##f

    %%% Padding for dynamics and text above/below staff
    \override DynamicLineSpanner.staff-padding = #4
    \override TextSpanner.staff-padding         = #3
    \override TextScript.staff-padding          = #3

    %%% No whiteout on text (prevents masking of staff lines)
    \override TextScript.whiteout  = ##f
    \override TextSpanner.whiteout = ##f

    %%% TextScript vertical centering on its anchor side -- offsets the
    %%% script by half its own Y-extent so it centers on whichever side
    %%% (up/down) it's aligned to, rather than hanging from the edge.
    %%% Guards against a real, confirmed case: a TextScript with a truly
    %%% empty stencil (e.g. ^\markup{""}, or the placeholder-then-
    %%% transparent trick project/timing.ily's \cueTocEntry uses) has a
    %%% degenerate (+inf.0 . -inf.0) Y-extent, not (0 . 0) -- a bare
    %%% (pair? ext) check doesn't catch that, and averaging +inf.0 with
    %%% -inf.0 produces +nan.0, which LilyPond reports as "programming
    %%% error: Improbable offset for stencil: -nan staff space" and
    %%% papers over by zeroing the offset. The finite? checks below make
    %%% that same zero-offset outcome the deliberate, silent result
    %%% instead of a caught internal error.
    \override TextScript.Y-offset = #(lambda (grob)
      (let* ((edge (ly:side-position-interface::y-aligned-side grob))
             (ext  (ly:grob-property grob 'Y-extent))
             (mid  (if (and (pair? ext) (finite? (car ext)) (finite? (cdr ext)))
                       (/ (+ (car ext) (cdr ext)) 2)
                       0)))
        (- edge mid)))

    %%% Glissando style — arrowed line
    \override Glissando.bound-details.right.arrow = ##t
    \override Glissando.arrow-length  = #0.8
    \override Glissando.arrow-width   = #0.5
    \override Glissando.style         = #'line
    \override Glissando.thickness     = #1.5

    %%% FrameBracket — suppress bracket display (core/frame-engraver.ily)
    \override FrameBracket.no-bracket = ##t
  }

  \context {
    \StaffGroup
    \override VerticalAxisGroup.staff-staff-spacing =
      #'((basic-distance   . 10)
         (minimum-distance . 10)
         (padding          . 4)
         (stretchability   . 12))
  }

  \context {
    \Voice
    %%% Roman string numbers (I II III IV) instead of arabic -- a
    %%% built-in LilyPond command, not project code.
    \romanStringNumbers
    %%% Frame engraver active in every Voice context by default, so any
    %%% cue can use \frameStart/\frameEnd/\frameExtenderEnd
    %%% (core/frame-engraver.ily) without remembering to \consists it
    %%% locally -- house-style-wide opt-OUT rather than per-use opt-in.
    %%% See core/MANUAL.md section 7 for the full frame-notation
    %%% vocabulary this activates.
    \consists \frameEngraver
  }
}


%%% ── PAPER ───────────────────────────────────────────────────────────
%%% Top-level \paper merges with any \paper in a reel's own file.
%%% Reel-specific overrides (e.g. different margins) go there instead.

\paper {
  #(set-paper-size "letter")

  %%% System spacing
  system-system-spacing  = #'((basic-distance . 20) (padding . 4))
  markup-system-spacing  = #'((basic-distance . 8)  (padding . 2))

  %%% Page headers -- the instrument name would fill in from a
  %%% \header { instrument = "..." } set inside a per-instrument \score
  %%% (LilyPond's own part-extraction convention). Currently unused/inert:
  %%% no reel in this project sets that field, since every real reel so
  %%% far is one combined conductor-score \score (see reel-template.ly),
  %%% not one \score per extracted part -- this is here ready for if/when
  %%% that changes, not a sign anything's broken now.
  %%% page numbers are automatic
  oddHeaderMarkup = \markup \column {
    \fill-line {
      ""
      \unless \on-first-page-of-part \fromproperty #'header:instrument
      \if \should-print-page-number \fromproperty #'page:page-number-string
    }
    \vspace #2
  }

  %%% evenHeaderMarkup must be defined explicitly once oddHeaderMarkup is set
  evenHeaderMarkup = \markup \column {
    \fill-line {
      \if \should-print-page-number \fromproperty #'page:page-number-string
      \unless \on-first-page-of-part \fromproperty #'header:instrument
      ""
    }
    \vspace #2
  }
}
