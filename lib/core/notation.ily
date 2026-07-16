%%% lib/core/notation.ily
%%% Instrument-agnostic notation vocabulary — shorthands written inside
%%% or alongside music. No instrument assumptions, no context
%%% modifications beyond the light functions below.
%%%
%%% CONTENTS:
%%%   Technique text markups   \sp \ord \st
%%%   Dynamic scripts          \sim
%%%   Hairpin shorthands       \daln \aln
%%%   Arrow spanner            \arrowSpan
%%%   Staff suppression        \ss
%%%   Repeat barlines          \staffRepeat
%%%   Scordatura markup        \scord (text label only — no transposition;
%%%                            the transposing scordatura system lives in
%%%                            strings.ily)
%%%   Cue label stub           \cueLabel (rehearsal-mark-style label;
%%%                            chronological timecode tracking for the
%%%                            notes within a cue is project/timing.ily's
%%%                            \cueTime/\cueStartTime)
%%%
%%% INSTRUMENT-SPECIFIC vocabulary does NOT belong here.
%%% String techniques (\halfHarmonic, \squareHead, \air) live in
%%% strings.ily. Transposing instrument shorthands are project-specific
%%% (see project/instruments.ily).

\version "2.24.0"

#(ly:message "core/notation.ily loaded")


%%% ── TECHNIQUE MARKUPS ───────────────────────────────────────────────
%%% Short italic text for bowing/contact position.
%%% Suffix usage: c4^\sp d^\ord e^\st -- the ^ (or -/_) is required.
%%% These are plain markups, not events, so a bare c4\sp with no
%%% direction indicator is silently dropped ("Ignoring non-music
%%% expression") rather than attaching -- confirmed empirically; this
%%% comment previously (wrongly) showed the bare form.

sp  = \markup \small \italic "pont."
ord = \markup \small \italic "ord."
st  = \markup \small \italic "tasto"


%%% ── DYNAMIC SCRIPTS ─────────────────────────────────────────────────
%%% sim. rendered as a dynamic-style script (aligns with hairpins).

sim = #(make-dynamic-script (markup #:normal-text #:italic "sim."))


%%% ── HAIRPIN SHORTHANDS ──────────────────────────────────────────────
%%% Circled-tip hairpins: dal niente / al niente.
%%% Suffix usage: c1\daln  d1\aln

daln = -\tweak Hairpin.circled-tip ##t \<
aln  = -\tweak Hairpin.circled-tip ##t \>


%%% ── ARROW SPANNER ───────────────────────────────────────────────────
%%% Two-sided labelled text spanner with right arrowhead.
%%% Usage: c1^\arrowSpan #"sul pont." #"ord." ... \stopTextSpan

arrowSpan = #(define-event-function (left right) (markup? markup?)
  #{
    \tweak direction                              #UP
    \tweak style                                  #'line
    \tweak thickness                              #1
    \tweak arrow-length                           #0.8
    \tweak arrow-width                            #0.5
    \tweak bound-details.right.arrow              ##t
    \tweak bound-details.left.text                \markup { \small #left \hspace #0.5 }
    \tweak bound-details.left-broken.text         ##f
    \tweak bound-details.left.stencil-align-dir-y  #CENTER
    \tweak bound-details.right.text               \markup { \hspace #0.5 \small #right }
    \tweak bound-details.right-broken.text        ##f
    \tweak bound-details.right.stencil-align-dir-y #CENTER
    \startTextSpan
  #})


%%% ── STAFF LINE SUPPRESSION ─────────────────────────────────────────
%%% Temporarily removes staff and ledger lines around a passage.
%%% Usage: \ss { c4 d e f }

ss = #(define-music-function (music) (ly:music?)
  #{
    \stopStaff
    \override Staff.StaffSymbol.stencil       = ##f
    \override Staff.LedgerLineSpanner.stencil = ##f
    \startStaff
    #music
    \stopStaff
    \revert Staff.LedgerLineSpanner.stencil
    \revert Staff.StaffSymbol.stencil
    \startStaff
  #})


%%% ── SINGLE-MEASURE REPEAT BARLINES ─────────────────────────────────
%%% Wraps a measure with .|: and :|. barlines.
%%% Usage: \staffRepeat { c1 }

staffRepeat = #(define-music-function (music) (ly:music?)
  #{
    \once \set Staff.whichBar = ".|:"
    #music
    \once \set Staff.whichBar = ":|."
  #})


%%% ── SCORDATURA MARKUP ───────────────────────────────────────────────
%%% Compact text indication. No transposition. No instrument knowledge.
%%% Usage: d1\scord "ADGD"
%%% Note: the full transposing scordatura system (\withScordatura) lives
%%% in strings.ily and is StringStaff-scoped.

scord = #(define-event-function (tuning) (string?)
  #{
    _\markup { \small \italic "scord." \hspace #0.3 \small #tuning }
  #})


%%% ── CUE LABEL ────────────────────────────────────────────────────────
%%% Placed at start of each cue's music block: a boxed rehearsal-mark
%%% label (e.g. "1M1"). Distinct from project/timing.ily's \cueTime,
%%% which prints the elapsed movie timecode at a given note, not a
%%% one-time label at the start of the cue.
%%% Usage: \cueLabel "1M1"

cueLabel = #(define-music-function (label) (string?)
  #{
    \mark \markup \box \bold #label
  #})
