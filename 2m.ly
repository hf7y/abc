%%% reel1.ly
%%% Reel 1 — score assembly.

\version "2.24.0"
\include "./lib/includes.ily"

\include "./2m1.ily"


%%% ── TRACKS ──────────────────────────────────────────────────────────

% vnTrack   = { \twoMone_vn   }
% vciTrack  = { \twoMone_vci  }
% vciiTrack = { \twoMone_vcii }
cbTrack   = { \twoMone_cb   }


%%% ── SCORE ───────────────────────────────────────────────────────────

\book {

  \header {
    title    = "Reel 1"
    composer = "Z.V. Pine"
    tagline  = "260700"
  }

  \score {
    \header {
      piece    = "Cue"
      opus     = "2M1"
    }
    \new StaffGroup <<
      % \new Staff \with { instrumentName = "Vn" } \vnTrack
      % \new StaffGroup \with {
      %   systemStartDelimiter = #'SystemStartBrace
      %   instrumentName       = "Vc"
      % } <<
      %   \new Staff \with { instrumentName = "1" } \vciTrack
      %   \new Staff \with { instrumentName = "2" } \vciiTrack
      % >>
      \new Staff \with { instrumentName = "Cb" } \cbTrack
    >>
  }
}