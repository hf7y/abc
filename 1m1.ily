%%% 1m1.ily
\header {
  piece    = "Coin"
  opus     = "1M1"
  % tempo    = "Quarter = 60"   % string, not a number — for display only
}

oneMone_vn = \transpose c c' {
  \clef "treble"
  \time 4/4

  \ss { R1 s1 } |
  \ss { s1 } | <d fis\harmonic>1~\daln |
  <d fis\harmonic>1~\pp^\arrowSpan #ord #sp | <fis\harmonic d>1\stopTextSpan\glissando\< |
  \half-harmonic fis1\glissando\p | \ss \square fis?1~\< |
  \ss \square fis1~\aln\f^"overpress." | \ss \square fis1 | \ss { R1\! | s1*3 } | \bar "|."

  bes'1~\fp\>^\arrowSpan #ord #sp | bes'1\pp\glissando | \square \ss bes'?1\stopTextSpan\aln | \ss R1\! | R1 \bar "|."

  b'!1~\fp\>^\arrowSpan #ord #sp | b'1\pp\glissando | \square \ss b'1\stopTextSpan\aln | \ss R1\! | R1 \bar "|."
}

oneMone_vci = \transpose c c, {
  \clef "bass"
  \time 4/4

  \ss R1 | <d' d''\harmonic>1\4~\daln^\st <d' d''\harmonic>2\3\laissezVibrer r2\!\pp |
  <g d'\harmonic>2\laissezVibrer\daln r2\!\pp |
  <g d'\harmonic>2\laissezVibrer\daln^\arrowSpan #"(tasto)" #sp r2\!\pp | <g d'\harmonic>2\laissezVibrer\daln r2\p |
  <g d'\harmonic>2\laissezVibrer\daln r2\p |
  <g d'\harmonic>2\daln r2\f | <g d'\harmonic>2\daln\stopTextSpan r2\f |
  \half-harmonic d'2\laissezVibrer\daln\3 r2\p | \half-harmonic d'2\laissezVibrer\daln r2\p |
  \half-harmonic d'2\laissezVibrer\daln r2\pp | \half-harmonic d'2\laissezVibrer\daln r2\pp |
  \ss R1 | \bar "|."

  <d' fis'\harmonic>1~\fp\>^\sp | <fis'\harmonic d>1\pp\glissando | \half-harmonic fis'?1\aln | R1\! | R1 \bar "|."

  <d' fis'\harmonic>1~\fp\>^\sp | <fis'\harmonic d>1\pp\glissando | \half-harmonic fis'?1\aln | R1\! | R1 \bar "|."
}

oneMone_vcii = \transpose c c, {
  \clef "bass"
  \time 4/4

  \ss R1 | <d' d''\harmonic>1\laissezVibrer\daln^\st |
  r2\!\pp <d' d''\harmonic>2\laissezVibrer\daln | r2\!\pp <g d'\harmonic>2\laissezVibrer\daln |
  r2\!\pp <d' d''\harmonic>2\laissezVibrer\daln^\arrowSpan #"(tasto)" #sp | r2\!\pp <d' d''\harmonic>2\laissezVibrer\daln |
  r2\!\p <d' d''\harmonic>2\laissezVibrer\daln |
  r2\!\p <d' d''\harmonic>2\laissezVibrer\daln | r2\!\f <d' d''\harmonic>2\laissezVibrer\daln\stopTextSpan |
  r2\!\f \half-harmonic d''\2\laissezVibrer\daln | r2\!\p \half-harmonic d''\laissezVibrer\daln |
  r2\!\p <d' d''\harmonic>2\laissezVibrer\daln | r2\!\pp <d' d''\harmonic>2\laissezVibrer\daln |
  \ss R1\!\pp \bar "|."

  <a' a''\harmonic>1~\fp\>^\sp | <a''\harmonic a'>1\glissando |
  \half-harmonic a''1\1~\pp^\arrowSpan #"(pont.)" #st | \half-harmonic a''1\aln\stopTextSpan |
  \ss R1\! | \bar "|."

  <a' a''\harmonic>1~\fp\>^\sp | <a''\harmonic a'>1\glissando |
  \half-harmonic a''1\1~\pp^\arrowSpan #"(pont.)" #st | \half-harmonic a''1\aln\stopTextSpan |
  \ss R1\! | \bar "|."
}

oneMone_cb = \transpose c c,, {
  \clef "bass_8"
  \time 4/4

  g1\pp~ | g1\glissando |
  \half-harmonic g1\glissando | \square \ss g1\aln |
  \ss { R1\! | R1 } |
  <g''\harmonic g'>1~\4^\sp\daln | <g''\harmonic g'>1\glissando\p |
  \half-harmonic g''1\glissando | \square \ss g''1~\aln |
  \square \ss g''1 | \ss { R1\! s1*2 } \bar "|."

  <g' c''\harmonic>1~\fp\>^\arrowSpan #sp #st | <c''\harmonic g' >1\pp\glissando\stopTextSpan | \half-harmonic c''1\1\aln | R1\! | R1 \bar "|."

  <g' c''\harmonic>1~\fp\>^\arrowSpan #sp #st | <c''\harmonic g' >1\pp\glissando\stopTextSpan | \half-harmonic c''1\1\aln | R1\! | R1 \bar "|."
}