%%% orch-style.ily
%%% Shared house-style: engravers, overrides, markups, music functions,
%%% layout, and paper settings common to all pieces.

\include "frame-engraver.ly"
\include "square.ily"
\include "half-harmonic.ily"

global = {
  \override Hairpin.to-barline = ##f
  \override FrameBracket.no-bracket = ##t
  \override DynamicLineSpanner.staff-padding = #4
  \override TextSpanner.staff-padding = #3
  \override TextScript.staff-padding = #3
  \override TextScript.whiteout = ##f
  \override TextSpanner.whiteout = ##f
  \override TextScript.Y-offset = #(lambda (grob)
    (let* ((edge (ly:side-position-interface::y-aligned-side grob))
           (ext (ly:grob-property grob 'Y-extent))
           (mid (if (pair? ext) (/ (+ (car ext) (cdr ext)) 2) 0)))
      (- edge mid)))

  \override Glissando.bound-details.right.arrow = ##t
  \override Glissando.arrow-length = #0.8
  \override Glissando.arrow-width = #0.5
  \override Glissando.style = #'line
  \override Glissando.thickness = #1.5

  \romanStringNumbers
}

%% Common text markups
sp  = \markup \small \italic "pont."
ord = \markup \small \italic "ord."
st  = \markup \small \italic "tasto"

sim = #(make-dynamic-script (markup #:normal-text #:italic "sim."))

%% Two-sided labelled text spanner with arrowhead
arrowSpan = #(define-event-function (left right) (markup? markup?)
  #{
    \tweak direction #UP
    \tweak style #'line
    \tweak thickness #1

    \tweak arrow-length #0.8
    \tweak arrow-width #0.5
    \tweak bound-details.right.arrow ##t

    \tweak bound-details.left.text \markup { \small #left \hspace #0.5 }
    \tweak bound-details.left-broken.text ##f
    \tweak bound-details.left.stencil-align-dir-y #CENTER

    \tweak bound-details.right.text \markup { \hspace #0.5 \small #right }
    \tweak bound-details.right-broken.text ##f
    \tweak bound-details.right.stencil-align-dir-y #CENTER
    \startTextSpan
  #})

%% Circled-tip hairpins
daln = -\tweak Hairpin.circled-tip ##t \<
aln  = -\tweak Hairpin.circled-tip ##t \>

%% Suppress staff lines / ledger lines (e.g. for harmonics passages)
ss = #(define-music-function (music) (ly:music?)
  #{
    \stopStaff
    \override Staff.StaffSymbol.stencil = ##f
    \override Staff.LedgerLineSpanner.stencil = ##f
    \startStaff
    #music
    \stopStaff
    \revert Staff.LedgerLineSpanner.stencil
    \revert Staff.StaffSymbol.stencil
    \startStaff
  #})

%% Single-measure repeat barlines
staffRepeat = #(define-music-function (music) (ly:music?)
  #{
    \once \set Staff.whichBar = ".|:"
    #music
    \once \set Staff.whichBar = ":|."
  #})

%% Shared \layout: drop this straight into a \score block as
%%   \score { ... \houseLayout }
houseLayout = \layout {
  indent = 0.5\in
  \context {
    \Score
    proportionalNotationDuration = #(ly:make-moment 1/8)
    \remove Bar_engraver
    \override BarNumber.extra-offset = #'(0 . 3)
    measureBarType = "'"
  }
  \context {
    \Global
    \grobdescriptions #all-grob-descriptions
  }
  \context {
    \Voice
    \consists \frameEngraver
  }
}

%% Shared \paper settings (top-level \paper blocks merge automatically
%% with any \paper block in the piece file)
\paper {
  system-system-spacing = #'((basic-distance . 20) (padding . 4))
  markup-system-spacing = #'((basic-distance . 8) (padding . 2))
  % top-markup-spacing = #'((basic-distance . 4)
  %                         (minimum-distance . 0)
  %                         (padding . 1))
    oddHeaderMarkup = \markup \column {
    \fill-line {
      ""
      \unless \on-first-page-of-part \fromproperty #'header:instrument
      \if \should-print-page-number \fromproperty #'page:page-number-string
    }
    \vspace #2
  }

  %% evenHeaderMarkup no longer inherits oddHeaderMarkup once you
  %% define oddHeaderMarkup yourself, so define this too
  evenHeaderMarkup = \markup \column {
    \fill-line {
      \if \should-print-page-number \fromproperty #'page:page-number-string
      \unless \on-first-page-of-part \fromproperty #'header:instrument
      ""
    }
    \vspace #2
  }
}