# Ideation Rules

Rules for AI agents (and humans) working in `ideation/`.

## Folder naming

- One folder per ideation session: `YYYY-MM-DD-theme`
  - Date = the day the ideation started (not last edited).
  - Theme = **one word**, lowercase, no hyphens or spaces (e.g. `presets`, `birding`, `transfer`).
  - Example: `2026-11-14-presets`
- Two sessions on the same day get different themes. Never reuse an existing folder name.
- Before creating a folder, list `ideation/` so the theme doesn't duplicate an earlier one. If it's a follow-up, pick a new theme word and link back to the earlier folder.

## Files inside a session folder

- Main document: `ideation.md`. Every session has one.
- Supporting files (research notes, sketches, sample data) use lowercase kebab-case: `wifi-api-notes.md`, `sample-recipe.yaml`.
- No spaces or capital letters in file names.

## `ideation.md` structure

Start with:

```markdown
# Theme: short title

**Date:** YYYY-MM-DD
**Status:** open | decided | parked | superseded
```

Then, in roughly this order:
1. **Goal**: what we're trying to figure out.
2. **Findings**: facts gathered, and how confident we are in them. Mark anything unverified on the camera as such.
3. **Proposal / options**: the current direction, with a recommendation.
4. **Open questions**: always a **numbered** list, so the user can answer by number.
5. **Sources**: markdown links for anything from the web.

## Editing rules

- Update the session's own folder while it's open. Once its status is `decided`, `parked` or `superseded`, don't rewrite it. Start a new dated folder and link back.
- When answers come in, record them under the question (e.g. `→ Answer: phone / Image Share`). Don't delete the question.
- When an ideation produces a design that's going to be built, move it out to a spec, set the session status to `decided`, and add a line linking to the spec.
- Keep camera setting names exactly as the OM-1 Mark II menus show them.
- Don't commit or push unless the user asks.
