%%% lib/project/reel-template.ly
%%% Copy this file to the repo root as the next reel (e.g. `3m.ly`) and
%%% fill in the placeholders marked <<LIKE-THIS>>. Not \included by
%%% anything -- it's a starting point, not a library module, so editing
%%% or ignoring it can never break a real reel.
%%%
%%% Why this exists: 1m.ly/2m.ly were each written by copy-pasting the
%%% previous reel and hand-editing every place that needed to change.
%%% That already produced two real, confirmed bugs (see TODO.md): 2m1.ily
%%% kept 1m1.ily's variable names, and 2m.ly itself still says "reel1.ly"
%%% /"Reel 1" in its own header. A blank-slate template with placeholders
%%% obviously meant to be replaced (rather than plausible-looking real
%%% values that are easy to forget to change) is aimed at that exact
%%% failure mode. This is a convention, not enforcement -- nothing
%%% requires using it, and copying it changes nothing about how existing
%%% reels work. Run check-cue-naming.sh (repo root) after filling it in;
%%% it catches exactly the class of mismatch that bit 2m1.ily.
%%%
%%% CONVENTIONS this encodes (see lib/README.md's "Reel & cue
%%% conventions" section for the fuller writeup):
%%%   - One \cueStartTime per reel, called once, here -- never inside a
%%%     cue .ily file. See the REEL/CUE OWNERSHIP note in timing.ily. It
%%%     sets a SCORE-level clock, not a per-staff one, so it only needs
%%%     to be written in ONE staff (the Vn staff below, by convention) --
%%%     don't add it to the Vc/Cb staves too "to be safe"; that's not
%%%     needed and isn't what \cueGapTo's own per-staff requirement
%%%     (next bullet) is about.
%%%   - Cue variable naming: <<REEL>><<CUE>>_<<INSTRUMENT>>, spelled out
%%%     (digits can't start a LilyPond identifier) -- e.g. reel 3 cue 1's
%%%     violin part is threeMone_vn. Keep the spelled prefix IDENTICAL
%%%     between the cue's own file and every reference to it here; that
%%%     mismatch is exactly what went wrong with 2m1.ily.
%%%   - \cueLabel at the start of each cue for a boxed mark in the score;
%%%     \cueTocEntry alongside it if you also want the cue in
%%%     \cueTimeline (they're independent -- see timing.ily).
%%%   - \cueGapTo between cues only where the movie actually has a silent
%%%     gap with a known next timecode; delete the example call below if
%%%     this reel's cues are simply back-to-back (the common case).
%%%   - \cueTotalTime on a trailing spacer after the reel's TRUE LAST
%%%     note (move it forward each time a new cue is appended) so the
%%%     reel's total runtime is always visible on the page.

\version "2.24.0"
\include "./lib/includes.ily"

\include "./<<REEL>><<CUE1>>.ily"
\include "./<<REEL>><<CUE2>>.ily"
%% \include "./<<REEL>><<CUE3>>.ily"   % add more cues as they exist


%%% ── TRACKS ──────────────────────────────────────────────────────────
%%% Concatenation IS accumulation (see timing.ily) -- listing cues here
%%% in order is all that's needed for \cueTime to track correctly through
%%% all of them, with zero extra bookkeeping.

vnTrack   = { \<<reel>><<cue1>>_vn   \<<reel>><<cue2>>_vn   }
vciTrack  = { \<<reel>><<cue1>>_vci  \<<reel>><<cue2>>_vci  }
vciiTrack = { \<<reel>><<cue1>>_vcii \<<reel>><<cue2>>_vcii }
cbTrack   = { \<<reel>><<cue1>>_cb   \<<reel>><<cue2>>_cb   }


%%% ── SCORE ───────────────────────────────────────────────────────────

\book {

  \header {
    title    = "Plunge"
    composer = "Z.V. Pine"
    tagline  = "<<DATE>>"
  }

  \markuplist \cueTimeline

  \score {
    \header { piece = "<<CUE1 DESCRIPTION>> / <<CUE2 DESCRIPTION>>" }
    \new StaffGroup <<
      %% \relative c' here is inert boilerplate as written -- every real
      %% note lives in the \include'd cue files, entered in absolute-pitch
      %% mode (see cue-template.ily) and already fully resolved by the
      %% time \<<reel>><<cue1>>_vn etc. are referenced here, so \relative
      %% has nothing left to adjust (confirmed: \relative cannot reach
      %% through a music-variable reference to reinterpret pitches that
      %% were already parsed absolute elsewhere). Kept as a harmless
      %% default in case bare notes ever get written directly in this
      %% Staff instead of through a cue file.
      \new Staff \with { instrumentName = "Vn" } \relative c' {
        \cueStartTime "<<M:SS or H:MM:SS -- this reel's start, from the EDL/spotting notes, NOT derived from a previous reel's rendered length>>"

        \cueLabel "<<REEL>>M<<CUE1>>"
        \<<reel>><<cue1>>_vn

        %% Only if the movie has a silent gap here with a KNOWN next
        %% timecode -- delete otherwise. Both arguments must be the SAME
        %% reel-start string used in \cueStartTime above, and the SAME
        %% music already placed since then (everything from \cueLabel
        %% down to here). Unlike \cueStartTime above, THIS needs repeating
        %% in every other staff too (Vc I/II, Cb below) if they also go
        %% silent here -- each with that staff's own preceding music --
        %% see timing.ily's MULTI-STAFF USE note.
        %% \cueGapTo "<<same reel start as above>>" "<<next timecode>>" { \<<reel>><<cue1>>_vn }

        \cueLabel "<<REEL>>M<<CUE2>>"
        \<<reel>><<cue2>>_vn

        s4\cueTotalTime
      }
      \new StaffGroup \with {
        systemStartDelimiter = #'SystemStartBrace
        instrumentName       = "Vc"
      } <<
        \new Staff \with { instrumentName = "1" } \vciTrack
        \new Staff \with { instrumentName = "2" } \vciiTrack
      >>
      \new Staff \with { instrumentName = "Cb" } \cbTrack
    >>
  }

}
