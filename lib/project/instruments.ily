%%% lib/project/instruments.ily
%%% Project-specific: instrument transposition and clef defaults for abc.
%%% Implementation detail. Do not include directly; use lib/includes.ily.
%%%
%%% OVER-COMPLICATION FLAG, whole file: as of this writing, NOTHING below
%%% is actually called by any real cue or reel file in this project --
%%% confirmed by grepping every .ly/.ily outside this one (this piece is
%%% strings-only so far: vn/vci/vcii/cb, no winds; and every real cue
%%% file, e.g. 1m1.ily, sets \clef "bass" etc. directly inline per cue
%%% instead of using celloClef/bassClef below). That inline-per-cue
%%% approach is arguably the right call, not an oversight to fix to match
%%% this file -- a cue can need its OWN clef change mid-cue (register
%%% jumps are normal for cello/bassoon), which a single track-level
%%% \celloClef call can't express anyway. So treat the CLEF DEFAULTS
%%% below as unverified-by-real-use speculative scaffolding, not a
%%% convention anything actually follows -- worth deleting if a future
%%% pass confirms nothing ever ends up using it, rather than left to
%%% imply a convention that isn't real.


%%% ── INSTRUMENT TRANSPOSITIONS ───────────────────────────────────────
%%% Apply at the top of a track definition in the reel file, e.g.:
%%%   clTrack = { \clarinetBb \oneMone_cl \oneMtwo_cl }
%%% (works as a bare element mixed into a sequence like this -- confirmed;
%%% \transposition doesn't need a \with block to take effect.)
%%%
%%% \transposition ONLY sets the Staff/Voice's instrumentTransposition
%%% context property -- confirmed empirically (a \midi{} test block,
%%% checking the actual note numbers in the .midi output) that this
%%% alone correctly shifts MIDI playback: a Bb instrument's written
%%% middle C sounds concert Bb, a major 2nd down -- MIDI note 60 becomes
%%% 58, matching what a real Bb clarinet/trumpet part should sound like.
%%%
%%% It does NOT transpose anything on the page -- confirmed empirically
%%% that \oneMone_cl written with \transposition bes and no other
%%% wrapping prints its pitches completely unchanged (still concert C if
%%% that's what's written), i.e. the printed page always shows whatever
%%% pitches are literally typed, full stop. A previous version of this
%%% comment claimed "conductor scores display concert pitch by default"
%%% -- that is FALSE, verified by direct compile-and-look. Since nothing
%%% here has been used by a real wind cue yet (see the file-level flag
%%% above), that false claim hasn't caused a real wrong-notes bug so far,
%%% but it would the moment someone trusts it. If/when a wind cue is
%%% written, either:
%%%   - type the instrument's own WRITTEN pitches directly (the same way
%%%     \oneMone_vn etc. already do, per cue-template.ily's \transpose
%%%     wrapping for octave convenience -- see that file), and rely on
%%%     \transposition only for correct MIDI/cue-note behavior, or
%%%   - type concert pitch and wrap with e.g. \transpose bes c' { ... }
%%%     to produce the correct WRITTEN pitch for the page.
%%% Neither path is automatic; \transposition alone does not pick one
%%% for you.

clarinetBb  = { \transposition bes }
hornF       = { \transposition f   }
trumpetBb   = { \transposition bes }


%%% ── CLEF DEFAULTS ───────────────────────────────────────────────────
%%% Apply at the top of a track definition in the reel file, e.g.:
%%%   vcTrack = { \celloClef \oneMone_vc \oneMtwo_vc }
%%% Not how any real cue actually sets its clef today -- see the
%%% file-level flag at the top of this file.

violaClef    = { \clef alto }
celloClef    = { \clef bass }
bassClef     = { \clef bass }
bassoonClef  = { \clef bass }
tromboneClef = { \clef bass }