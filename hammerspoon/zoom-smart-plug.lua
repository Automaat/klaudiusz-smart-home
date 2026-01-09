-- ========================================
-- Zoom Meeting Smart Plug Controller
-- ========================================
-- Monitors Zoom meeting state and controls
-- Home Assistant smart plug via webhook
--
-- Installation:
-- 1. Copy to ~/.hammerspoon/zoom-smart-plug.lua
-- 2. Add to ~/.hammerspoon/init.lua:
--    require("zoom-smart-plug")
-- 3. Reload Hammerspoon config

local log = hs.logger.new('zoom-smart-plug', 'info')

-- ========================================
-- Configuration
-- ========================================
local config = {
    -- Home Assistant webhook URL
    -- NOTE: Update webhook_id to match your installation
    -- Using mDNS hostname (homeassistant.local) for network flexibility
    ha_webhook_url = "http://homeassistant.local:8123/api/webhook/zoom_meeting_7cca0951_0a49_4bdc_a8d3_cc46ea7d8980",

    -- Check interval (seconds)
    check_interval = 5,

    -- Zoom process name
    zoom_process = "zoom.us",
}

-- ========================================
-- State Management
-- ========================================
local state = {
    in_meeting = false,
    timer = nil,
}

-- ========================================
-- Zoom Meeting Detection
-- ========================================
local function isZoomRunning()
    local app = hs.application.find(config.zoom_process)
    return app ~= nil and app:isRunning()
end

local function isInMeeting()
    if not isZoomRunning() then
        return false
    end

    -- Method 1: Check for CptHost process (Zoom meeting component)
    -- This is the most reliable method - CptHost only runs during active meetings
    local output, status = hs.execute("pgrep -x CptHost")
    if status then
        log.d("CptHost process detected - in meeting")
        return true
    end

    -- Method 2: Check for meeting window patterns (fallback)
    local app = hs.application.find(config.zoom_process)
    if not app then
        return false
    end

    local windows = app:allWindows()
    for _, window in ipairs(windows) do
        local title = window:title()
        if title and title ~= "" then
            local lower_title = title:lower()
            if string.match(lower_title, "zoom meeting") or
               string.match(lower_title, "zoom cloud meeting") or
               string.match(lower_title, "'s meeting") or
               string.match(lower_title, "participant") then
                log.d("Meeting window detected: " .. title)
                return true
            end
        end
    end

    -- Method 3: Check for "Meeting" menu
    local menuItems = app:getMenuItems()
    if menuItems and menuItems["Meeting"] then
        log.d("Meeting menu detected")
        return true
    end

    return false
end

-- ========================================
-- Home Assistant Webhook
-- ========================================
local function sendWebhook(meeting_state, on_success)
    local json = hs.json.encode({state = meeting_state})

    local headers = {
        ["Content-Type"] = "application/json"
    }

    log.i(string.format("Sending webhook: %s", meeting_state))

    hs.http.asyncPost(
        config.ha_webhook_url,
        json,
        headers,
        function(status, body, headers)
            if status == 200 then
                log.i(string.format("Webhook sent successfully: %s", meeting_state))
                if on_success then
                    on_success()
                end
            else
                log.e(string.format("Webhook failed (status %d): %s", status or "nil", body or "no response"))
            end
        end
    )
end

-- ========================================
-- State Change Handler
-- ========================================
local function checkMeetingState()
    local currently_in_meeting = isInMeeting()

    -- State transition: not in meeting → in meeting
    if currently_in_meeting and not state.in_meeting then
        log.i("Meeting started - turning on smart plug")
        sendWebhook("started", function()
            -- Only update state after successful webhook
            state.in_meeting = true

            -- Optional: show notification
            hs.notify.new({
                title = "Zoom Meeting",
                informativeText = "Smart plug turned ON",
            }):send()
        end)

    -- State transition: in meeting → not in meeting
    elseif not currently_in_meeting and state.in_meeting then
        log.i("Meeting ended - turning off smart plug")
        sendWebhook("ended", function()
            -- Only update state after successful webhook
            state.in_meeting = false

            -- Optional: show notification
            hs.notify.new({
                title = "Zoom Meeting",
                informativeText = "Smart plug turned OFF",
            }):send()
        end)
    end
end

-- ========================================
-- Initialization
-- ========================================
local function start()
    if state.timer then
        state.timer:stop()
    end

    log.i("Starting Zoom meeting monitor")
    log.i(string.format("Webhook URL: %s", config.ha_webhook_url))
    log.i(string.format("Check interval: %d seconds", config.check_interval))

    -- Initial check
    checkMeetingState()

    -- Start periodic checks
    state.timer = hs.timer.new(config.check_interval, checkMeetingState)
    state.timer:start()

    log.i("Zoom meeting monitor started")
end

local function stop()
    if state.timer then
        state.timer:stop()
        state.timer = nil
    end
    log.i("Zoom meeting monitor stopped")
end

-- ========================================
-- Module Interface
-- ========================================
local module = {
    start = start,
    stop = stop,
    config = config,
}

-- Auto-start on load
start()

return module
