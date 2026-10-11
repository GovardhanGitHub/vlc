// SPDX-License-Identifier: LGPL-2.1-or-later
/*****************************************************************************
 * skip_ranges.c: player skip ranges and merge test
 *****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
 *****************************************************************************/

#include "common.h"

static void
test_skip_ranges_basic(struct ctx *ctx)
{
    vlc_player_t *player = ctx->player;

    vlc_player_Lock(player);

    /* Initially empty */
    assert(vlc_player_GetSkipRangesCount(player) == 0);
    assert(vlc_player_IsAutoSkipEnabled(player) == true);

    /* Add invalid range (end <= start) should fail */
    int ret = vlc_player_AddSkipRange(player, vlc_tick_from_sec(50), vlc_tick_from_sec(30), "Invalid");
    assert(ret == VLC_EINVAL);
    assert(vlc_player_GetSkipRangesCount(player) == 0);

    /* Add distinct ranges */
    ret = vlc_player_AddSkipRange(player, vlc_tick_from_sec(10), vlc_tick_from_sec(25), "Intro");
    assert(ret == VLC_SUCCESS);
    ret = vlc_player_AddSkipRange(player, vlc_tick_from_sec(60), vlc_tick_from_sec(90), "Sponsor");
    assert(ret == VLC_SUCCESS);
    assert(vlc_player_GetSkipRangesCount(player) == 2);

    /* Clear */
    vlc_player_ClearSkipRanges(player);
    assert(vlc_player_GetSkipRangesCount(player) == 0);

    vlc_player_Unlock(player);
}

static void
test_skip_ranges_merge(struct ctx *ctx)
{
    vlc_player_t *player = ctx->player;

    vlc_player_Lock(player);
    vlc_player_ClearSkipRanges(player);

    /* Add overlapping ranges:
     * Range 1: [10s, 30s]
     * Range 2: [25s, 50s] (overlaps with Range 1 -> merges to [10s, 50s])
     * Range 3: [70s, 80s] (disjoint)
     * Range 4: [80s, 100s] (contiguous with Range 3 -> merges to [70s, 100s])
     */
    vlc_player_AddSkipRange(player, vlc_tick_from_sec(10), vlc_tick_from_sec(30), "Segment 1");
    vlc_player_AddSkipRange(player, vlc_tick_from_sec(25), vlc_tick_from_sec(50), "Segment 2");
    vlc_player_AddSkipRange(player, vlc_tick_from_sec(70), vlc_tick_from_sec(80), "Segment 3");
    vlc_player_AddSkipRange(player, vlc_tick_from_sec(80), vlc_tick_from_sec(100), "Segment 4");

    assert(vlc_player_GetSkipRangesCount(player) == 4);

    /* Perform merge */
    size_t new_count = vlc_player_MergeSkipRanges(player);
    assert(new_count == 2);
    assert(vlc_player_GetSkipRangesCount(player) == 2);

    /* Clean up */
    vlc_player_ClearSkipRanges(player);
    assert(vlc_player_GetSkipRangesCount(player) == 0);

    vlc_player_Unlock(player);
}

int
main(void)
{
    struct ctx ctx;
    ctx_init(&ctx);

    test_skip_ranges_basic(&ctx);
    test_skip_ranges_merge(&ctx);

    ctx_destroy(&ctx);
    return 0;
}
