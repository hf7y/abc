%%% reel1.ly
%%% Reel 1 — score assembly.

\version "2.24.0"
\include "./lib/includes.ily"

\include "./1m1.ily"
\include "./1m2.ily"


%%% ── TRACKS ──────────────────────────────────────────────────────────

vnTrack   = { \oneMone_vn   \oneMtwo_vn   }
vciTrack  = { \oneMone_vci  \oneMtwo_vci  }
vciiTrack = { \oneMone_vcii \oneMtwo_vcii }
cbTrack   = { \oneMone_cb   \oneMtwo_cb   }


%%% ── SCORE ───────────────────────────────────────────────────────────

\book {

  \header {
    title    = "Plunge"
    composer = "Z.V. Pine"
    tagline  = "260615"
  }

  \score {
    \header { piece = "i. Coin" }
    \new StaffGroup <<
      \new Staff \with { instrumentName = "Vn" } \vnTrack
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

  \score {
    \header { piece = "ii. Water" }
    \new StaffGroup \with {
      \override VerticalAxisGroup.staff-staff-spacing =
        #'((basic-distance   . 10)
           (minimum-distance . 10)
           (padding          . 4)
           (stretchability   . 12))
    } <<
      \new Staff \with { instrumentName = "Vn" } \vnTrack
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