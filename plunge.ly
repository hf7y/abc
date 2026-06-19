\include "orch-style.ily"

\header {
  title = "Plunge"
  composer = "Z.V. Pine"
  tagline = "260615"
}

i_coin_gm_vn = \transpose c c' {
  \clef "treble"
  \time 4/4

  \ss { R1 s1 } |
  \ss { s1 } | <d fis\harmonic>1~\daln |
  <d fis\harmonic>1~\pp^\arrowSpan #ord #sp | <fis\harmonic d>1\stopTextSpan\glissando\< |
  \half-harmonic fis1\glissando\p | \ss \square fis?1~\< |
  \ss \square fis1~\aln\f^"overpress." | \ss \square fis1 | \ss { R1\! | s1*3 } | \bar "|." \break

  bes'1~\fp\>^\arrowSpan #ord #sp | bes'1\pp\glissando | \square \ss bes'?1\stopTextSpan\aln | \ss R1\! | R1 \bar "|."

  b'!1~\fp\>^\arrowSpan #ord #sp | b'1\pp\glissando | \square \ss b'1\stopTextSpan\aln | \ss R1\! | R1 \bar "|."
}

i_coin_gm_vci = \transpose c c, {
  \clef "bass"
  \time 4/4

  \ss R1 | <d' d''\harmonic>1\4~\daln^\st <d' d''\harmonic>2\3\laissezVibrer r2\!\pp |
  <g d'\harmonic>2\laissezVibrer\daln r2\!\pp |
  <g d'\harmonic>2\laissezVibrer\daln^\arrowSpan #"(tasto)" #sp r2\!\pp | <g d'\harmonic>2\laissezVibrer\daln r2\p |
  <g d'\harmonic>2\laissezVibrer\daln r2\p |
  <g d'\harmonic>2\daln r2\f | <g d'\harmonic>2\daln\stopTextSpan r2\f |
  \half-harmonic d'2\laissezVibrer\daln\3 r2\p | \half-harmonic d'2\laissezVibrer\daln r2\p |
  \half-harmonic d'2\laissezVibrer\daln r2\pp | \half-harmonic d'2\laissezVibrer\daln r2\pp |
  \ss R1 | \bar "|." \break

  <d' fis'\harmonic>1~\fp\>^\sp | <fis'\harmonic d>1\pp\glissando | \half-harmonic fis'?1\aln | R1\! | R1 \bar "|."

  <d' fis'\harmonic>1~\fp\>^\sp | <fis'\harmonic d>1\pp\glissando | \half-harmonic fis'?1\aln | R1\! | R1 \bar "|."
}

i_coin_gm_vcii = \transpose c c, {
  \clef "bass"
  \time 4/4

  \ss R1 | <d' d''\harmonic>1\laissezVibrer\daln^\st |
  r2\!\pp <d' d''\harmonic>2\laissezVibrer\daln | r2\!\pp <g d'\harmonic>2\laissezVibrer\daln |
  r2\!\pp <d' d''\harmonic>2\laissezVibrer\daln^\arrowSpan #"(tasto)" #sp | r2\!\pp <d' d''\harmonic>2\laissezVibrer\daln |
  r2\!\p <d' d''\harmonic>2\laissezVibrer\daln |
  r2\!\p <d' d''\harmonic>2\laissezVibrer\daln | r2\!\f <d' d''\harmonic>2\laissezVibrer\daln\stopTextSpan |
  r2\!\f \half-harmonic d''\2\laissezVibrer\daln | r2\!\p \half-harmonic d''\laissezVibrer\daln |
  r2\!\p <d' d''\harmonic>2\laissezVibrer\daln | r2\!\pp <d' d''\harmonic>2\laissezVibrer\daln |
  \ss R1\!\pp \bar "|." \break

  <a' a''\harmonic>1~\fp\>^\sp | <a''\harmonic a'>1\glissando |
  \half-harmonic a''1\1~\pp^\arrowSpan #"(pont.)" #st | \half-harmonic a''1\aln\stopTextSpan |
  \ss R1\! | \bar "|."

  <a' a''\harmonic>1~\fp\>^\sp | <a''\harmonic a'>1\glissando |
  \half-harmonic a''1\1~\pp^\arrowSpan #"(pont.)" #st | \half-harmonic a''1\aln\stopTextSpan |
  \ss R1\! | \bar "|."
}

i_coin_gm_cb = \transpose c c,, {
  \clef "bass_8"
  \time 4/4

  g1\pp~ | g1\glissando |
  \half-harmonic g1\glissando | \square \ss g1\aln |
  \ss { R1\! | R1 } |
  <g''\harmonic g'>1~\4^\sp\daln | <g''\harmonic g'>1\glissando\p |
  \half-harmonic g''1\glissando | \square \ss g''1~\aln |
  \square \ss g''1 | \ss { R1\! s1*2 } \bar "|." \break

  <g' c''\harmonic>1~\fp\>^\arrowSpan #sp #st | <c''\harmonic g' >1\pp\glissando\stopTextSpan | \half-harmonic c''1\1\aln | R1\! | R1 \bar "|."

  <g' c''\harmonic>1~\fp\>^\arrowSpan #sp #st | <c''\harmonic g' >1\pp\glissando\stopTextSpan | \half-harmonic c''1\1\aln | R1\! | R1 \bar "|."
}

\score {
  \header { piece = "i. Coin" }
  \new StaffGroup \with {
    \override VerticalAxisGroup.staff-staff-spacing =
      #'((basic-distance . 10)
         (minimum-distance . 10)
         (padding . 4)
         (stretchability . 12))
  } <<
    \new Staff \with { instrumentName = "Vn" } { \global \i_coin_gm_vn }
    \new StaffGroup \with {
      systemStartDelimiter = #'SystemStartBrace
      instrumentName = "Vc"
    } <<
      \new Staff \with { instrumentName = "1" } { \global \i_coin_gm_vci }
      \new Staff \with { instrumentName = "2" } { \global \i_coin_gm_vcii }
    >>
    \new Staff \with { instrumentName = "Cb" } { \global \i_coin_gm_cb }
  >>
  \houseLayout
}

ii_water_vn = \transpose c c' {
  \clef "treble"
  \time 2/2

  \ss { R1 | \square a,1\1~\daln^\st | 
  \square a,1\pp\glissando } | \half-harmonic a,1\glissando | 
  a,1~^\arrowSpan #"(tasto)" #ord | a,1~ |
  a,1~\< | a,1~\stopTextSpan | 
  a,1~\p^\arrowSpan #"" #sp  | a,1~|
  a,1~ | a,1\stopTextSpan\glissando | 
  \ss { \square a,1\daln~ | \square a,1~ | }
  \ss { \square a,1\f\<\glissando | \square a1\4\glissando | << { \once \hide NoteHead a'1\ff } R1 >> | R1 } |

  % \bar "|." \pageBreak

  \ss R1*2 | 
  <a'\harmonic a>1^\sp\daln\glissando | \half-harmonic a'1\glissando\3 | \ss \square a'1\f\aln~ | \ss \square a'1 | \ss R1\! \bar "|."
}

ii_water_vci = \transpose c c, {
  \clef "bass"
  \time 2/2

  \ss r2_\markup { "scord." \tiny "ADGD" } d2^\st\daln | \frameStart d'2\pp d2 |
  <d d'\harmonic>2 \frameEnd d2 |
  \ss { s1 | s1^\arrowSpan #"(tasto)" #ord | 
  s1 | s1\< | s1\stopTextSpan } \frameExtenderEnd |
  \frameStart d'2\p \square d'2 | <d d'\harmonic>2 \frameEnd \square d'2 |
  \ss { s1^\arrowSpan #"(ord.)" #sp | s1 | }
  \ss { s1 | s1\stopTextSpan\frameExtenderEnd | }
   \frameStart d'2\p \frameEnd  \square d'2 | 
   \ss { s1 s1 \frameExtenderEnd | R1 | R1 | R1 | }

  % \bar "|." \pageBreak

  <d' a'\harmonic>2\daln\laissezVibrer r2\f | \ss { R1 | } |
  \half-harmonic a'2\3\daln\laissezVibrer r2\p
  \ss { R1 | R1 }
  \bar "|."
}

ii_water_vcii = \transpose c c, {
  \clef "bass"
  \time 2/2

  \ss r4_\markup { "scord." \tiny "ADGD" } d2^\st\daln <d d'\harmonic>4~ | \frameStart <d d'\harmonic>4\pp d2 d'4~ |
  d'4 d2 \frameEnd <d d'\harmonic>4~ | \ss { \once \hide NoteHead \once \hide Stem <d d'\harmonic>4 s2. } | 
  \ss { s1^\arrowSpan #"(tasto)" #ord | s1 | 
  s1\< | s2.\stopTextSpan \once \hide NoteHead \once \hide Stem <d d'\harmonic>4~ } \frameExtenderEnd |
  \frameStart <d d'\harmonic>4\p \square d'2 d'4~ |  d'4 \square d'2 \frameEnd <d d'\harmonic>4~  |
  \ss { \once \hide NoteHead \once \hide Stem <d d'\harmonic>4^\arrowSpan #"(ord.)" #sp s2. | s1 } 
  \ss { s1\stopTextSpan | s2.\frameExtenderEnd \once \hide NoteHead \once \hide Stem <d d'\harmonic>4~ | } 
  \frameStart <d d'\harmonic>4\p \square d'2  \frameEnd <d d'\harmonic>4~ | \ss { \once \hide NoteHead \once \hide Stem <d d'\harmonic>4 s2. | } 
  \ss { s1 | \frameExtenderEnd  R1 | } 

  \bar "|." \pageBreak

  \ss R1 | <d a\harmonic>2\daln\laissezVibrer^\sp r2\f |
  \ss { R1 | }  <a a'\harmonic>2\daln\laissezVibrer r2\p | \ss { R1 | }
  \half-harmonic a'2\2\daln\laissezVibrer r2\pp | \ss R1 \bar "|."
}

ii_water_cb = \transpose c c,, {
  \clef "bass_8"
  \time 2/2

  d1~\fp\>\1_\markup { "scord." \tiny "GDAD" }^\st d1~ | d1~ | d1 |
  d1~\pp^\arrowSpan #"(tasto)" #ord d1~ | d1~\stopTextSpan\< | d1 |
  <d a\harmonic>1\p~ | <d a\harmonic>1\glissando | d1~^\arrowSpan #"(ord.)" #st | d1~ |
  \ss <d a>1\stopTextSpan | R1*3 |
  \ss R1*2 |

  \bar "|." \pageBreak

  <a d'\harmonic>1~\pp\<^\arrowSpan #ord #sp | <d'\harmonic a>1\glissando |
  \half-harmonic d'\glissando\3 | \ss \square d'\f\stopTextSpan\aln~ | \ss \square <g d'>1~ | \ss \square <g d'>1 | \ss R1\! | \bar "|."
}

\score {
  \header { piece = "ii. Water" }
  \new StaffGroup \with {
    \override VerticalAxisGroup.staff-staff-spacing =
      #'((basic-distance . 10)
         (minimum-distance . 10)
         (padding . 4)
         (stretchability . 12))
  } <<
    \new Staff \with { instrumentName = "Vn" } { \global \ii_water_vn }
    \new StaffGroup \with {
      systemStartDelimiter = #'SystemStartBrace
      instrumentName = "Vc"
    } <<
      \new Staff \with { instrumentName = "1" } { \global \ii_water_vci }
      \new Staff \with { instrumentName = "2" } { \global \ii_water_vcii }
    >>
    \new Staff \with { instrumentName = "Cb" } { \global \ii_water_cb }
  >>
  \houseLayout
}