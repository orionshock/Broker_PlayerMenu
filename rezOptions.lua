local addonName, addon = ...

if _G[addonName] ~= addon then
    _G[addonName] = addon
end
local rezOptions = {}
addon.rezOptions = rezOptions

---
-- RezOptions module - helper functions to populate a LibQTip tooltip with
-- resurrection-related options (accept rez, retrieve corpse, self-rez, release).
-- @module rezOptions
-- @field eventFrame Frame The frame used for event handling
-- @field myTooltip table|nil Current LibQTip tooltip instance (or nil)
-- @field resurrectRequesterName string|nil Name of the player who requested resurrection
-- @field corpseInRange boolean Whether the player's corpse is in range
-- @field playerDeadInCorpse boolean Whether the player is dead on their corpse
---

local eventFrame = CreateFrame("Frame", nil, UIParent)
rezOptions.eventFrame = eventFrame
local LibQTip = LibStub("LibQTip-1.0")

local myTooltip
local resurrectRequesterName = nil
local corpseInRange = false
local playerDeadInCorpse = false

--- Add a tooltip line that allows the player to retrieve their corpse.
-- @local
-- @tparam table tooltip LibQTip tooltip object
local function populateTooltip_RetrieveCorpse(tooltip)
    local currentLine = tooltip:AddLine(RECOVER_CORPSE)
    tooltip:SetLineScript(currentLine, "OnMouseUp", RetrieveCorpse)
end

--- Handle choosing a self-resurrect option from the tooltip.
-- This calls the Blizzard API to use the selected self-resurrect.
-- @local
-- @tparam Frame frame The frame the tooltip line belongs to
-- @tparam table info Table with fields 'optionType' and 'id'
-- @tparam string|number button Mouse/button identifier passed by LibQTip
local function DoSelfRez(frame, info, button)
    if info then
        C_DeathInfo.UseSelfResurrectOption(info.optionType, info.id)
    end
end

--- Populate tooltip with available self-resurrect options.
-- Each line will call DoSelfRez when clicked.
-- @local
-- @tparam table tooltip LibQTip tooltip object
local function populateTooltip_SelfRez(tooltip)
    local selfRezOptions = C_DeathInfo.GetSelfResurrectOptions()
    for i = 1, #selfRezOptions do
        local info = selfRezOptions[i]
        local currentLine = tooltip:AddLine(info.name)
        tooltip:SetLineScript(currentLine, "OnMouseUp", DoSelfRez, info)
    end
end

--- Add a tooltip line to allow the player to release spirit (if dead).
-- @local
-- @tparam table tooltip LibQTip tooltip object
local function populateTooltip_PlayerIsDead(tooltip)
    local currentLine = tooltip:AddLine(DEATH_RELEASE)
    tooltip:SetLineScript(currentLine, "OnMouseUp", RepopMe)
end

--- Populate tooltip with an Accept Resurrect option for another player's rez.
-- Formats the global RESURRECT_REQUEST_NO_SICKNESS string with the
-- `resurrectRequesterName` (falls back to a small sentinel string).
-- Clicking the line will accept the resurrect and clear the stored name.
-- @local
-- @tparam table tooltip LibQTip tooltip object
local function populateTooltip_OtherRez(tooltip)
    if resurrectRequesterName == "" or resurrectRequesterName == nil then
        resurrectRequesterName = "?UnknownRezer"
    end
    local text = string.format(RESURRECT_REQUEST_NO_SICKNESS, resurrectRequesterName)
    local currentLine = tooltip:AddLine(text)
    -- Use a small wrapper so we can clear the cached name after accepting.
    tooltip:SetLineScript(currentLine, "OnMouseUp", function()
        resurrectRequesterName = nil; AcceptResurrect()
    end)
end

--- Called when the mouse leaves the RezOptions tooltip; releases it.
-- @local
-- @tparam table self The tooltip frame passed by LibQTip's auto-hide
local function RezOptions_OnLeave(self)
    LibQTip:Release(myTooltip)
    myTooltip = nil
end

--- Tooltip OnEnter handler; builds the tooltip body depending on state.
-- This function will add lines for:
-- * Accepting another player's resurrection (when ResurrectHasTimer())
-- * Retrieving a corpse if in range
-- * Self-resurrect options
-- * Releasing spirit when dead
-- @local
-- @tparam Frame frame The UI frame that triggered the OnEnter
local function RezOptions_OnEnter(frame)
    if myTooltip and myTooltip:IsShown() then
        return
    end
    local tooltip = LibQTip:Acquire("RezOptionsToolTip", 1, "CENTER")
    if not tooltip then
        return
    end
    myTooltip = tooltip
    local showingTooltip = false
    if ResurrectHasTimer() then
        showingTooltip = true
        populateTooltip_OtherRez(tooltip)
    end
    if corpseInRange then
        showingTooltip = true
        populateTooltip_RetrieveCorpse(tooltip)
    end
    if C_DeathInfo.GetSelfResurrectOptions() then
        showingTooltip = true
        populateTooltip_SelfRez(tooltip)
    end
    if UnitIsDead("player") then
        showingTooltip = true
        populateTooltip_PlayerIsDead(tooltip)
    end

    if showingTooltip then
        tooltip:SetAutoHideDelay(.01, frame, RezOptions_OnLeave)
        tooltip:SmartAnchorTo(frame)
        tooltip:Show()
    end
end

--LDB OBJECT--
local ldbObject = {
    type = "data source",
    label = "RezOptions",
    icon = "135955",
    OnEnter = RezOptions_OnEnter
}
local libLDB = LibStub:GetLibrary("LibDataBroker-1.1")
libLDB:NewDataObject("RezOptions", ldbObject)
---

eventFrame:SetScript(
    "OnEvent",
    function(frame, event, ...)
        if (type(rezOptions[event]) == "function") then
            --print("rezOptions_event: ", event)
            rezOptions[event](rezOptions, event, ...)
        end
    end
)
eventFrame:RegisterEvent("CORPSE_IN_RANGE")
eventFrame:RegisterEvent("CORPSE_OUT_OF_RANGE")
eventFrame:RegisterEvent("PLAYER_DEAD")
eventFrame:RegisterEvent("RESURRECT_REQUEST")


function rezOptions:CORPSE_IN_RANGE(event)
    corpseInRange = true
end

function rezOptions:CORPSE_OUT_OF_RANGE(event)
    corpseInRange = false
end

function rezOptions:PLAYER_DEAD(event)
    eventFrame:Show()
end

function rezOptions:PLAYER_ALIVE(event)
    eventFrame:Hide()
end

-- Capture the name (first arg) from a resurrection request event
function rezOptions:RESURRECT_REQUEST(event, requesterName)
    resurrectRequesterName = requesterName
end

eventFrame.interval = 0
eventFrame:SetScript("OnUpdate", function(self, elapsed)
    self.interval = self.interval + elapsed
    if GetReleaseTimeRemaining() then
        if self.interval > 1 then
            ldbObject.text = SecondsToTime(GetReleaseTimeRemaining())
            self.interval = 0
        end
    else
        ldbObject.text = ""
        self:Hide()
    end
end)
