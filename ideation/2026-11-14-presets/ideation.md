# Presets: outing-based C1–C4 loadouts

**Date:** 2026-11-14  
**Status:** open

## Goal

Describe an outing in plain words, for example "birding on a sunny day" or "the swim and dive meet at the pool". Get back the right settings for the OM-1 Mark II's custom mode slots (C1–C4), loaded or ready to load, so the camera is set up before you leave the house.

## How settings get onto the camera

What we found (needs testing on your body and firmware):

| Path | What it does | Notes |
|---|---|---|
| **OM Workspace** (USB, Mac) | Camera → Customer Settings → Save / Load. Writes a `.set` file. On load you pick which settings to apply, then the camera restarts. | Files only load into the **same model** (an OM-1 file fails on a Mark II). The format is proprietary binary. |
| **OM Image Share** (phone app) | Saves each custom mode from the camera, then loads it back **into any C slot**. | The only confirmed way to move one mode into a different slot. |
| **Wi-Fi HTTP API** (`get_camprop` / `set_camprop`, used by `olympuswifi`) | Sets live shooting properties remotely. | Not confirmed on OM-1 II, and probably can't write C slots. Treat as a stretch goal. |
| **Manual** | Dial it in from a checklist, then Menu → Assign to Custom Mode → C*n*. | Always works. It's the fallback. |

**Working assumption:** the source of truth is readable recipes kept in this repo. Each recipe is captured once on the camera as a per-mode file (Image Share or Workspace). After that, loading is just choosing a file. We don't try to write the binary format ourselves unless a later research step makes it worth it.

## Concepts

- **Recipe**: one complete setup for one situation (for example `birds-in-flight-bright`). It maps to a single C slot.
- **Kit**: an outing → up to 4 recipes assigned to C1–C4 (for example "sunny birding" = perched / in flight / Pro Capture takeoff / backup).
- **Base**: settings that aren't scenario-specific and stay the same everywhere (button mapping, EVF, file format, card slots). Recipes override the base only where needed.
- **Capture**: the camera-side `.set` / Image Share file that matches a recipe, plus the firmware it was saved on.

## Recipe format

```yaml
id: birds-in-flight-bright
name: Birds in flight – bright sun
intent: Fast action against sky; freeze wings, track bird eyes
mode: S
shutter: 1/3200
aperture: null            # camera picks (S mode)
iso: { auto: true, max: 3200 }
exposure_comp: +0.7       # bright sky behind subject
metering: ESP
af:
  mode: C-AF
  target: Cluster          # target pattern
  subject_detection: Birds
  c_af_sensitivity: +1
drive: { mode: SH2 }      # electronic, AF-tracking burst; fps TBD
stabilization: S-IS AUTO
white_balance: Sunny
notes: Switch to Pro Capture recipe for takeoffs.
capture:                  # filled in after you save it from the camera
  file: captures/birds-in-flight-bright.set
  firmware: "1.x"
  verified: 2026-11-xx
```

Setting names follow the camera's own menu names, so the checklist reads the way the menus do.

## Example kits (for discussion, values aren't final)

**Sunny birding**
| Slot | Recipe | Key settings |
|---|---|---|
| C1 | Perched birds | A, f/6.3, Auto ISO ≤3200, C-AF + Birds, Seq L |
| C2 | Birds in flight | S 1/3200, +0.7 EV, C-AF + Birds, Seq H |
| C3 | Takeoff / Pro Capture | Pro Capture SH2, pre-frames ~20, 1/4000 |
| C4 | Scenery / habitat | A f/8, ISO 200, S-AF, single shot |

**Pool – swim & dive** (indoor, mixed light, flicker)
| Slot | Recipe | Key settings |
|---|---|---|
| C1 | Swim lanes | S 1/1000, Auto ISO ≤6400, C-AF + Human, Seq H, Flicker Scan |
| C2 | Diving | S 1/2000, Pro Capture for entry, C-AF + Human |
| C3 | Team / podium | A f/4, Auto ISO, S-AF, face/eye priority |
| C4 | Silent / no-flash backup | Electronic shutter, flash off |

## Flow

1. You: "I'm going birding, sunny day."
2. Claude matches it to a kit, or builds one from existing recipes, and shows C1–C4 with the key settings.
3. You adjust if needed ("make C4 video instead").
4. Output:
   - **If every recipe has a capture:** which files to load into which slot, plus steps.
   - **If not:** a manual checklist for each slot, in menu order, ending with "Assign to C*n*". When you're done, save it from the camera as the new capture.
5. Optionally note how the settings worked after the outing, to feed recipe tuning.

## Repo layout

```
recipes/      one YAML per recipe
kits/         one YAML per outing → slot assignments
base.yaml     shared settings
captures/     camera-saved files (.set / Image Share exports)
ideation/     dated ideation sessions (see ideation_rules.md)
```

## Phases

1. **Recipes + checklists**: YAML library, a few starter kits, a generated per-slot checklist. Useful on day one, manual loading.
2. **Captures**: save each recipe from the camera and record a step-by-step load procedure for Image Share and for Workspace.
3. **Research (optional)**: test the Wi-Fi API on the OM-1 II. Diff `.set` files with one setting changed to see whether direct generation is feasible.

## Open questions

1. Phone (Image Share) or Mac (OM Workspace) for loading? It decides which capture format we standardize on.
2. Current firmware version on the body?
3. Do you already have C1–C4 set up anything you want to keep as a base or as recipes?
4. Output: a Markdown checklist in the terminal/repo, or a phone-friendly page you can follow at the camera?
5. Other outings to cover now (landscape, family/indoor, astro, video)?
6. Lenses: should a recipe assume a specific lens (e.g. 150-600 for birding), or stay lens-agnostic?
