%%% lib/core/includes.ily
%%% Aggregates the generic (non-ABC-specific) notation library.
%%%
%%% This is the exact unit meant to be promoted to a standalone repo
%%% later (working name: zly) via `git subtree split -P lib/core`. It
%%% has zero dependencies on anything in lib/project/ — do not add any
%%% here.
%%%
%%% LOAD ORDER:
%%%   noteheads before strings — strings.ily uses square-head-stencil.
%%%   notation and frame-engraver have no dependencies.

\version "2.24.0"

\include "noteheads.ily"
\include "notation.ily"
\include "frame-engraver.ily"
\include "strings.ily"
