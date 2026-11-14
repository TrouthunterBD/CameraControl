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
| **gphoto2** (USB, Mac, open source) | Reads and sets camera properties over PTP: `gphoto2 --list-all-config` / `--set-config`. | **Tested 2026-11-14, see below.** Can't write C slots, but can push a recipe's settings. Then you assign to C*n* on the camera. |
| **Manual** | Dial it in from a checklist, then Menu → Assign to Custom Mode → C*n*. | Always works. It's the fallback. |

**Working assumption:** the source of truth is readable recipes kept in this repo. Each recipe is captured once on the camera as a per-mode file (Image Share or Workspace). After that, loading is just choosing a file. We don't try to write the binary format ourselves unless a later research step makes it worth it.

### gphoto2 probe (2026-11-14, read-only)

- Setup: Mac, gphoto2 2.5.32 / libgphoto2 2.5.34 (Homebrew). Ran `killall ptpcamerad` first, because macOS otherwise grabs the camera.
- `gphoto2 --auto-detect` found the camera: `Olympus OM-1MarkII` on `usb:002,003`. The camera reports firmware **1.00**.
- Full dump: [`gphoto2-config-dump.txt`](gphoto2-config-dump.txt) (serial number removed). 317 properties: **215 writable**, 102 read-only.
- **Named** (writable): image format, WB, color temp, WB A/B shift, exposure comp, focus mode, aspect ratio, metering, aperture, shutter speed. Also bulb, manual focus drive, raw opcode, and date/time.
- **About 290 unnamed vendor properties** (`/main/other/d0xx`–`d1xx`) with raw numeric values. These are probably where AF target, subject detection, drive/Pro Capture, IS, ISO limits and so on live, but unmapped.
- **Hand mapping (done once, then stopped):** the camera locks its controls while it's connected in RAW/Control, so each change means unplugging, changing the setting, replugging and choosing RAW/Control again. Changing Subject Detection Birds → Airplanes → Off showed it's `d1d0`, with 5 = Birds, 3 = Airplanes, 1 = Off. A dozen or so codes change on every read with nothing touched (live meter/AF readings, `d061` = CameraState, timestamps), so diffs have to ignore them.
- **Reference found, so no more hand mapping:** libgphoto2's development code (`camlibs/ptp2/ptp.h`, `config.c`) is getting OM-1 support right now (commits 2026-11-10 to 11-12, e.g. PR #1365). It names **282 of the 296** vendor codes on this camera and has value tables for 56 settings, including subject detection (it matches the hand result), drive mode (Single/Seq/SH1/SH2/Pro Capture variants), AF area, image stabilizer, focus mode, AF limiter, Auto ISO minimum shutter speed and bracketing. Release 2.5.34 (2026-05-30) predates this, so it shows the codes unnamed.
- Current values decoded from the reference: mode S (`d006`=4), drive **Silent Sequential** (`d009`=0x27), AF area Small (`d00c`=0x8802), S-IS Auto (`d01d`=4), custom mode C1 (`d174`=1).
- `CustomMode` (`d174`) **reports** the active C slot. It doesn't save to one, so the "Assign to Custom Mode → C*n*" step stays on the camera.
- **Writes work (2026-11-14):** `--set-config /main/capturesettings/exposurecompensation=0.3`, then `=-0.7`. Both read back correctly and showed on the camera display. Exposure comp only comes in ⅓-stop steps (…, −0.7, −0.3, 0, +0.3, +0.7, …), so recipes must use those values. The known Mark II bug ([libgphoto2 #1308](https://github.com/gphoto/libgphoto2/issues/1308)) is the camera stopping responding after the end of a session.
- **Installed (2026-11-14):** `brew install --HEAD libgphoto2` fails to link (missing `libintl`/gettext). What worked was building from git (commit `31a2f40`) with `./configure --disable-nls --with-camlibs=ptp2` into a separate prefix, then running Homebrew's `gphoto2` with `DYLD_LIBRARY_PATH`, `CAMLIBS` and `IOLIBS` pointing at it. Homebrew's 2.5.34 is left untouched.
- **Result:** [`gphoto2-config-head.txt`](gphoto2-config-head.txt) has 517 entries: **221 named** settings with choice lists, plus the same 296 raw codes. Writable and named, with choices: drive mode (13), subject detection (7), ISO (31), image stabilizer, focus mode, AF area, AF limiter (on/distance/release priority), Auto ISO minimum shutter, exposure comp, metering, aperture, shutter, WB + A-B/G-M shift, image format, aspect ratio, and per-drive-mode frame limiters and max fps. Read-only: exposure program (mode dial) and custom mode (active C slot).
- After a power cycle, Subject Detection read **Birds** again, even though it had been set to Off. It looks like the camera reverted to C1's saved settings, so changes made while in a C mode are temporary until assigned to a slot (to confirm).
- After about 8 connect/disconnect cycles the camera got stuck with "I/O in progress" until it was power cycled (probably the #1308 bug).
- Firmware 1.00 is older than the 1.1 that OM Workspace's MTP settings backup expects. It may be worth updating, after a manual backup.

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
   → Answer: 1.00 (reported over USB, 2026-11-14)
3. Do you already have C1–C4 set up anything you want to keep as a base or as recipes?
4. Output: a Markdown checklist in the terminal/repo, or a phone-friendly page you can follow at the camera?
5. Other outings to cover now (landscape, family/indoor, astro, video)?
6. Lenses: should a recipe assume a specific lens (e.g. 150-600 for birding), or stay lens-agnostic?
7. Map the unnamed USB properties (change one setting, dump, diff)? It's about one setting per minute, best done with the camera next to you.
   → Answer: no, the user doesn't want to map everything. Use the libgphoto2 development code instead. Only hand-map gaps a recipe actually needs.

## Sources

- [How to download settings in your camera (OM System)](https://explore.omsystem.com/us/en/how-to-download-settings-in-your-camera)
- [OM System firmware update instructions (MTP for settings backup)](https://explore.omsystem.com/c/en/firmware-update-instructions)
- [OM-1 Mark II manual: saving to C1–C4](https://learning.omsystem.com/OM-1MarkII/zz_html_manual/en/taking_pictures_using_c_26.html)
- [OM-1 Mark II manual: RAW/Control](https://learning.omsystem.com/OM-1MarkII/zz_html_manual/en/high-speed_raw_processing_299.html)
- [DPReview: OM1-II assigning and moving custom settings](https://www.dpreview.com/forums/threads/om1-ii-assigning-and-moving-custom-settings.4753874/)
- [E-Group: OM-1 settings won't load on Mark II](https://www.e-group.uk.net/forum/forum/cameras-lenses-and-system-accessories/camera-conference/micro-four-thirds/new-om-system-om-1-mark-ii/964295-om-1-mark-ii-loading-saved-settings-from-om-1)
- [libgphoto2 ptp.h](https://github.com/gphoto/libgphoto2/blob/master/camlibs/ptp2/ptp.h) · [config.c](https://github.com/gphoto/libgphoto2/blob/master/camlibs/ptp2/config.c) · [PR #1365](https://github.com/gphoto/libgphoto2/pull/1365)
- [libgphoto2 releases](https://github.com/gphoto/libgphoto2/releases) · [issue #1308](https://github.com/gphoto/libgphoto2/issues/1308)
- [n0p/om-tether](https://github.com/n0p/om-tether) · [HolmHaensel/omcap](https://github.com/HolmHaensel/omcap) · [fishcu/oly_fw_analysis](https://github.com/fishcu/oly_fw_analysis)
- [olympuswifi API docs](https://olympus-wifi.readthedocs.io/en/stable/api.html)
