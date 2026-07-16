%%% lib/core/noteheads.ily
%%% Notehead stencil library — visual primitives only.
%%% No instrument assumptions. No articulation semantics.
%%% No engravers. No context modifications.
%%%
%%% Provides raw stencil functions that other core modules use to build
%%% instrument-specific articulation systems (see strings.ily).
%%%
%%% CONTENTS:
%%%   square-head-stencil — filled square, duration-aware geometry
%%%
%%% EXTENDING:
%%%   Add new stencil functions here following the square-head-stencil
%%%   pattern: take a grob, return a stencil, duration-aware. Do not
%%%   assign musical meaning here — that belongs in the module that
%%%   uses the stencil (e.g. strings.ily's contact articulations).

\version "2.24.0"

#(ly:message "core/noteheads.ily loaded")


%%% ── SQUARE NOTEHEAD STENCIL ─────────────────────────────────────────
%%% Duration-aware filled square geometry.
%%% Whole note: open square with inner square (wholeSquare path)
%%% Half note:  open square with angled inner (halfSquare path)
%%% Quarter+:   solid filled box
%%%
%%% Returns a stencil. Does not set NoteHead.style —
%%% that is the responsibility of the calling engraver.

#(define square-whole-path
   '((moveto -0.7  0.54)
     (lineto -0.7 -0.52)
     (lineto  0.7 -0.52)
     (lineto  0.7  0.54)
     (lineto -0.7  0.54)
     (lineto -0.65  0.5)
     (lineto  0.45  0.5)
     (lineto  0.65 -0.48)
     (lineto -0.45 -0.48)
     (lineto -0.65  0.5)
     (closepath)))

#(define square-half-path
   '((moveto -0.6  0.52)
     (lineto -0.6 -0.50)
     (lineto  0.6 -0.50)
     (lineto  0.6  0.52)
     (lineto -0.6  0.52)
     (lineto -0.53  0.35)
     (lineto  0.53  0.49)
     (lineto  0.53 -0.33)
     (lineto -0.53 -0.47)
     (lineto -0.53  0.35)
     (closepath)))

#(define (square-head-stencil grob)
   "Return a square notehead stencil appropriate for the grob's duration.
Quarter notes and shorter: solid filled box.
Half notes: open square with angled inner path.
Whole notes: open square with inner square path."
   (let ((duration (ly:grob-property grob 'duration-log)))
     (cond
       ((>= duration 2)
        (grob-interpret-markup grob
          #{
            \markup \halign #-1.5
              \filled-box #'(-0.6 . 0.6) #'(-0.5 . 0.5) #0
          #}))
       ((= duration 1)
        (grob-interpret-markup grob
          #{
            \markup \halign #-1.5
              \override #'(filled . #t) \path #0.1 #square-half-path
          #}))
       (else
        (grob-interpret-markup grob
          #{
            \markup \halign #-0.7
              \override #'(filled . #t) \path #0.1 #square-whole-path
          #})))))
