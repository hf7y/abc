%%% lib/core/strings.ily
%%% String-instrument notation library: contact articulations, a
%%% transposing scordatura system, and string-number coloring.
%%%
%%% DEPENDENCIES: noteheads.ily must be loaded before this file (provides
%%% square-head-stencil). Loaded automatically via core/includes.ily.
%%%
%%% CONTENTS:
%%%   Contact articulations   \squareHead \halfHarmonic \air — suffix
%%%                            articulations, StringStaff-scoped, with
%%%                            chord-member independence
%%%                            (<c\squareHead g\halfHarmonic>). Legacy
%%%                            prefix aliases \square \half-harmonic are
%%%                            also still defined (see design note).
%%%   Scordatura system       \withScordatura #'instrument { tuning } { music }
%%%                            \set Staff.scordaturaMode = #'sounding / #'fingered
%%%                            \unscordatura
%%%   String color system     \withStringColors { music }
%%%                            \withStringColorsInferred { music }
%%%                            \set Staff.stringColorList = #(list (cons 1 red) ...)
%%%   StringStaff context     \new StringStaff { ... } — everything above
%%%                            is scoped here (\alias Staff, so all normal
%%%                            Staff behavior works).
%%%
%%% DESIGN NOTE — suffix contact articulations, and a correction:
%%% An earlier draft of this file concluded that suffix articulations
%%% with chord-member independence were not achievable in LilyPond
%%% 2.24.3, based on two failed approaches: (1) registering a brand-new
%%% Music event class from Scheme, which the postfix-combination step
%%% doesn't recognize ("Not a music type" — LilyPond's post-event class
%%% hierarchy is fixed at build time); (2) piggybacking on the existing
%%% ArticulationEvent class, which works but was abandoned because it
%%% triggered the built-in Script engraver to also try to interpret the
%%% same event, spamming "do not know how to interpret articulation" /
%%% "script-stencil property must be pair" warnings on every use.
%%%
%%% That second approach was abandoned one step too early. The Script
%%% engraver reads its interpretation table from the scriptDefinitions
%%% context property (defaults to default-script-alist, scm/lily/script.scm).
%%% Extending that alist with entries for our articulation types — giving
%%% each a 'stencil of (lambda (grob) empty-stencil) so the Script grob
%%% it creates renders nothing — silences the warnings entirely, without
%%% touching Script.stencil globally (which would also hide real
%%% accents/bowings/etc.).
%%%
%%% A second, separate bug surfaced after that fix, from trusting a
%%% too-convenient-looking visual check: chords rendered correctly, and
%%% bare (non-chord) *quarter* notes appeared to as well — but only
%%% because our filled-box override and a default filled quarter
%%% notehead look nearly identical at a glance. They were not actually
%%% using the same code path. Testing with whole notes (open, visually
%%% distinct shapes) instead exposed that bare-note contact
%%% articulations did nothing at all. Root cause, confirmed via
%%% \displayMusic and an instrumented engraver: LilyPond folds a chord
%%% member's articulation into that specific NoteEvent's own
%%% 'articulations, but for a bare note the articulation instead
%%% broadcasts as its own independent event and is absent from the
%%% note's cause — two different delivery mechanisms depending on
%%% syntax. contactNoteheadsEngraver below handles both (see its own
%%% comment for the detection logic). Verified clean end-to-end with
%%% both bare whole notes and chords, and confirmed staccato/accent/
%%% upbow/dynamics still render normally alongside these articulations
%%% in the same Voice.
%%%
%%% USAGE EXAMPLES:
%%%
%%%   Contact articulations (suffix, StringStaff-scoped):
%%%     \new StringStaff {
%%%       c,1\halfHarmonic
%%%       d1\squareHead
%%%       <c\squareHead g\halfHarmonic e>1   % independent per chord member
%%%     }
%%%
%%%   Scordatura with highlighting:
%%%     \new StringStaff {
%%%       \clef bass
%%%       \set Staff.scordaturaMode  = #'sounding
%%%       \set Staff.stringColorList = #strings-highlight-4
%%%       \withScordatura #'cello { a, d, g, des, } {
%%%         \withStringColors {
%%%           c,1\4\squareHead
%%%         }
%%%       }
%%%     }
%%%
%%% ADDING INSTRUMENTS: extend scord-instrument-tunings below. The
%%% instrument must have a LilyPond built-in tuning variable (see
%%% ly/string-tunings-init.ly) or a custom list of ly:pitch objects.

\version "2.24.0"

#(ly:message "core/strings.ily loaded")


%%% ── SHARED HELPERS ───────────────────────────────────────────────────
%%% Pitch arithmetic and string assignment. Used by both the scordatura
%%% and string-color systems.

#(define str-chromatic-steps #(0 2 4 5 7 9 11))

#(define (str-pitch->semitones p)
   (+ (* 12 (ly:pitch-octave p))
      (vector-ref str-chromatic-steps (ly:pitch-notename p))
      (inexact->exact (round (* 2 (ly:pitch-alteration p))))))

%%% Display name for a pitch, for warning messages only.
#(define (str-pitch->name p)
   (let* ((names '#("C" "D" "E" "F" "G" "A" "B"))
          (name  (vector-ref names (ly:pitch-notename p)))
          (alt   (ly:pitch-alteration p)))
     (string-append name
       (cond ((= alt  1/2) "#")
             ((= alt -1/2) "b")
             ((= alt  1)   "##")
             ((= alt -1)   "bb")
             (else          "")))))

%%% Lowest-fret string assignment heuristic (mirrors the tab engine's
%%% logic in portable Scheme rather than depending on its C++ API).
%%% tuning: list of ly:pitch, string 1 first (highest).
%%% Returns 1-based string number, or #f if pitch not reachable.
#(define (str-lowest-fret-string pitch tuning)
   (let* ((pitch-st  (str-pitch->semitones pitch))
          (frets     (map (lambda (p) (- pitch-st (str-pitch->semitones p)))
                           tuning))
          (candidates (filter-map
                        (lambda (fret idx) (if (>= fret 0) (cons fret (+ idx 1)) #f))
                        frets
                        (iota (length tuning)))))
     (if (null? candidates)
         #f
         (cdr (car (sort candidates (lambda (a b) (< (car a) (car b)))))))))

%%% Extract ordered pitch list from sequential music { a, d, g, des, }
#(define (str-music->pitches music)
   (filter ly:pitch?
     (map (lambda (ev) (ly:music-property ev 'pitch))
          (ly:music-property music 'elements))))

%%% An explicit \N string number (e.g. c,1\4) is its own StringNumberEvent
%%% living in the note's articulations list -- it is NOT a 'string-number
%%% property on the note event itself. (Verified empirically: reading
%%% 'string-number directly off the cause event always returns #f; an
%%% earlier draft of this file had exactly that bug, which silently
%%% disabled every explicit-string-number code path -- string coloring
%%% by explicit number never colored anything, though inference and
%%% scordatura's own use of \N both happened to still work by falling
%%% through to the pitch-based heuristic instead.)
%%% Returns the 1-based string number, or #f if the cause has no
%%% explicit string number.
#(define (str-explicit-string-number cause)
   (if cause
       (let* ((arts (ly:event-property cause 'articulations))
              (str-events (filter
                            (lambda (a) (ly:in-event-class? a 'string-number-event))
                            arts)))
         (if (pair? str-events)
             (ly:event-property (car str-events) 'string-number)
             #f))
       #f))


%%% ── STANDARD INSTRUMENT TUNINGS ─────────────────────────────────────
%%% Maps instrument symbols to LilyPond's own built-in tuning variables
%%% (violin-tuning, viola-tuning, cello-tuning, bass-tuning — defined in
%%% ly/string-tunings-init.ly). Deliberately not reimplemented here: the
%%% built-ins are the authoritative source and stay correct if LilyPond
%%% ever revises them.

#(define scord-instrument-tunings
   `((violin . ,violin-tuning)
     (viola  . ,viola-tuning)
     (cello  . ,cello-tuning)
     (bass   . ,bass-tuning)))


%%% ── DEFAULT STRING COLOR SCHEMES ────────────────────────────────────
%%% Ready-made schemes for common scordatura/string-highlighting needs.

#(define strings-all-black
   (list (cons 1 black) (cons 2 black) (cons 3 black) (cons 4 black)))

#(define strings-highlight-1
   (list (cons 1 red) (cons 2 black) (cons 3 black) (cons 4 black)))

#(define strings-highlight-2
   (list (cons 1 black) (cons 2 red) (cons 3 black) (cons 4 black)))

#(define strings-highlight-3
   (list (cons 1 black) (cons 2 black) (cons 3 red) (cons 4 black)))

#(define strings-highlight-4
   (list (cons 1 black) (cons 2 black) (cons 3 black) (cons 4 red)))

#(define strings-highlight-1-4
   (list (cons 1 red) (cons 2 black) (cons 3 black) (cons 4 red)))

#(define strings-highlight-all
   (list (cons 1 red) (cons 2 red) (cons 3 red) (cons 4 red)))

#(define strings-rainbow
   (list (cons 1 black)
         (cons 2 (x11-color 'RoyalBlue))
         (cons 3 (x11-color 'ForestGreen))
         (cons 4 (x11-color 'DarkOrchid))))


%%% ── CONTEXT PROPERTY REGISTRATION ──────────────────────────────────
%%% scordaturaTuning is deliberately NOT named stringTuning/stringTunings
%%% — those names are already used by LilyPond's own tablature machinery
%%% (\stringTuning is a built-in chord-to-tuning conversion function;
%%% stringTunings is TabStaff's own context property). Reusing either
%%% name risks confusing readers even though no runtime collision was
%%% found in testing.

#(set-object-property! 'scordaturaMode      'translation-type? symbol?)
#(set-object-property! 'scordaturaMode      'translation-doc
   "Scordatura display mode: fingered (written pitch, default) or sounding")
#(set-object-property! 'scordaturaActive    'translation-type? boolean?)
#(set-object-property! 'scordaturaActive    'translation-doc
   "Gate flag: #t inside \\withScordatura block")
#(set-object-property! 'scordaturaBaseTuning 'translation-type? list?)
#(set-object-property! 'scordaturaBaseTuning 'translation-doc
   "Standard tuning snapshot for interval calculation")
#(set-object-property! 'scordaturaTuning    'translation-type? list?)
#(set-object-property! 'scordaturaTuning    'translation-doc
   "Active scordatura tuning: string 1 first")
#(set-object-property! 'stringColorsActive  'translation-type? boolean?)
#(set-object-property! 'stringColorsActive  'translation-doc
   "Gate flag: #t to activate string-color rendering")
#(set-object-property! 'stringColorsInfer   'translation-type? boolean?)
#(set-object-property! 'stringColorsInfer   'translation-doc
   "Set #t to infer string numbers via the lowest-fret heuristic")
#(set-object-property! 'stringColorList     'translation-type? list?)
#(set-object-property! 'stringColorList     'translation-doc
   "Alist of (string-number . color) pairs")


%%% ── SCORDATURA ENGRAVER ─────────────────────────────────────────────
%%% Installed in StringStaff (Staff-scoped). For each NoteHead:
%%%   1. Only act if scordaturaActive and mode is 'sounding.
%%%   2. Resolve string number: explicit \N wins, else lowest-fret
%%%      heuristic against the snapshot of the standard tuning.
%%%   3. Compute the transposition interval for that string and
%%%      transpose the pitch.
%%%   4. Set the grob's staff-position AND rewrite the cause event's
%%%      'pitch to the sounding pitch.
%%%
%%% Verified empirically (2.24.3) that step 4 alone is sufficient for
%%% Accidental_engraver to render the *sounding* pitch's accidental
%%% correctly — including same-measure accidental suppression on a
%%% repeated sounding pitch and sharp-cancelled-to-natural cases — with
%%% no special \consists reordering needed. (An earlier hypothesis that
%%% Accidental_engraver's acknowledger would need to be forced to run
%%% after ours, since it's added earlier in Staff's default \consists
%%% list, turned out not to matter: Accidental_engraver evidently defers
%%% its real decision past the immediate acknowledger call, by which
%%% point our mutation has already landed.)

#(define scordaturaEngraver
   (make-engraver
     (acknowledgers
       ((note-head-interface engraver grob source-engraver)
        (let* ((context (ly:translator-context engraver))
               (active  (ly:context-property context 'scordaturaActive #f))
               (mode    (ly:context-property context 'scordaturaMode 'fingered)))
          (if (and active (eq? mode 'sounding))
              (let* ((scord-tuning (ly:context-property context 'scordaturaTuning #f))
                     (base-tuning  (ly:context-property context 'scordaturaBaseTuning #f))
                     (cause        (event-cause grob))
                     (pitch        (if cause (ly:event-property cause 'pitch) #f))
                     (explicit-str (str-explicit-string-number cause))
                     (str-num      (if (and (integer? explicit-str) (> explicit-str 0))
                                       explicit-str
                                       (if (and pitch (pair? base-tuning))
                                           (str-lowest-fret-string pitch base-tuning)
                                           #f))))
                (if (and pitch str-num
                         (pair? scord-tuning) (pair? base-tuning)
                         (<= str-num (length scord-tuning))
                         (<= str-num (length base-tuning)))
                    (let* ((std-p    (list-ref base-tuning  (- str-num 1)))
                           (new-p    (list-ref scord-tuning (- str-num 1)))
                           (interval (ly:pitch-diff new-p std-p))
                           (sounding (ly:pitch-transpose pitch interval))
                           (mid-c    (ly:context-property context 'middleCPosition 0))
                           (new-pos  (+ mid-c
                                        (* 7 (ly:pitch-octave sounding))
                                        (ly:pitch-notename sounding))))
                      (ly:grob-set-property! grob 'staff-position new-pos)
                      (if cause
                          (ly:event-set-property! cause 'pitch sounding)))
                    ;; pitch and base-tuning both present but str-num came
                    ;; back #f: the written pitch isn't reachable on any
                    ;; string of the standard tuning (e.g. below the
                    ;; lowest open string). Without this, the note simply
                    ;; renders unsounded/untransposed with no explanation --
                    ;; confirmed by testing a pitch below cello's low C.
                    (if (and pitch (not str-num) (pair? base-tuning))
                        (ly:warning (string-append
                          "strings.ily: written pitch " (str-pitch->name pitch)
                          " is not reachable on any string of the standard"
                          " tuning -- scordatura transposition skipped for"
                          " this note. Use an explicit \\N if the pitch is"
                          " reachable on a specific string only under"
                          " scordatura.")))))))))))


%%% ── STRING COLORS ENGRAVER ──────────────────────────────────────────
%%% Reads stringColorsActive, stringColorsInfer, stringColorList,
%%% scordaturaTuning. Sets NoteHead color by string number. Explicit
%%% \N string numbers are always honored; heuristic inference against
%%% scordaturaTuning only applies when stringColorsInfer is #t (off by
%%% default — a speculative string assignment shouldn't be colored with
%%% the same confidence as an explicit one).

#(define stringColorsEngraver
   (make-engraver
     (acknowledgers
       ((note-head-interface engraver grob source-engraver)
        (let* ((context (ly:translator-context engraver))
               (active  (ly:context-property context 'stringColorsActive #f)))
          (if active
              (let* ((colors      (ly:context-property context
                                    'stringColorList strings-rainbow))
                     (infer       (ly:context-property context 'stringColorsInfer #f))
                     (tuning      (ly:context-property context 'scordaturaTuning #f))
                     (cause       (event-cause grob))
                     (pitch       (if cause (ly:event-property cause 'pitch) #f))
                     (explicit-str (str-explicit-string-number cause))
                     (str-num     (cond
                                    ((and (integer? explicit-str) (> explicit-str 0))
                                     explicit-str)
                                    ((and infer pitch (pair? tuning))
                                     (str-lowest-fret-string pitch tuning))
                                    (else #f))))
                (if str-num
                    (let ((color (assoc-get str-num colors #f)))
                      (if color
                          (ly:grob-set-property! grob 'color color)))))))))))


%%% ── CONTACT ARTICULATION EVENTS ──────────────────────────────────────
%%% Suffix articulations, built on the existing ArticulationEvent class
%%% (see design note at the top of this file for why, and why this is
%%% clean rather than a hack). Priority when more than one is present on
%%% the same note (shouldn't normally happen, but mutually exclusive by
%%% convention): air > squareHead > halfHarmonic > default.

squareHead   = #(make-music 'ArticulationEvent 'articulation-type 'squareHead)
halfHarmonic = #(make-music 'ArticulationEvent 'articulation-type 'halfHarmonic)
air          = #(make-music 'ArticulationEvent 'articulation-type 'air)

#(define (str-has-articulation? arts type)
   (pair? (filter (lambda (a)
                     (and (ly:in-event-class? a 'articulation-event)
                          (eq? (ly:event-property a 'articulation-type) type)))
                   arts)))

%%% Silences the built-in Script engraver for just these three types
%%% (giving each an explicit empty stencil) without touching
%%% Script.stencil globally — real articulations (accents, bowings,
%%% staccato, ...) keep rendering normally in the same Voice.
#(define (str-no-script-stencil grob) empty-stencil)

%%% avoid-slur: 'ignore tells the slur engraver not to route around this
%%% grob at all. Without it, an invisible (empty-stencil) Script grob
%%% still participates in slur-avoidance layout and the slur engraver
%%% warns "Ignoring grob for slur: Script. avoid-slur not set?" the
%%% first time it meets one — harmless visually (the warning describes
%%% its own recovery), but a real latent rough edge worth closing since
%%% ties/slurs across a contact-articulated note are ordinary usage.
#(define contactScriptDefinitions
   (append
     `((squareHead   . ((stencil . ,str-no-script-stencil) (direction . ,UP) (avoid-slur . ignore)))
       (halfHarmonic . ((stencil . ,str-no-script-stencil) (direction . ,UP) (avoid-slur . ignore)))
       (air          . ((stencil . ,str-no-script-stencil) (direction . ,UP) (avoid-slur . ignore))))
     default-script-alist))

%%% Installed in StringStaff. Sets the NoteHead's own stencil/style —
%%% the Script grob created alongside (see above) is invisible.
%%%
%%% Two-mechanism detection, verified empirically against 2.24.3 via
%%% \displayMusic and instrumented engravers — this is not incidental
%%% complexity, it reflects a genuine LilyPond asymmetry:
%%%
%%%   - A chord member's articulation (<c\squareHead g>) is folded into
%%%     that specific NoteEvent's own 'articulations, and does NOT
%%%     broadcast as an independent event. Caught by the acknowledger
%%%     inspecting the NoteHead grob's cause.
%%%   - A bare note's articulation (c\squareHead, no chord brackets) is
%%%     the reverse: it broadcasts as its own independent
%%%     'articulation-event at the same timestep, and is ABSENT from the
%%%     note's own cause. Caught by the listener below, staged in
%%%     `pending` and consumed by the very next note-head acknowledgment
%%%     in the same timestep, then cleared.
%%%
%%% An earlier version of this engraver only implemented the first
%%% mechanism. It looked correct — chords rendered fine, and *quarter*
%%% notes appeared to work too, but only because a plain filled quarter
%%% notehead and our filled-box override are nearly indistinguishable at
%%% a glance. Whole/half notes (visually distinct open shapes) exposed
%%% that bare-note contact articulations were silently doing nothing.
%%% Lesson: verify with a duration whose override is visually distinct
%%% from the default, not just whichever duration is at hand.
%%%
%%% The `pending` staging assumes at most one contact-articulated bare
%%% note per timestep per *Voice*. Multiple simultaneous Voices are fine
%%% because this engraver is installed on StringVoice (below), not
%%% StringStaff — each Voice instance gets its own independent `pending`
%%% closure. It was originally installed on StringStaff directly, which
%%% failed exactly this case: confirmed empirically that two Voices with
%%% different bare contact articulations at the same timestep both
%%% resolved to whichever type had higher priority, because they shared
%%% one pending queue. If you ever see two contact-marked notes in
%%% different Voices resolve to the same shape when they shouldn't,
%%% check that this engraver is still Voice-scoped, not Staff-scoped —
%%% see test-suite.ly score 2e, which exists specifically to catch a
%%% regression back to Staff-scoping.
contactNoteheadsEngraver =
#(lambda (context)
   (let ((pending '()))
     (make-engraver
       (listeners
         ((articulation-event engraver event)
          (let ((type (ly:event-property event 'articulation-type)))
            (if (memq type '(air squareHead halfHarmonic))
                (set! pending (cons type pending))))))
       (acknowledgers
         ((note-head-interface engraver grob source-engraver)
          (let* ((cause (event-cause grob))
                 (arts  (if cause (ly:event-property cause 'articulations) '()))
                 (type  (cond
                          ((str-has-articulation? arts 'air) 'air)
                          ((str-has-articulation? arts 'squareHead) 'squareHead)
                          ((str-has-articulation? arts 'halfHarmonic) 'halfHarmonic)
                          ((memq 'air pending) 'air)
                          ((memq 'squareHead pending) 'squareHead)
                          ((memq 'halfHarmonic pending) 'halfHarmonic)
                          (else #f))))
            (cond
              ((memq type '(air squareHead))
               (ly:grob-set-property! grob 'stencil square-head-stencil))
              ((eq? type 'halfHarmonic)
               (ly:grob-set-property! grob 'style 'harmonic-black))))))
       ((stop-translation-timestep trans)
        (set! pending '())))))


%%% ── STRINGVOICE CONTEXT DEFINITION ──────────────────────────────────
%%% contactNoteheadsEngraver lives here, not in StringStaff, and this is
%%% not incidental — it was moved here after finding a real bug. Its
%%% bare-note detection (see the engraver's own comment) stages a
%%% "pending" queue that gets consumed by whichever note-head is
%%% acknowledged next. If the engraver is Staff-scoped, two simultaneous
%%% Voices in the same Staff share ONE pending queue: verified
%%% empirically that both noteheads then resolve to whichever type has
%%% higher priority in the queue, silently applying the SAME wrong
%%% articulation to both. Voice-scoping gives each Voice its own
%%% pending queue (a fresh closure per context instance), which
%%% eliminates the ambiguity rather than just documenting it.
%%%
%%% scordaturaEngraver lives here too, for an unrelated second reason:
%%% ties. Tie_engraver is Voice-scoped and, like every context's default
%%% consist list, was already in place before StringStaff's \consists
%%% additions -- so a Staff-scoped scordaturaEngraver always ran AFTER
%%% Tie_engraver on any given NoteHead (Voice-level acknowledgers fire
%%% before the grob's announcement bubbles up to Staff level). Verified
%%% empirically: a tie across two scordatura-transposed sounding-mode
%%% notes rendered with NO tie curve at all (not just a warning) --
%%% Tie_engraver compared the first note's cause pitch (already mutated,
%%% since our engraver had already run for that note by the time the
%%% second note arrived) against the second note's cause pitch (not yet
%%% mutated at the point Tie_engraver read it), and they didn't match.
%%% Moving scordaturaEngraver next to Tie_engraver in the same context
%%% isn't enough by itself -- \consists order still matters, so
%%% Tie_engraver is explicitly removed and re-added afterward to
%%% guarantee it sees the mutated pitch on both notes.
%%%
%%% DO NOT give scordaturaMode/scordaturaActive/scordaturaTuning/
%%% scordaturaBaseTuning their own default values here. Confirmed
%%% empirically: a context's own default for a property shadows a
%%% parent's \set entirely (ly:context-property does not fall through
%%% to the parent once the local context has ANY value, even a
%%% context-definition default) -- \set Staff.scordaturaMode = #'sounding
%%% would silently have no effect on notes if StringVoice also declared
%%% scordaturaMode = #'fingered as its own default. These properties are
%%% declared exactly once, on StringStaff, and StringVoice must inherit
%%% them by leaving them unset locally.
\layout {
  \context {
    \Voice
    \name StringVoice
    \alias Voice
    \remove Tie_engraver
    \consists \scordaturaEngraver
    \consists \contactNoteheadsEngraver
    \consists Tie_engraver
  }
}


%%% ── STRINGSTAFF CONTEXT DEFINITION ─────────────────────────────────
%%% \new StringStaff { ... }
%%% Inherits all Staff behavior via \alias Staff (clef, key, dynamics,
%%% spanners — everything works normally). Scordatura and string colors
%%% only activate inside StringStaff, so their context properties don't
%%% leak into a plain Staff. defaultchild StringVoice means music
%%% written directly inside \new StringStaff (no explicit \new Voice)
%%% gets contact-articulation support automatically; an explicit
%%% \new Voice still works (inherited from Staff) but without it —
%%% use \new StringVoice explicitly if you need multiple contact-
%%% articulated voices in one StringStaff.

\layout {
  \context {
    \Staff
    \name StringStaff
    \type Engraver_group
    \alias Staff
    \accepts StringVoice
    \defaultchild StringVoice
    \consists \stringColorsEngraver
    scordaturaMode      = #'fingered
    scordaturaActive    = ##f
    scordaturaTuning    = #'()
    scordaturaBaseTuning = #'()
    stringColorsActive  = ##f
    stringColorsInfer   = ##f
    stringColorList     = #strings-rainbow
    scriptDefinitions   = #contactScriptDefinitions
  }
  \context {
    \StaffGroup
    \accepts StringStaff
  }
  \context {
    \Score
    \accepts StringStaff
  }
}


%%% ── PUBLIC VOCABULARY: SCORDATURA ───────────────────────────────────

%%% \withScordatura #'instrument { tuning } { music }
%%% Tuning: ordered string 1 (highest) to string N (lowest).
%%% Use explicit octaves: { a, d, g, des, } not { a d g des }
%%% Mode set separately: \set Staff.scordaturaMode = #'sounding

withScordatura = #(define-music-function (instrument tuning-music music)
  (symbol? ly:music? ly:music?)
  (let* ((new-pitches (str-music->pitches tuning-music))
         (std-tuning  (assq-ref scord-instrument-tunings instrument)))
    (if (not std-tuning)
        (begin
          (ly:warning (string-append
                        "strings.ily: unknown instrument "
                        (symbol->string instrument)
                        " — add to scord-instrument-tunings"))
          music)
        #{
          \set Staff.scordaturaBaseTuning = #std-tuning
          \set Staff.scordaturaTuning     = #new-pitches
          \set Staff.scordaturaActive     = ##t
          #music
          \set Staff.scordaturaTuning     = #std-tuning
          \unset Staff.scordaturaActive
          \unset Staff.scordaturaBaseTuning
        #})))

%%% \unscordatura — explicit manual clear, for when \withScordatura's
%%% scope doesn't cover your use case.
unscordatura = {
  \unset Staff.scordaturaActive
  \unset Staff.scordaturaBaseTuning
}


%%% ── PUBLIC VOCABULARY: STRING COLORS ────────────────────────────────

%%% \withStringColors { music }
%%%   Activate coloring for explicit string numbers only.
withStringColors = #(define-music-function (music) (ly:music?)
  #{
    \set Staff.stringColorsActive = ##t
    #music
    \set Staff.stringColorsActive = ##f
  #})

%%% \withStringColorsInferred { music }
%%%   Activate coloring with lowest-fret inference.
%%%   Requires Staff.scordaturaTuning to be set (e.g. inside a
%%%   \withScordatura block, or set directly).
withStringColorsInferred = #(define-music-function (music) (ly:music?)
  #{
    \set Staff.stringColorsActive = ##t
    \set Staff.stringColorsInfer  = ##t
    #music
    \set Staff.stringColorsActive = ##f
    \set Staff.stringColorsInfer  = ##f
  #})


%%% ── LEGACY CONTACT ARTICULATION ALIASES ─────────────────────────────
%%% \square and \half-harmonic predate the suffix versions above
%%% (\squareHead / \halfHarmonic) and are prefix functions: they wrap
%%% exactly one note/chord and work in any Staff, not just StringStaff.
%%% Retained only because existing cues (1m1.ily, 1m2.ily, 2m1.ily) use
%%% them ~40 times; new music should prefer the suffix versions (they
%%% support chord-member independence, e.g. <c\squareHead g\halfHarmonic>,
%%% which these prefix forms cannot). No \air alias here — it was never
%%% used anywhere and would collide with the suffix \air above.
%%%
%%% Note: \harmonic (open diamond, touch only) is a LilyPond built-in.
%%% This family extends that vocabulary into pressure/overpressure
%%% territory.

square = #(define-music-function (music) (ly:music?)
  #{
    \override NoteHead.stencil = #square-head-stencil
    #music
    \revert NoteHead.stencil
  #})

half-harmonic = #(define-music-function (music) (ly:music?)
  #{
    \temporary \override NoteHead.style = #'harmonic-black
    #music
    \revert NoteHead.style
  #})
