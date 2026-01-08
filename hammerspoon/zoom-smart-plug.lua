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
    ha_webhook_url = "http://192.168.0.241:8123/api/webhook/zoom_meeting",

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

    -- Check Zoom windows for meeting indicators
    local app = hs.application.find(config.zoom_process)
    if not app then
        return false
    end

    -- Method 1: Check for meeting window title patterns
    local windows = app:allWindows()
    for _, window in ipairs(windows) do
        local title = window:title()
        if title then
            -- Meeting windows typically have these patterns
            if string.match(title:lower(), "zoom meeting") or
               string.match(title:lower(), "participant") or
               (string.match(title:lower(), "zoom") and not string.match(title:lower(), "home")) then
                return true
            end
        end
    end

    -- Method 2: Check menu bar extra
    local menuItems = app:getMenuItems()
    if menuItems and menuItems["Meeting"] then
        -- If "Meeting" menu exists, we're in a meeting
        return true
    end

    return false
end

-- ========================================
-- Home Assistant Webhook
-- ========================================
local function sendWebhook(meeting_state)
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
            else
                log.e(string.format("Webhook failed (status %d): %s", status, body))
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
        sendWebhook("started")
        state.in_meeting = true

        -- Optional: show notification
        hs.notify.new({
            title = "Zoom Meeting",
            informativeText = "Smart plug turned ON",
        }):send()

    -- State transition: in meeting → not in meeting
    elseif not currently_in_meeting and state.in_meeting then
        log.i("Meeting ended - turning off smart plug")
        sendWebhook("ended")
        state.in_meeting = false

        -- Optional: show notification
        hs.notify.new({
            title = "Zoom Meeting",
            informativeText = "Smart plug turned OFF",
        }):send()
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
