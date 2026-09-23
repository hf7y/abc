# abc

Music for **Abecedarian** — three feature films meant to play simultaneously.
This repo holds the notation. Everything else lives where it is named below.

    lilypond -dno-point-and-click 1m.ly     # from the repo root; the paths are relative

## Naming

    b1m1-gewissensruf.ily
    ^^^^                     canonical, machine-read: film b, reel 1, cue 1
        ^^^^^^^^^^^^         human flavour, affects nothing

A reel is an act. Cue numbers restart per reel, so the film letter is part of
the identity, not decoration. A file's prefix must agree with its own
`\header opus` field — the one mismatch this repo has actually shipped.

## Where the rest of it is

| what | where |
|---|---|
| every relationship, timestamp and cue↔scene link | `abcdb` — the NocoDB instance on dexter |
| takes, sketches, picture, renders | dexter, split by kind |
| the notation library | `lib/core`, a submodule of [hf7y/zly](https://github.com/hf7y/zly) |
| house style, timing vocabulary | `lib/project/` |
| open work | `gh issue list --repo hf7y/abc` |

Git holds schema and migrations, never rows. Media never enters git.

## Where the rules live

Nowhere in prose, deliberately.

| what | where it is enforced |
|---|---|
| the tree may not gain prose | `.prose-ratchet` + `.github/workflows/prose.yml`, the guard in hf7y/etalon |
| this repo is an agent project | `.agent-project`, read by realisateur's verb build |
| media stays out of git | `.gitignore` |

Every root `.ly` compiling, a cue's prefix agreeing with its `opus`, and no
file referencing a path that does not exist are **not** enforced yet. They are
issues, not claims: `gh issue list --repo hf7y/abc --milestone "The score
compiles and a check says so"`.
