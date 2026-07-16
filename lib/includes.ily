%%% lib/includes.ily
%%% Public API — the only lib file included by score files.
%%% All other lib files are implementation details.
%%%
%%% Rule: \include "./lib/includes.ily" is the only lib include
%%%       that should ever appear in a reel file (e.g. 1m.ly) or cue
%%%       .ily file.
%%%
%%% Thin loader: generic core/ (promotable to its own repo later) first,
%%% then this project's house style. See lib/README.md for the split.

\version "2.24.0"

\include "core/includes.ily"
\include "project/instruments.ily"
\include "project/style.ily"
\include "project/timing.ily"
