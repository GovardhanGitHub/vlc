--[[
  VLC Lua Extension: Skip Timings & YouTube Percentage Seek
  Author: VLC Enhanced Contributor
  Description: Provides YouTube-style percentage seeking (0-90%) and multiple skip timings with auto-skip and merge intervals.
--]]

function descriptor()
    return {
        title = "Skip Timings & YouTube Seek",
        version = "1.0",
        author = "VLC Contributor",
        shortdesc = "Skip Timings and 0-9 Percentage Seeking",
        description = "Jump video percentage like YouTube (0-9) and define multiple video segments to auto-skip with interval merge support.",
        capabilities = { "input-listener" }
    }
end

local dlg = nil
local skip_ranges = {}
local auto_skip_active = true
local last_skipped_end = -1

function activate()
    create_dialog()
end

function deactivate()
    if dlg then
        dlg:delete()
        dlg = nil
    end
end

function close()
    vlc.deactivate()
end

function create_dialog()
    dlg = vlc.dialog("Skip Timings & YouTube Seek")

    -- Row 1: YouTube Percentage Seek Buttons
    dlg:add_label("<b>YouTube Percentage Seek:</b>", 1, 1, 10, 1)

    for i = 0, 9 do
        local pct = i * 10
        dlg:add_button(tostring(pct) .. "%", function()
            seek_percentage(pct / 100.0)
        end, i + 1, 2, 1, 1)
    end

    -- Row 3: Add Skip Timing Range
    dlg:add_label("<b>Add Skip Range:</b>", 1, 3, 10, 1)
    dlg:add_label("Label:", 1, 4, 2, 1)
    local input_label = dlg:add_text_input("Sponsor / Intro", 3, 4, 8, 1)

    dlg:add_label("Start (sec):", 1, 5, 2, 1)
    local input_start = dlg:add_text_input("10", 3, 5, 3, 1)
    dlg:add_button("Set Now", function()
        local t = get_current_time()
        if t >= 0 then input_start:set_text(tostring(t)) end
    end, 6, 5, 2, 1)

    dlg:add_label("End (sec):", 1, 6, 2, 1)
    local input_end = dlg:add_text_input("30", 3, 6, 3, 1)
    dlg:add_button("Set Now", function()
        local t = get_current_time()
        if t >= 0 then input_end:set_text(tostring(t)) end
    end, 6, 6, 2, 1)

    -- Row 7: Action Buttons
    dlg:add_button("Add Skip Timing", function()
        local s = tonumber(input_start:get_text()) or 0
        local e = tonumber(input_end:get_text()) or 0
        local lbl = input_label:get_text()
        if e > s then
            table.insert(skip_ranges, { start_time = s, end_time = e, label = lbl })
            vlc.osd.message("Added Skip Range: " .. lbl .. " [" .. s .. "s - " .. e .. "s]")
            refresh_list()
        else
            vlc.osd.message("Error: End time must be greater than start time")
        end
    end, 1, 7, 3, 1)

    dlg:add_button("Merge Overlapping Timings", function()
        merge_timings()
    end, 4, 7, 4, 1)

    dlg:add_button("Clear All", function()
        skip_ranges = {}
        refresh_list()
        vlc.osd.message("Cleared all skip ranges")
    end, 8, 7, 3, 1)

    -- Row 8: Active Timings List
    dlg:add_label("<b>Active Skip Ranges:</b>", 1, 8, 10, 1)
    list_label = dlg:add_label("No skip timings added yet.", 1, 9, 10, 3)
end

function get_current_time()
    local input = vlc.object.input()
    if not input then return -1 end
    local time = vlc.var.get(input, "time")
    return math.floor(time or 0)
end

function seek_percentage(pos)
    local input = vlc.object.input()
    if not input then return end
    vlc.var.set(input, "position", pos)
    vlc.osd.message(string.format("Seek: %d%%", math.floor(pos * 100)))
end

function refresh_list()
    if not list_label then return end
    if #skip_ranges == 0 then
        list_label:set_text("No skip timings added yet.")
        return
    end

    local text = ""
    for idx, r in ipairs(skip_ranges) do
        text = text .. string.format("%d. %s: %ds -> %ds\n", idx, r.label or "Skip", r.start_time, r.end_time)
    end
    list_label:set_text(text)
end

function merge_timings()
    if #skip_ranges <= 1 then return end

    -- Sort by start time
    table.sort(skip_ranges, function(a, b)
        return a.start_time < b.start_time
    end)

    local merged = {}
    local curr = skip_ranges[1]

    for i = 2, #skip_ranges do
        local nxt = skip_ranges[i]
        if nxt.start_time <= curr.end_time then
            -- Overlap or contiguous: merge
            if nxt.end_time > curr.end_time then
                curr.end_time = nxt.end_time
            end
            curr.label = curr.label .. " + " .. nxt.label
        else
            table.insert(merged, curr)
            curr = nxt
        end
    end
    table.insert(merged, curr)

    skip_ranges = merged
    refresh_list()
    vlc.osd.message("Merged overlapping skip timings! Active: " .. tostring(#skip_ranges))
end

function input_changed()
    -- When playing, monitor current time and skip
    if not auto_skip_active or #skip_ranges == 0 then return end

    local current_time = get_current_time()
    if current_time < 0 then return end

    for _, r in ipairs(skip_ranges) do
        if current_time >= r.start_time and current_time < r.end_time then
            if last_skipped_end ~= r.end_time then
                last_skipped_end = r.end_time
                local input = vlc.object.input()
                if input then
                    vlc.var.set(input, "time", r.end_time)
                    vlc.osd.message("⏩ Skipped: " .. (r.label or "Segment") .. " to " .. r.end_time .. "s")
                end
                break
            end
        end
    end

    if last_skipped_end >= 0 and current_time > last_skipped_end + 1 then
        last_skipped_end = -1
    end
end
