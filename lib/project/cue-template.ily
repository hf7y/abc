%%% lib/project/cue-template.ily
%%% Copy this file to the repo root as the next cue (e.g. `3m1.ily`) and
%%% fill in every placeholder marked <<LIKE-THIS>>, including in the
%%% variable names themselves. Not \included by anything -- a starting
%%% point, not a library module.
%%%
%%% Why this exists: the bug it guards against (2m1.ily silently keeping
%%% 1m1.ily's variable names after a copy-paste) is a renaming mistake
%%% INSIDE this kind of file, not in the reel that includes it.
%%% Placeholders that don't look like a plausible real answer are harder
%%% to leave in than a real name borrowed from whatever file was copied.
%%% The variable prefix below must match this file's own `opus` header
%%% field; that mismatch is exactly what shipped unnoticed in 2m1.ily.
%%%
%%% Naming: <<reel>><<cue>>_<<instrument>>, spelled out because LilyPond
%%% identifiers can't start with a digit -- e.g. reel 3 cue 1 is
%%% "threeMone" (three + M + one). Every variable in this file must start
%%% with that SAME spelled prefix; the reel file that \includes this
%%% references them by that exact prefix too.
%%%
%%% The \transpose c c' / c c, / c c,, wrapping each instrument below is
%%% NOT related to project/instruments.ily's \transposition (that's for
%%% actual transposing winds; these four are all non-transposing
%%% strings). It's an OCTAVE-ENTRY convention, confirmed by reading the
%%% real cue files (1m1.ily etc.): pitches are typed in absolute-pitch
%%% mode (no \relative) using octave marks clustered the same way across
%%% all four instruments (e.g. an unmarked "g" or a single-mark "d'"),
%%% which is what lets you SEE shared pitch classes/harmonic relationships
%%% between parts directly in the source (real cues here lean heavily on
%%% shared drone pitches and natural harmonics across the whole string
%%% section). The wrapping then corrects each part into its actual
%%% sounding register: \transpose c c' shifts the violin UP an octave,
%%% \transpose c c, shifts each cello DOWN an octave, \transpose c c,,
%%% shifts the bass DOWN two octaves. Keep writing new music inside these
%%% same wrappers using that same shared-octave convention (don't type
%%% final absolute pitches expecting them to land as written -- they'll
%%% be off by whatever this cue's wrapper shifts them).

\header {
  piece    = "<<CUE NAME, e.g. Coin>>"
  opus     = "<<REEL>>M<<CUE>>"   % e.g. "3M1" -- must match the spelled
                                   % prefix in the variable names below
}

<<reel>><<cue>>_vn = \transpose c c' {
  \clef "treble"
  \time 4/4

}

<<reel>><<cue>>_vci = \transpose c c, {
  \clef "bass"
  \time 4/4

}

<<reel>><<cue>>_vcii = \transpose c c, {
  \clef "bass"
  \time 4/4

}

<<reel>><<cue>>_cb = \transpose c c,, {
  \clef "bass_8"
  \time 4/4

}
