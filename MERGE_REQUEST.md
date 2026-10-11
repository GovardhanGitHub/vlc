# Merge Request: YouTube-Style Percentage Seeking (0-9) and Multiple Skip Video Timings with Merge Support

**Target Branch:** `master`  
**Source Branch:** `feature/youtube-percentage-and-skip-timings`  
**Upstream Repository:** VideoLAN VLC (`https://code.videolan.org/videolan/vlc.git`)  
**Type:** Feature / Enhancement

---

## 1. Summary of Changes

This Merge Request introduces two high-value video playback features to VLC Media Player:

1. **YouTube-style Number Keys (0–9) Percentage Seeking**:
   - Pressing keys `0` through `9` during playback immediately jumps to the corresponding video percentage (`0` = 0%, `1` = 10%, `2` = 20%, ..., `9` = 90% of duration).
   - Updates the OSD position display upon seek.
   - Configurable in VLC preferences under hotkeys (`key-seek-percent-0` to `key-seek-percent-90`).

2. **Multiple Skip Video Timings with Interval Merging & Auto-Skip**:
   - Allows defining multiple timestamp intervals (`[start, end]`) for skipping intros, sponsor segments, recaps, and outros.
   - Auto-skips forward to `end` whenever playback reaches `start`.
   - **Merge Overlapping Timings Algorithm (`vlc_player_MergeSkipRanges`)**: Automatically merges overlapping or adjacent intervals (e.g. `[10s, 30s]` and `[25s, 50s]` into `[10s, 50s]`), avoiding redundant seeks and duplicate segments.
   - Public Core Player API exposed in `include/vlc_player.h` and exported in `src/libvlccore.sym`.
   - Unit tests added in `test/src/player/skip_ranges.c`.
   - Companion Lua GUI Extension added in `share/lua/extensions/skip_and_percentage_jump.lua` for instant graphical use in VLC.

---

## 2. Key Code Modifications

| Component / Subsystem | Files Changed | Description |
| :--- | :--- | :--- |
| **Actions Definition** | `include/vlc_actions.h` | Added `ACTIONID_SEEK_PERCENT_0` through `ACTIONID_SEEK_PERCENT_90` |
| **Action Lookup** | `src/misc/actions.c` | Added `"seek-percent-0"` to `"seek-percent-90"` in sorted `s_names2actions` table |
| **Hotkeys Module** | `modules/control/hotkeys.c` | Added `PlayerSeekPercent` handler and bound action range in actions table |
| **LibVLC Core Config** | `src/libvlc-module.c` | Registered default key bindings (`"0"` through `"9"`) and localized descriptions |
| **Player Core Header** | `include/vlc_player.h` | Declared `vlc_player_skip_range_t`, `vlc_player_AddSkipRange`, `vlc_player_ClearSkipRanges`, `vlc_player_MergeSkipRanges`, etc. |
| **Player Internal** | `src/player/player.h` | Added `skip_state` struct to `vlc_player_t` and declared `vlc_player_input_HandleSkipRanges` |
| **Player Implementation**| `src/player/player.c` | Implemented skip range list management and $O(N \log N)$ interval merge algorithm |
| **Input Event Loop** | `src/player/input.c` | Hooked `vlc_player_input_HandleSkipRanges` into `input_thread_Events` for automatic playback skipping |
| **Symbol Exports** | `src/libvlccore.sym` | Exported new skip player symbols |
| **Tests** | `test/src/player/skip_ranges.c`<br>`test/Makefile.am` | Unit tests for adding ranges, validation, and interval merging |
| **VLC Lua Extension** | `share/lua/extensions/skip_and_percentage_jump.lua` | Interactive dialog with 0-9% seek buttons and Skip Range Manager |

---

## 3. How to Test and Validate

### Testing Feature 1 (YouTube 0-9 Percentage Seeking):
1. Start playback of any media file in VLC.
2. Press keyboard numbers:
   - Press `0`: video seeks to 0% (beginning).
   - Press `5`: video seeks to 50% (middle).
   - Press `9`: video seeks to 90%.
3. OSD shows position confirmation.

### Testing Feature 2 (Multiple Skip Timings & Merge):
1. Run player unit test suite:
   ```sh
   make check TESTS="test_src_player_skip_ranges"
   ```
2. Verify adding multiple intervals and merging:
   - Interval A: `10s` to `30s`
   - Interval B: `25s` to `50s`
   - After calling `vlc_player_MergeSkipRanges(player)`, intervals merge into `10s` to `50s`.
3. During playback, when time reaches `10s`, player automatically seeks to `50s`.

### Testing via Lua Extension:
1. In VLC, go to **View** -> **Skip Timings & YouTube Seek**.
2. Click any percentage button (`0%` - `90%`) or use the Skip Range Manager.
3. Click **Merge Overlapping Timings** to merge contiguous intervals.

---

## 4. How to Merge This Branch into Master

```bash
# Ensure working tree is clean
git checkout master

# Merge the feature branch
git merge feature/youtube-percentage-and-skip-timings

# Push to your remote repository
git push origin master
```
