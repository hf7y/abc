%%% lib/project/timing.ily
%%% Chronological (movie-timecode) tracking for film cues. Project-
%%% specific for now; promote to core/ once used across more than one
%%% project (see lib/README.md for the split rationale).
%%%
%%% CONTENTS:
%%%   \cueTime                 Suffix event -- prints elapsed timecode
%%%                            above the note/chord/rest it's attached to.
%%%   \cueTotalTime            Suffix event -- prints the running total
%%%                            so far, styled to stand out. Meant for the
%%%                            last note of a reel.
%%%   \cueStartTime "M:SS"     Sets the absolute movie-timecode offset
%%%                            for whichever \score this is called in
%%%                            (this Score's local 0:00 -- see the
%%%                            REEL/CUE OWNERSHIP note below for where
%%%                            this belongs).
%%%   \cueTocEntry "l" "d"     Suffix event -- prints nothing, registers
%%%                            a chronological entry ("l -- d -- time")
%%%                            for \cueTimeline below.
%%%   \cueTimeline             \markuplist command -- renders every
%%%                            \cueTocEntry registered anywhere in the
%%%                            \book, in chronological-registration order.
%%%   \cueGapTo "s" "t" \m     Computed silence: inserts exactly enough
%%%                            rest (visible whole measures + an exact
%%%                            invisible remainder) so the music right
%%%                            after it lands at absolute timecode "t",
%%%                            given \m is everything already written
%%%                            since this reel's own \cueStartTime "s".
%%%   \cueTempoTo u "s" "t" \m Computed tempo: prints a \tempo mark (in
%%%                            note-value u) that makes \m -- taken as
%%%                            written, regardless of any tempo already
%%%                            on it -- take exactly (t - s) seconds.
%%%                            The inverse problem from \cueGapTo: that
%%%                            one solves for a REST's length given a
%%%                            fixed tempo; this solves for the TEMPO
%%%                            given a fixed passage and a fixed target
%%%                            duration.
%%%   \cueUseSmpteFps 24       Switches \cueTime/\cueTotalTime/
%%%                            \cueTocEntry display to HH:MM:SS:FF SMPTE
%%%                            timecode at the given rate (##f to switch
%%%                            back to decimal M:SS.mmm).
%%%
%%% REEL/CUE OWNERSHIP -- confirmed from this project's actual structure
%%% (1m.ly, 1m1.ily, 1m2.ily): a cue file (1m1.ily) defines bare music
%%% variables with no \score of its own; a reel file (1m.ly) \includes
%%% several cues and concatenates them into one continuous per-instrument
%%% Staff (vnTrack = { \oneMone_vn \oneMtwo_vn }), all inside ONE \score.
%%% Since ly:context-current-moment is cumulative from that \score's own
%%% start, cue 1M2's music continues 1M1's clock automatically, for free,
%%% with no extra code -- concatenation IS accumulation.
%%%
%%% Consequence: \cueStartTime belongs in the REEL file, called once,
%%% right before the first cue's music -- never inside an individual cue
%%% file. If each cue file called \cueStartTime with its own
%%% author-guessed offset, concatenating them would silently let the
%%% later cue's guess overwrite the earlier cue's real accumulated
%%% position the moment it's reached, with no warning -- exactly the
%%% class of silent-wrongness bug the rest of this library's design notes
%%% keep surfacing elsewhere. One reel, one \cueStartTime.
%%%
%%% Reel-to-reel is different and deliberately NOT automated: a reel's
%%% start timecode comes from the locked picture edit (external,
%%% authoritative), not from how long the previous reel's own music
%%% happened to render. Auto-deriving Reel 2's offset from Reel 1's
%%% played-out duration would get the causality backwards -- if the
%%% music ever runs long or short against the real edit, that mismatch
%%% is exactly the information worth surfacing, not silently absorbed.
%%% Type each reel's own \cueStartTime from the spotting notes/EDL.
%%%
%%% DESIGN NOTE -- how this works and why:
%%% \cueTime is a real TextScriptEvent (the same event class ordinary
%%% ^"text"/^\markup{} postfix text uses), not a custom event class and
%%% not a manually-constructed grob. Confirmed empirically: piggybacking
%%% on ArticulationEvent/Script (the mechanism strings.ily's contact
%%% articulations use) cannot render arbitrary text -- Script grobs are
%%% feta-glyph-only and throw "Cannot get a text stencil from this font."
%%% TextScriptEvent's own built-in engraver already creates a correctly
%%% positioned, correctly styled TextScript grob (font, spacing,
%%% collision-avoidance, and this project's own TextScript house-style
%%% overrides in project/style.ily all apply automatically) -- cueTime
%%% just tags the event with 'cue-time-marker so cueTimeEngraver below
%%% can recognize its own grobs and overwrite their placeholder text with
%%% the real computed value.
%%%
%%% Timing math: tempo is read directly off each TempoChangeEvent's own
%%% 'metronome-count/'tempo-unit properties (metronome ranges like
%%% "60-72" are averaged), not off the Score.tempoWholesPerMinute context
%%% property -- confirmed empirically that \tempo expands into a
%%% SequentialMusic of [the event, then a separate property-set], so the
%%% context property is not yet updated at the instant the raw event
%%% fires. The engraver accumulates elapsed seconds at each tempo change
%%% (moment-delta since the last change, converted via the tempo active
%%% over that span) and extends that same calculation on demand whenever
%%% a \cueTime grob needs its value frozen. A text-only \tempo "Andante"
%%% (no count/unit) is handled gracefully: the accumulator still flushes
%%% up to that moment, but the tempo itself is left unchanged, since
%%% there's nothing to compute a new one from.
%%%
%%% Installed once, at \Score (not per-Voice): confirmed empirically that
%%% a single Score-scoped instance correctly receives tempo-change events
%%% regardless of which Staff/Voice they were written in, AND correctly
%%% acknowledges TextScript grobs created in any descendant Staff/Voice
%%% -- this matters for real cue files, which are multi-instrument
%%% StaffGroups where tempo is typically marked once but \cueTime may be
%%% used in any staff. If this project ever needs independently-clocked
%%% simultaneous timelines in one score, that would need re-deriving.
%%%
%%% \cueTime intentionally does NOT need the chord-member-independence
%%% machinery strings.ily's contact articulations required (two delivery
%%% mechanisms depending on bare-note vs. chord-member syntax). A cue
%%% timestamp is inherently one-per-moment regardless of how many notes
%%% are stacked at that moment, so attaching it anywhere in a chord and
%%% getting exactly one label is the correct behavior, not a limitation.
%%%
%%% USAGE:
%%%   \cueStartTime "3:12.5"     % this cue's \score starts at 3:12.500
%%%                              % into the film (parses M:SS or H:MM:SS)
%%%   c4\cueTime d e f |         % prints elapsed timecode above the note
%%%
%%% NOT YET DONE / assumptions worth re-checking if this gets promoted:
%%%   - DONE (was listed here as not-yet-done): SMPTE HH:MM:SS:FF display
%%%     is now available via \cueUseSmpteFps -- see PUBLIC VOCABULARY.
%%%     Does not implement drop-frame timecode's skipped-number
%%%     convention; see the note above cue-format-timecode-smpte.
%%%   - No reset function: each \score's own Score context gives
%%%     cueTimeEngraver a fresh closure, so every cue file's timeline
%%%     naturally starts at 0 (then \cueStartTime supplies the absolute
%%%     offset) -- there's deliberately no mid-score reset, since that's
%%%     not how film cues work (a cue is one continuous timeline from its
%%%     start point).
%%%
%%% QC PASS (2026-07-16) -- additional cases tested beyond the original
%%% test suite, each confirmed empirically (not just reasoned about):
%%%   - Grace notes: correctly invisible to the clock. A grace note only
%%%     moves the moment's grace component, not its main component, and
%%%     cueTimeEngraver only ever reads ly:context-current-moment (the
%%%     whole moment) through ly:moment-main in flush-to -- confirmed
%%%     c4\cueTime \grace d8 e4\cueTime shows the SAME time on both notes
%%%     the grace note doesn't cost any real time, correctly.
%%%   - Tuplets: correctly scaled. \times 2/3 { c4\cueTime d4 e4 } f4 --
%%%     the tuplet's compressed real duration (2 quarters' worth of time
%%%     for 3 notated quarters) is exactly what ly:context-current-moment
%%%     already reflects, so no tuplet-aware code was needed here.
%%%   - \repeat unfold: each repetition is a genuinely separate event in
%%%     the expanded music tree (unfold literally duplicates), so
%%%     \cueTime inside a repeated block correctly produces one distinct,
%%%     correctly-incremented timecode per repetition -- confirmed
%%%     \repeat unfold 3 { c4\cueTime d e f } produces three different
%%%     values 4s apart. The same is true of \cueTocEntry, which is
%%%     usually NOT what you want: it registers one timeline ENTRY per
%%%     repetition, with the identical label text but a different time on
%%%     each line. If you want a single timeline entry for a repeated
%%%     passage, place \cueTocEntry outside/before the \repeat, not
%%%     inside it.
%%%   - No \tempo at all: falls through to the hardcoded 60bpm default
%%%     (matching LilyPond's own MIDI default in performer-init.ly), not
%%%     a crash or a zero tempo. Confirmed with a \cueTime-only score with
%%%     no \tempo command anywhere.
%%%   - Malformed \cueStartTime argument: warns clearly via ly:warning
%%%     and falls back to offset 0, confirmed does not halt compilation.
%%%   - Mid-cue \cueStartTime resync: calling it again partway through a
%%%     cue's music works as a manual drift-correction point -- the new
%%%     offset REPLACES (not adds to) the old one, applies only to
%%%     \cueTime/\cueTocEntry from that point forward, and does not
%%%     retroactively change already-frozen earlier values (each is
%%%     frozen into its own grob at its own acknowledge-time, using
%%%     whatever offset was active then). Confirmed with two \cueStartTime
%%%     calls in one cue's music, second one showing a resynced value.
%%%   - KNOWN LIMITATION, not fixed (low priority, fringe use case): a
%%%     leading minus sign on a ZERO minutes/hours field is lost --
%%%     \cueStartTime "-0:05" parses as +5s, not -5s, because Guile's
%%%     (string->number "-0") is 0, not -0.0. A genuinely negative offset
%%%     still works fine as long as the signed field is nonzero, e.g.
%%%     "-1:05" correctly parses as -65s. Movie timecodes are not
%%%     normally negative, so this wasn't fixed.
%%%   - Interaction worth knowing about (not a timing.ily bug -- see the
%%%     LilyPond bug note near \cueGapTo further down for a related, but
%%%     separate, real engraver bug): several \tempo commands in a row
%%%     with no note between them make LilyPond's OWN
%%%     Metronome_mark_engraver warn "conflict with event"/"discarding
%%%     event" and print only the FIRST mark. cueTimeEngraver's listener
%%%     still receives and applies all of them in order, so the ACTUAL
%%%     tempo used for \cueTime's math ends up being the LAST one issued
%%%     -- correct for timing purposes, but it means the printed tempo
%%%     mark and the tempo actually in effect can visually disagree in
%%%     this specific degenerate case. Real cue-writing has no reason to
%%%     stack bare tempo changes like this, so this is documented rather
%%%     than special-cased.

\version "2.24.0"

#(ly:message "project/timing.ily loaded")


%%% ── CONTEXT PROPERTY REGISTRATION ───────────────────────────────────

#(set-object-property! 'cueTimeOffset 'translation-type? number?)
#(set-object-property! 'cueTimeOffset 'translation-doc
   "Absolute movie-timecode (seconds) that this cue's local 0:00 maps to")

#(set-object-property! 'cueSmpteFps 'translation-type? (lambda (x) (or (not x) (number? x))))
#(set-object-property! 'cueSmpteFps 'translation-doc
   "#f (default) for decimal M:SS.mmm display, or a frame rate (24, 25,
    29.97, 30, ...) to display HH:MM:SS:FF SMPTE timecode instead")


%%% ── TIMECODE FORMATTING ─────────────────────────────────────────────

%%% M:SS.mmm below one hour, H:MM:SS.mmm from one hour up -- matches
%%% common spotting-sheet convention without assuming a frame rate.
#(define (cue-format-timecode seconds)
   (let* ((total-ms (inexact->exact (round (* seconds 1000))))
          (hours    (quotient total-ms 3600000))
          (rem1     (remainder total-ms 3600000))
          (mins     (quotient rem1 60000))
          (secs     (/ (remainder rem1 60000) 1000.0)))
     (if (> hours 0)
         (format #f "~a:~a:~a" hours
                 (if (< mins 10) (format #f "0~a" mins) mins)
                 (if (< secs 10) (format #f "0~,3f" secs) (format #f "~,3f" secs)))
         (format #f "~a:~a" mins
                 (if (< secs 10) (format #f "0~,3f" secs) (format #f "~,3f" secs))))))

%%% HH:MM:SS:FF SMPTE timecode at a given frame rate -- opt-in via
%%% \cueUseSmpteFps (see PUBLIC VOCABULARY below); \cueTime etc. use this
%%% instead of cue-format-timecode whenever Score.cueSmpteFps is set.
%%% Non-integer rates (29.97, 23.976, ...) are accepted and rounded to
%%% the nearest frame like any other rate -- this does NOT implement
%%% drop-frame timecode's skipped-frame-number convention, just frame
%%% counting at that rate. Fine for spotting-sheet cross-reference; not
%%% a substitute for real drop-frame math if that distinction matters
%%% for a specific delivery spec.
#(define (cue-format-timecode-smpte seconds fps)
   (let* ((total-frames    (inexact->exact (round (* seconds fps))))
          (frames-per-hour (round (* fps 3600)))
          (frames-per-min  (round (* fps 60)))
          (hours  (quotient total-frames frames-per-hour))
          (rem1   (remainder total-frames frames-per-hour))
          (mins   (quotient rem1 frames-per-min))
          (rem2   (remainder rem1 frames-per-min))
          (secs   (quotient rem2 (round fps)))
          (frames (remainder rem2 (round fps))))
     (format #f "~a:~a:~a:~a"
             (if (< hours 10) (format #f "0~a" hours) hours)
             (if (< mins 10) (format #f "0~a" mins) mins)
             (if (< secs 10) (format #f "0~a" secs) secs)
             (if (< frames 10) (format #f "0~a" frames) frames))))

%%% Picks decimal or SMPTE display based on whatever's active in CONTEXT.
#(define (cue-format-timecode-for context seconds)
   (let ((fps (ly:context-property context 'cueSmpteFps #f)))
     (if fps
         (cue-format-timecode-smpte seconds fps)
         (cue-format-timecode seconds))))

%%% Inverse of the above, for \cueStartTime's argument: "M:SS" or
%%% "H:MM:SS" (decimal seconds allowed in the last field).
#(define (cue-parse-timecode str)
   (let* ((parts (string-split str #\:))
          (nums  (map string->number parts)))
     (cond
       ((not (and (pair? nums) (every number? nums)))
        (ly:warning (string-append
          "project/timing.ily: \\cueStartTime could not parse " str
          " -- expected M:SS or H:MM:SS"))
        0)
       ((= (length nums) 2) (+ (* 60.0 (car nums)) (cadr nums)))
       ((= (length nums) 3) (+ (* 3600.0 (car nums)) (* 60.0 (cadr nums)) (caddr nums)))
       (else
        (ly:warning (string-append
          "project/timing.ily: \\cueStartTime could not parse " str
          " -- expected M:SS or H:MM:SS"))
        0))))


%%% ── CUE TIME EVENT ───────────────────────────────────────────────────
%%% Suffix usage: c4\cueTime d e f
%%% Placeholder text is overwritten by cueTimeEngraver below once the
%%% real elapsed time is known; it's only ever visible if the engraver
%%% somehow isn't active (\Score \consists it by default, below).

cueTime = #(make-music 'TextScriptEvent
             'text (markup #:tiny #:italic "0:00.000")
             'direction UP
             'cue-time-marker #t)

%%% \cueTotalTime -- same underlying clock as \cueTime, styled to stand
%%% out. Meant for the end of a reel's music (see the reel/cue design
%%% note above \cueStartTime's definition): it reports the time elapsed
%%% as of wherever it's attached, computed fresh rather than cached from
%%% whatever the last \cueTime happened to be -- correct even if the
%%% last note itself has no \cueTime on it.
%%%
%%% Like \cueTime, it reports the moment AT its attachment point, not
%%% that note's own end -- so to get a reel's true total INCLUDING the
%%% last note's own duration, attach it to a trailing spacer rest placed
%%% immediately after the last real note, not to the last note itself:
%%%   c4 d e f |
%%%   s4\cueTotalTime
%%% Any short duration works for the spacer (it's silent and invisible);
%%% confirmed empirically that a ZERO-duration spacer (s1*0) is the one
%%% thing that doesn't work -- it never gets acknowledged, so no grob is
%%% ever created for its \cueTotalTime to attach to, and the label
%%% silently fails to print with no warning. Use a real, if short,
%%% duration.
cueTotalTime = #(make-music 'TextScriptEvent
             'text (markup #:bold #:box #:small "Total: 0:00.000")
             'direction UP
             'cue-time-marker #t
             'cue-time-total #t)


%%% ── CUE TIMELINE (bridges to LilyPond's own TOC machinery) ──────────
%%% \cueTocEntry "1M1" "Coin" -- suffix usage, attach to a cue's first
%%% note: c4\cueTocEntry "1M1" "Coin" d e f. Prints nothing in the score
%%% (that's \cueLabel's job, from core/notation.ily -- use both together
%%% if you want the boxed mark AND a timeline entry). Instead, registers
%%% a line into a chronological cue timeline via LilyPond's own
%%% toc-init.ly machinery (add-toc-item!/toc-items -- the same functions
%%% \tocItem and \table-of-contents use, exported public and reusable),
%%% tagged with a distinct 'cueTimelineMarkup key so \cueTimeline below
%%% can pick out only these entries.
%%%
%%% This deliberately does NOT use \tocItem's own page-number machinery
%%% (built on \label + #:page-ref, resolved during page-breaking): the
%%% text here is computed and frozen during Interpreting Music, from
%%% cueTimeEngraver's own live accumulated/offset state -- the same
%%% "freeze at acknowledge-time" pattern \cueTime itself uses, and for
%%% the same reason (the value must be captured in performance order,
%%% before layout runs). If you also want PDF page numbers, add a
%%% separate plain \tocItem call and a \markuplist \table-of-contents --
%%% the two systems coexist fine since they're keyed by different
%%% 'toc-markup tags and read independently.
%%% text starts as a non-empty placeholder, not "" -- confirmed
%%% empirically that a truly empty TextScript stencil has a degenerate
%%% (+inf.0 . -inf.0) Y-extent, which trips a latent NaN bug in this
%%% project's own TextScript.Y-offset override in project/style.ily (its
%%% (pair? ext) guard doesn't catch infinite bounds). The acknowledger
%%% below marks the grob 'transparent instead of emptying its text, so
%%% the extent stays real (just invisible), sidestepping that bug rather
%%% than touching the shared house-style override.
cueTocEntry = #(define-music-function (label desc) (string? string?)
  (make-music 'TextScriptEvent
    'text (markup #:tiny "0:00.000")
    'direction UP
    'cue-toc-marker #t
    'cue-toc-text (string-append label " -- " desc)))

%%% \markuplist \cueTimeline -- place anywhere in the \book (commonly at
%%% the front, like \table-of-contents); reads whatever \cueTocEntry has
%%% registered by the time the page is actually rendered (deferred, same
%%% as \table-of-contents), regardless of \score boundaries -- confirmed
%%% empirically that toc-items() accumulates across every \score in one
%%% \book, so a single reel-level \cueTimeline can list every cue in
%%% that reel.
#(define-markup-list-command (cueTimeline layout props) ()
   (let* ((items (toc-items))
          (mine  (filter (lambda (item)
                            (eq? (assoc-get 'toc-markup (cdr item)) 'cueTimelineMarkup))
                          items)))
     (map (lambda (item) (interpret-markup layout props (assoc-get 'text (cdr item))))
          mine)))


%%% ── CUE TIME ENGRAVER ────────────────────────────────────────────────
%%% See the design note at the top of this file for why this piggybacks
%%% on TextScriptEvent's own built-in grob-creation rather than building
%%% a grob by hand.

cueTimeEngraver =
#(lambda (context)
   (let ((accumulated 0.0)
         (last-change (ly:make-moment 0))
         (tempo (ly:make-moment 15 1)))  ; quarter = 60, LilyPond's own default
     (define (flush-to now)
       (let* ((delta     (ly:moment-sub now last-change))
              (delta-sec (* 60.0 (/ (ly:moment-main delta) (ly:moment-main tempo)))))
         (set! accumulated (+ accumulated delta-sec))
         (set! last-change now)))
     (make-engraver
       (listeners
         ((tempo-change-event engraver event)
          (let* ((now   (ly:context-current-moment context))
                 (count (ly:event-property event 'metronome-count))
                 (unit  (ly:event-property event 'tempo-unit)))
            (flush-to now)
            (if (and count unit)
                (let ((avg-count (if (pair? count)
                                      (/ (+ (car count) (cdr count)) 2)
                                      count)))
                  (set! tempo (ly:moment-mul (ly:make-moment avg-count)
                                              (ly:duration-length unit))))))))
       (acknowledgers
         ((text-script-interface engraver grob source-engraver)
          (let ((cause (event-cause grob)))
            (cond
              ((and cause (ly:event-property cause 'cue-time-marker #f))
               (let* ((now    (ly:context-current-moment context))
                      (offset (ly:context-property context 'cueTimeOffset 0))
                      (total? (ly:event-property cause 'cue-time-total #f)))
                 (flush-to now)
                 (ly:grob-set-property! grob 'text
                   (if total?
                       (markup #:bold #:box #:small
                         (string-append "Total: " (cue-format-timecode-for context (+ accumulated offset))))
                       (markup #:tiny #:italic (cue-format-timecode-for context (+ accumulated offset)))))))
              ((and cause (ly:event-property cause 'cue-toc-marker #f))
               (let* ((now    (ly:context-current-moment context))
                      (offset (ly:context-property context 'cueTimeOffset 0))
                      (label  (ly:event-property cause 'cue-toc-text "")))
                 (flush-to now)
                 (ly:grob-set-property! grob 'transparent #t)
                 (add-toc-item! 'cueTimelineMarkup
                   (markup (string-append label " -- "
                             (cue-format-timecode-for context (+ accumulated offset))))))))))))))

\layout {
  \context {
    \Score
    \consists \cueTimeEngraver
    cueTimeOffset = #0
    cueSmpteFps = ##f
  }
}


%%% ── PUBLIC VOCABULARY ────────────────────────────────────────────────

%%% \cueUseSmpteFps 24 -- switches \cueTime/\cueTotalTime/\cueTocEntry
%%% display to HH:MM:SS:FF SMPTE timecode at the given frame rate, for
%%% the rest of this \score (or until called again with a different
%%% rate, or with ##f to switch back to decimal M:SS.mmm). Common rates:
%%% 24, 25, 30, 29.97, 23.976. See the SMPTE note above
%%% cue-format-timecode-smpte for what this does and doesn't handle
%%% (no drop-frame skipped-number convention).
cueUseSmpteFps = #(define-music-function (fps) ((lambda (x) (or (not x) (number? x))))
  #{
    \set Score.cueSmpteFps = #fps
  #})

%%% \cueStartTime "3:12.5" -- sets this cue's absolute movie-timecode
%%% offset. Place at the very start of the cue's music, before any notes.
cueStartTime = #(define-music-function (timecode) (string?)
  #{
    \set Score.cueTimeOffset = #(cue-parse-timecode timecode)
  #})


%%% ── CUE GAP (delayed cue start, computed silence) ───────────────────
%%% \cueGapTo "reelStart" "target" \precedingMusic -- inserts exactly the
%%% right amount of rest so that the NEXT note after it lands at the
%%% absolute movie timecode "target", given that \precedingMusic is
%%% everything already written since "reelStart" (this reel's own
%%% \cueStartTime argument, passed again here). Real use case: a movie
%%% has a dialogue-only scene between two cues, and the next cue needs to
%%% start at a specific, known later timecode -- this computes the
%%% silence instead of the composer hand-counting measures.
%%%
%%% Usage (mirrors a real reel's own track-concatenation style):
%%%   partA = { \tempo 4 = 60 c4 d e f | g4 a b c' | }
%%%   partB = { d4 e f g | }
%%%   track = { \partA \cueGapTo "0:00" "1:15.0" \partA \partB }
%%%
%%% DESIGN -- why this can't reuse cueTimeEngraver's live state:
%%% \cueTime/\cueTocEntry work by freezing a value that's already
%%% flowing forward -- they read cueTimeEngraver's accumulated/offset
%%% state at acknowledge-time and stamp it onto a grob after the fact.
%%% A gap is the opposite: it needs to CONSTRUCT a rest of the right
%%% LENGTH, and that length has to be fixed before interpretation even
%%% starts (parsing determines every note's duration; nothing can go
%%% back and resize a rest once the score is being interpreted). So this
%%% cannot be engraver-based at all -- it has to know "how much real time
%%% has \precedingMusic already used" from the raw, not-yet-interpreted
%%% Music tree itself, using ly:music-length and a Scheme-level walk
%%% (this is "Approach B" from the original timing.ily research -- a
%%% pure tree-walk, no engraver -- which was set aside for \cueTime
%%% itself because of exactly the repeat/tempo-order fragility below, but
%%% is the ONLY correct approach for this direction of the problem).
%%%
%%% The walker (cue-gap-elapsed-seconds) handles: SequentialMusic
%%% (elements in order), SimultaneousMusic (takes the longest branch --
%%% correct for total duration; which branch's tempo history "wins" for
%%% an eventual tempo change is ambiguous in general, and not something
%%% real cue-writing should rely on: mark tempo in one place per reel, as
%%% documented up top), a bare TempoChangeEvent (found directly, not
%%% inside an EventChord -- confirmed empirically that a standalone
%%% \tempo's event sits bare in the tree, not wrapped, unlike a genuine
%%% chord's simultaneous post-events), and single-child wrapper nodes
%%% (ContextSpeccedMusic, RelativeOctaveMusic, UnfoldedRepeatedMusic,
%%% etc.) via a generic 'element recursion. \repeat unfold is handled
%%% correctly, INCLUDING a tempo change inside the repeated body: unfold
%%% is a literal duplication (confirmed in the QC pass above), so every
%%% repetition has an identical internal tempo profile, which makes
%%% "walk one copy, multiply by the wrapper/inner length ratio" exact --
%%% verified against a hand-checked case (2 repeats, tempo 60 -> 120
%%% inside each) before trusting it.
%%%
%%% Exact arithmetic throughout (cue-gap-parse-exact-number,
%%% cue-gap-parse-exact-timecode): deliberately NOT reusing
%%% cue-parse-timecode, which returns an inexact (float) number of
%%% seconds -- fine for a value that only ever gets rounded for display,
%%% but wrong here, where the result becomes a REST LENGTH. Converting a
%%% lossy float back to an exact rational (inexact->exact) can produce an
%%% ugly huge-denominator fraction for anything not exactly representable
%%% in binary (e.g. most decimal thousandths), since IEEE floats don't
%%% store decimal fractions exactly. cue-gap-parse-exact-number instead
%%% parses the decimal STRING directly into a clean exact rational
%%% (12.345 -> exactly 2469/200, from the digits, not from a float).
%%%
%%% REAL LILYPOND BUG FOUND while building this (2.24.3, confirmed
%%% reproducible in isolation, unrelated to any of this project's own
%%% code): a multi-measure rest (R) with a NON-INTEGER multiplier --
%%% e.g. R1*7/2 -- doesn't just look odd, it triggers genuine internal
%%% failures: "programming error: Multi measure rest seems misplaced"
%%% and "programming error: Trying to interpret a non-markup object: ()"
%%% (the rest-count number's markup-generation code appears to assume a
%%% whole number of measures and produces garbage otherwise). Separately
%%% (not a bug, but a real gotcha that cost real debugging time here):
%%% \compressMMRests is a MUSIC FUNCTION that wraps exactly one following
%%% music argument (\compressMMRests { ... your rest ... }) -- it is NOT
%%% a \set-like mode switch. Writing it as a bare statement earlier in a
%%% sequence (\compressMMRests \n noteA noteB R1*3) silently only wraps
%%% noteA (the very next token) and does nothing for the rest three notes
%%% later, with no warning that anything was missed.
%%%
%%% Because of the real bug, the visible portion of the gap is ALWAYS a
%%% whole-measure R (safe, integer multiplier, correctly compressed via
%%% \compressMMRests wrapping the whole constructed passage) with any
%%% leftover fraction absorbed by a trailing INVISIBLE \skip (exact,
%%% never rendered, so it can never trip the fractional-R bug above).
%%% This assumes \time 4/4 for the visible measure count to mean anything
%%% (1 whole note = 1 measure) -- true everywhere in this project's
%%% existing cues; a different time signature would still get the
%%% correct TOTAL silence (the invisible \skip doesn't care), just not a
%%% visually meaningful "N measures" count.
%%%
%%% SAFETY: if \precedingMusic already reaches past "target" (the
%%% previous cue ran long, or the target was mistyped), this warns
%%% clearly and returns a zero-length gap rather than attempting a
%%% negative rest -- confirmed empirically that this path compiles clean
%%% and simply continues immediately, exactly as if \cueGapTo had not
%%% been called, so a mistake here is loud (a warning) rather than a
%%% silently wrong score.
%%%
%%% MULTI-STAFF USE: call \cueGapTo once per staff, each with THAT
%%% staff's own \precedingMusic -- do not assume one call somehow covers
%%% a whole StaffGroup. Confirmed empirically with a two-staff reel
%%% simulation (matching this project's real StaffGroup shape) that
%%% calling it symmetrically in each staff, with each staff's own
%%% preceding track, produces perfectly synchronized gaps (same measure
%%% count, same resulting \cueTime on the far side in both staves) --
%%% consistent with how LilyPond requires simultaneous staves to agree on
%%% duration at every barline anyway.

#(define (cue-gap-parse-exact-number str)
   (let* ((negative? (and (> (string-length str) 0) (char=? (string-ref str 0) #\-)))
          (str       (if negative? (substring str 1) str))
          (dot       (string-index str #\.)))
     (let* ((int-str   (if dot (substring str 0 dot) str))
            (frac-str  (if dot (substring str (1+ dot)) ""))
            (int-part  (if (= (string-length int-str) 0) 0 (string->number int-str)))
            (frac-len  (string-length frac-str))
            (frac-part (if (= frac-len 0) 0 (string->number frac-str))))
       (if (or (not int-part) (not frac-part))
           #f
           (let ((magnitude (+ int-part (/ frac-part (expt 10 frac-len)))))
             (if negative? (- magnitude) magnitude))))))

#(define (cue-gap-parse-exact-timecode str)
   (let* ((parts (string-split str #\:))
          (nums  (map cue-gap-parse-exact-number parts)))
     (if (not (and (pair? nums) (every number? nums)))
         (begin (ly:warning (string-append "cueGapTo: could not parse " str)) 0)
         (case (length nums)
           ((2) (+ (* 60 (car nums)) (cadr nums)))
           ((3) (+ (* 3600 (car nums)) (* 60 (cadr nums)) (caddr nums)))
           (else (ly:warning (string-append "cueGapTo: could not parse " str)) 0)))))

#(define (cue-gap-tempo-from-event evt)
   (let ((count (ly:music-property evt 'metronome-count))
         (unit  (ly:music-property evt 'tempo-unit)))
     (cond
       ((not (ly:duration? unit)) #f)
       ((number? count) (ly:moment-mul (ly:make-moment count) (ly:duration-length unit)))
       ((pair? count) (ly:moment-mul (ly:make-moment (/ (+ (car count) (cdr count)) 2))
                                      (ly:duration-length unit)))
       (else #f))))

%%% Returns (elapsed-exact-seconds . final-tempo-moment) for MUSIC,
%%% walked statically (parse-time, not the live score -- see design note
%%% above). start-tempo is a ly:moment (wholes-per-minute), matching
%%% cueTimeEngraver's own default when no \tempo has been seen yet.
#(define (cue-gap-elapsed-seconds music start-tempo)
   (define (walk m tempo)
     (let ((name (ly:music-property m 'name)))
       (cond
         ((eq? name 'TempoChangeEvent)
          (cons 0 (or (cue-gap-tempo-from-event m) tempo)))
         ((eq? name 'SequentialMusic)
          (fold (lambda (elt acc)
                  (let ((r (walk elt (cdr acc))))
                    (cons (+ (car acc) (car r)) (cdr r))))
                (cons 0 tempo)
                (ly:music-property m 'elements)))
         ((eq? name 'SimultaneousMusic)
          (let ((results (map (lambda (elt) (walk elt tempo)) (ly:music-property m 'elements))))
            (if (null? results)
                (cons 0 tempo)
                (cons (apply max (map car results)) (cdr (car results))))))
         ((pair? (ly:music-property m 'elements '()))
          (let* ((tempo-evt (find (lambda (e) (eq? (ly:music-property e 'name) 'TempoChangeEvent))
                                   (ly:music-property m 'elements)))
                 (new-tempo (if tempo-evt (or (cue-gap-tempo-from-event tempo-evt) tempo) tempo))
                 (len (ly:moment-main (ly:music-length m))))
            (cons (* 60 (/ len (ly:moment-main tempo))) new-tempo)))
         ((ly:music-property m 'element #f)
          => (lambda (child)
               (let* ((inner (walk child tempo))
                      (wrapper-len (ly:moment-main (ly:music-length m)))
                      (inner-len   (ly:moment-main (ly:music-length child))))
                 (if (or (= inner-len 0) (= wrapper-len inner-len))
                     inner
                     (cons (* (car inner) (/ wrapper-len inner-len)) (cdr inner))))))
         (else
          (let ((len (ly:moment-main (ly:music-length m))))
            (cons (* 60 (/ len (ly:moment-main tempo))) tempo))))))
   (walk music start-tempo))

cueGapTo = #(define-music-function (reel-start target preceding) (string? string? ly:music?)
  (let* ((offset   (cue-gap-parse-exact-timecode reel-start))
         (target-s (cue-gap-parse-exact-timecode target))
         (result   (cue-gap-elapsed-seconds preceding (ly:make-moment 15)))
         (elapsed  (car result))
         (tempo    (cdr result))
         (gap-sec  (- target-s offset elapsed)))
    (if (< gap-sec 0)
        (begin
          (ly:warning (string-append "cueGapTo: target " target
            " is EARLIER than the music already written (already at "
            (number->string (exact->inexact (+ offset elapsed))) "s past reel start "
            reel-start ") -- returning a zero-length gap instead of a negative rest"))
          #{ \skip 1*0 #})
        (let* ((gap-wholes     (/ (* gap-sec (ly:moment-main tempo)) 60))
               (whole-measures (inexact->exact (floor gap-wholes)))
               (remainder      (- gap-wholes whole-measures)))
          #{
            \compressMMRests { R1*#whole-measures }
            \skip #(ly:make-duration 0 0 remainder)
          #}))))


%%% ── CUE TEMPO FIT (tempo needed for a passage to fit a target length) ──
%%% \cueTempoTo unit "start" "target" \music -- prints a \tempo mark
%%% (metronome count in note-value "unit", e.g. 4 for a quarter note, 4.
%%% for a dotted quarter) immediately before \music, computed so that
%%% \music takes exactly (target - start) seconds. The inverse of
%%% \cueGapTo: that one solves for how much SILENCE to insert given a
%%% fixed tempo and a fixed target; this solves for the TEMPO given a
%%% fixed, already-written passage and a fixed target duration -- the
%%% real use case is a passage that has to land precisely inside a
%%% fixed-length window (a scene, an action beat) regardless of what
%%% tempo that turns out to require.
%%%
%%% Usage:
%%%   partA = { c4 d e f | g4 a b c' | }   % 8 quarter notes, no \tempo
%%%   track = { \cueTempoTo 4 "0:00" "0:10" \partA }
%%%   %% prints "\tempo 4 = 48" before partA's music (8 quarters in 10s
%%%   %% = 48bpm), so partA plays out in exactly 10 real seconds.
%%%
%%% DESIGN -- why this only needs \music's notated length, not a
%%% tempo-aware tree-walk like \cueGapTo's: the target tempo is being
%%% SOLVED FOR, so \music's own written duration (ly:music-length --
%%% purely note values, independent of tempo) is exactly the "how many
%%% beats" side of the equation; no walk of embedded \tempo events is
%%% needed to get there (unlike \cueGapTo, which walks tempo history
%%% because it's computing a real elapsed time from an ALREADY-fixed
%%% tempo). This also means grace notes, tuplets, and \repeat unfold
%%% behave the same way here as everywhere else in this file --
%%% ly:music-length already reflects their real notated duration, for
%%% free.
%%%
%%% Rounding: metronome marks are conventionally whole numbers, so the
%%% exact solved-for count is rounded to the nearest integer. That
%%% rounding is real drift (a passage this short can round to a
%%% noticeably different actual duration than the target) -- rather than
%%% hide it, this prints an informational ly:message reporting the
%%% target vs. the actual duration at the rounded tempo whenever they
%%% differ by more than 20ms, the same "surface it, don't absorb it"
%%% approach \cueGapTo's own warning takes for a mistimed target.
%%%
%%% SAFETY: if \music already contains its own numeric \tempo change(s)
%%% (e.g. copy-pasted from a cue that had one), the mark this prints will
%%% be overridden partway through by the pre-existing one, silently
%%% breaking the "whole passage takes exactly this long" guarantee past
%%% that point -- this is exactly the kind of mismatch this library warns
%%% about loudly elsewhere, so it warns here too rather than proceeding
%%% quietly. A target at or before the start (or a zero-length \music)
%%% can't be solved at all -- warns and returns \music unmodified, same
%%% failure shape as \cueGapTo's own negative-gap case.
%%%
%%% MULTI-STAFF USE: as with \cueGapTo, this is for the single passage
%%% it's given -- if the same tempo needs to apply across a whole
%%% StaffGroup, mark it once in one staff (LilyPond's own tempo-per-Score
%%% behavior already makes a single \tempo visible/used everywhere, same
%%% as any other \tempo call in this project).

#(define (cue-tempo-has-numeric-tempo-change? music)
   (or (and (eq? (ly:music-property music 'name) 'TempoChangeEvent)
            (cue-gap-tempo-from-event music)
            #t)
       (let ((elts (ly:music-property music 'elements '())))
         (and (pair? elts) (any cue-tempo-has-numeric-tempo-change? elts) #t))
       (let ((elt (ly:music-property music 'element #f)))
         (and elt (cue-tempo-has-numeric-tempo-change? elt) #t))))

cueTempoTo = #(define-music-function (unit start target music)
               (ly:duration? string? string? ly:music?)
  (let* ((start-s   (cue-gap-parse-exact-timecode start))
         (target-s  (cue-gap-parse-exact-timecode target))
         (duration  (- target-s start-s))
         (wholes    (ly:moment-main (ly:music-length music))))
    (cond
      ((<= duration 0)
       (ly:warning (string-append "cueTempoTo: target " target
         " is not after start " start
         " -- cannot compute a tempo, returning music unmodified"))
       music)
      ((= wholes 0)
       (ly:warning (string-append "cueTempoTo: \\music has zero length"
         " -- cannot compute a tempo, returning music unmodified"))
       music)
      (else
       (if (cue-tempo-has-numeric-tempo-change? music)
           (ly:warning (string-append "cueTempoTo: \\music already contains"
             " its own \\tempo change(s) -- the mark computed here will be"
             " overridden partway through, so the passage will NOT"
             " uniformly take the target duration past that point")))
       (let* ((unit-wholes (ly:moment-main (ly:duration-length unit)))
              (exact-count (/ (* wholes 60) duration unit-wholes))
              (count       (inexact->exact (round exact-count)))
              (actual-sec  (exact->inexact (/ (* wholes 60) (* count unit-wholes))))
              (target-sec  (exact->inexact duration))
              (drift       (abs (- actual-sec target-sec))))
         (if (> drift 0.02)
             (ly:message (string-append "cueTempoTo: rounded to "
               (number->string count) " -- actual duration "
               (format #f "~,3f" actual-sec) "s vs. target "
               (format #f "~,3f" target-sec) "s (drift "
               (format #f "~,3f" drift) "s)")))
         #{ \tempo $unit = #count $music #})))))
