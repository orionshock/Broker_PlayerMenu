local addonName, addon = ...

if _G[addonName] ~= addon then
    _G[addonName] = addon
end
local ldbPVPToggle = {}
addon.ldbPVPToggle = ldbPVPToggle

local eventFrame = CreateFrame("Frame", nil, UIParent)
ldbPVPToggle.eventFrame = eventFrame

local PVP_ICON_HORDE = "132485"
local PVP_ICON_ALLIANCE = "132486"
local PVP_ICON_OFF = "132487"

local PVP_NO = PVP .. " " .. NO
local PVP_YES = PVP .. " " .. YES

local function GetFormattedPVPTimer()
    local timeLeft = (GetPVPTimer() / 1000)
    return string.format("%d:%02d", timeLeft / 60, timeLeft % 60)
end

local function ldbPVPToggle_OnClick(frame, button)
    if not IsShiftKeyDown() then
        eventFrame:GetScript("OnEvent")(eventFrame)
        return
    end
    if button == "LeftButton" then
        if not InCombatLockdown() then
            TogglePVP()
        end
    elseif button == "RightButton" then
        if IsPVPTimerRunning() then
            local msg = string.format("PvP flag off - Time Left: %s", GetFormattedPVPTimer())
            if IsInRaid(LE_PARTY_CATEGORY_INSTANCE) then   --Instance Raid
                SendChatMessage(msg, "INSTANCE_CHAT")
            elseif IsInRaid(LE_PARTY_CATEGORY_HOME) then   --Home Raid
                SendChatMessage(msg, "RAID")
            elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then --Instance Party
                SendChatMessage(msg, "PARTY")
            elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then --Home Party
                SendChatMessage(msg, "INSTANCE_CHAT")
            else
                print(msg)
            end
        end
    end
end

local function ldbPVPToggle_OnTooltipShow(tooltip)
    local pvpDesired = GetPVPDesired() and "|cFF00FF00Yes|r" or "|cFFFF0000No|r"
    local flaggedState = (UnitIsPVPFreeForAll("player") and "|cFF00FF00FFA|r") or
        (UnitIsPVP("player") and "|cFF00FF00PVP Flaged|r") or ("|cFFFF0000Not Flaged|r")

    if IsPVPTimerRunning() then
        local timeLeft = (GetPVPTimer() / 1000)
        pvpDesired = string.format("%s - %s", pvpDesired, GetFormattedPVPTimer())
    end
    tooltip:AddDoubleLine("PvP Desired:", pvpDesired)
    tooltip:AddDoubleLine("Flagged State:", flaggedState)
    tooltip:AddLine("")
    tooltip:AddLine("Click to Force Update")
    tooltip:AddLine("Shift-Left Click to Toggle PvP")
    tooltip:AddLine("Shift-Right Click to Announce Timer")
end

local ldbObject = {
    type = "data source",
    label = "PVP Toggle",
    icon = PVP_ICON_OFF,
    OnClick = ldbPVPToggle_OnClick,
    OnTooltipShow = ldbPVPToggle_OnTooltipShow
}

local libLDB = LibStub:GetLibrary("LibDataBroker-1.1")
libLDB:NewDataObject("PVPToggle", ldbObject)

eventFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UPDATE_UI_WIDGET")
eventFrame:RegisterEvent("ZONE_CHANGED")
eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript(
    "OnEvent",
    function(frame, event, ...)
        frame:Hide()
        ldbObject.text = ""

        --Icon always Indicates if your Flagged currently
        if UnitIsPVPFreeForAll("player") then
            ldbObject.icon = 132482
        elseif UnitIsPVP("player") then
            if (UnitFactionGroup("player")) == "Horde" then --If flagged then show the factoin emblem
                ldbObject.icon = 132485
            else
                ldbObject.icon = 132486
            end
        else
            ldbObject.icon = 132487 --Else if not flagged or FFA'ed then show a blank banner.
        end

        --Label indicates if PVP is desired ON or OFF
        if GetPVPDesired() then
            ldbObject.label = PVP_YES
        else
            ldbObject.label = PVP_NO
        end

        --Value only shows if there is a timer going or infinity otherwise.
        if IsPVPTimerRunning() then
            frame:Show()
        else
            frame:Hide()
            ldbObject.text = "∞"
        end
    end
)

eventFrame:SetScript(
    "OnUpdate",
    function(frame, event, elapsed)
        ldbObject.text = GetFormattedPVPTimer()
    end
)
