%%% 1m2.ily
%%% Cue: 1M2 — ii. Water
%%% Pure musical data.

\header {
  piece    = "Water"
  opus     = "1M2"
  tempo    = "Quarter = 60"   % string, not a number — for display only
}

oneMtwo_vn = \transpose c c' {
  \clef "treble"
  \time 2/2

  \ss { R1 | \square a,1\1~\daln^\st |
  \square a,1\pp\glissando } | \half-harmonic a,1\glissando |
  a,1~^\arrowSpan #"(tasto)" #ord | a,1~ |
  a,1~\< | a,1~\stopTextSpan |
  a,1~\p^\arrowSpan #"" #sp | a,1~ |
  a,1~ | a,1\stopTextSpan\glissando |
  \ss { \square a,1\daln~ | \square a,1~ | }
  \ss { \square a,1\f\<\glissando | \square a1\4\glissando | << { \once \hide NoteHead a'1\ff } R1 >> | R1 } |

  % \bar "|."

  \ss R1*2 |
  <a'\harmonic a>1^\sp\daln\glissando | \half-harmonic a'1\glissando\3 | \ss \square a'1\f\aln~ | \ss \square a'1 | \ss R1\! \bar "|."
}

oneMtwo_vci = \transpose c c, {
  \clef "bass"
  \time 2/2

  \ss r2_\markup { "scord." \tiny "ADGD" } d2^\st\daln | \frameStart d'2\pp d2 |
  <d d'\harmonic>2 \frameEnd d2 |
  \ss { s1 | s1^\arrowSpan #"(tasto)" #ord |
  s1 | s1\< | s1\stopTextSpan } \frameExtenderEnd |
  \frameStart d'2\p \square d'2 | <d d'\harmonic>2 \frameEnd \square d'2 |
  \ss { s1^\arrowSpan #"(ord.)" #sp | s1 | }
  \ss { s1 | s1\stopTextSpan\frameExtenderEnd | }
  \frameStart d'2\p \frameEnd \square d'2 |
  \ss { s1 s1 \frameExtenderEnd | R1 | R1 | R1 | }

  % \bar "|."

  <d' a'\harmonic>2\daln\laissezVibrer r2\f | \ss { R1 | } |
  \half-harmonic a'2\3\daln\laissezVibrer r2\p
  \ss { R1 | R1 }
  \bar "|."
}

oneMtwo_vcii = \transpose c c, {
  \clef "bass"
  \time 2/2

  \ss r4_\markup { "scord." \tiny "ADGD" } d2^\st\daln <d d'\harmonic>4~ | \frameStart <d d'\harmonic>4\pp d2 d'4~ |
  d'4 d2 \frameEnd <d d'\harmonic>4~ | \ss { \once \hide NoteHead \once \hide Stem <d d'\harmonic>4 s2. } |
  \ss { s1^\arrowSpan #"(tasto)" #ord | s1 |
  s1\< | s2.\stopTextSpan \once \hide NoteHead \once \hide Stem <d d'\harmonic>4~ } \frameExtenderEnd |
  \frameStart <d d'\harmonic>4\p \square d'2 d'4~ | d'4 \square d'2 \frameEnd <d d'\harmonic>4~ |
  \ss { \once \hide NoteHead \once \hide Stem <d d'\harmonic>4^\arrowSpan #"(ord.)" #sp s2. | s1 }
  \ss { s1\stopTextSpan | s2.\frameExtenderEnd \once \hide NoteHead \once \hide Stem <d d'\harmonic>4~ | }
  \frameStart <d d'\harmonic>4\p \square d'2 \frameEnd <d d'\harmonic>4~ | \ss { \once \hide NoteHead \once \hide Stem <d d'\harmonic>4 s2. | }
  \ss { s1 | \frameExtenderEnd R1 | }

  \bar "|."

  \ss R1 | <d a\harmonic>2\daln\laissezVibrer^\sp r2\f |
  \ss { R1 | } <a a'\harmonic>2\daln\laissezVibrer r2\p | \ss { R1 | }
  \half-harmonic a'2\2\daln\laissezVibrer r2\pp | \ss R1 \bar "|."
}

oneMtwo_cb = \transpose c c,, {
  \clef "bass_8"
  \time 2/2

  d1~\fp\>\1_\markup { "scord." \tiny "GDAD" }^\st d1~ | d1~ | d1 |
  d1~\pp^\arrowSpan #"(tasto)" #ord d1~ | d1~\stopTextSpan\< | d1 |
  <d a\harmonic>1\p~ | <d a\harmonic>1\glissando | d1~^\arrowSpan #"(ord.)" #st | d1~ |
  \ss <d a>1\stopTextSpan | R1*3 |
  \ss R1*2 |

  \bar "|."

  <a d'\harmonic>1~\pp\<^\arrowSpan #ord #sp | <d'\harmonic a>1\glissando |
  \half-harmonic d'\glissando\3 | \ss \square d'\f\stopTextSpan\aln~ | \ss \square <g d'>1~ | \ss \square <g d'>1 | \ss R1\! | \bar "|."
}