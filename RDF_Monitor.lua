--RDF Monitor --
--Show Lockout timer if present on LDB Display
--Show progress of getting group if  in queue
--show nothing if not in queue.

local addonName, addon = ...

if _G[addonName] ~= addon then
    _G[addonName] = addon
end
local rdfMonitor = {}
addon.rdfMonitor = rdfMonitor

local eventFrame = CreateFrame("Frame", nil, UIParent)
rdfMonitor.eventFrame = eventFrame

eventFrame:SetScript("OnEvent", function(frame, event, ...)
    if rdfMonitor[event] and type(rdfMonitor[event]) == "function" then
        rdfMonitor[event](rdfMonitor, event, ...)
    end
end)

eventFrame:RegisterEvent("LFG_UPDATE")
eventFrame:RegisterEvent("LFG_QUEUE_STATUS_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")


local ldbObject = {
    type = "data source",
    label = "RDF",
    text = "",
    icon = "237185", --"inv_jewelcrafting_dragonseye02"
    OnClick = function() rdfMonitor:LFG_UPDATE() end
}
local libLDB = LibStub:GetLibrary("LibDataBroker-1.1")
libLDB:NewDataObject("RDFQueueMonitor", ldbObject)

local colorStrings = {
    tankNeeds = {
        [0] = "|cFF80FF00T|r", --Green Found Tank
        [1] = "|cFFA0A0A0T|r", --Gray, Waiting for Tank
    },
    healerNeeds = {
        [0] = "|cFF80FF00H|r", --Green Found Healer
        [1] = "|cFFA0A0A0H|r", --Gray Wating for DPS
    },
    dpsNeeds = {
        [0] = "|cFF80FF00DDD|r",             --Green Found 3 DPS, Not Waiting for Any More
        [1] = "|cFF80FF00DD|r|cFFA0A0A0D|r", --Green Found 2 DPS, Waiting for 1 more
        [2] = "|cFF80FF00D|r|cFFA0A0A0DD|r", --Green Found 1 DPS, Waiting for 2 more
        [3] = "|cFFA0A0A0DDD|r",             --Gray - Waiting for 3 DPS
    }
}

-- Keep the frame active while a queue or cooldown needs a live timer.
function rdfMonitor:LFG_UPDATE()
    local hasData, _, tankNeeds, healerNeeds, dpsNeeds, _, _, _, _, _, _, _, _, _, _, _, queuedTime =
        GetLFGQueueStats(LE_LFG_CATEGORY_LFD)
    if hasData then
        ldbObject.text = (colorStrings.tankNeeds[tankNeeds] or "T") ..
            (colorStrings.healerNeeds[healerNeeds] or "H") ..
            (colorStrings.dpsNeeds[dpsNeeds] or "DDD") .. " -- " ..
            SecondsToTime(math.max(0, GetTime() - (queuedTime or GetTime())), true)
        eventFrame:Show()
        return
    end

    local expiration = GetLFGRandomCooldownExpiration()
    if UnitHasLFGRandomCooldown("player") and expiration and expiration > GetTime() then
        ldbObject.text = "|cFFFF0000" .. SecondsToTime(expiration - GetTime()) .. "|r"
        eventFrame:Show()
    else
        ldbObject.text = ""
        eventFrame:Hide()
    end
end

rdfMonitor.LFG_QUEUE_STATUS_UPDATE = rdfMonitor.LFG_UPDATE
rdfMonitor.PLAYER_ENTERING_WORLD = rdfMonitor.LFG_UPDATE
rdfMonitor.GROUP_ROSTER_UPDATE = rdfMonitor.LFG_UPDATE
function rdfMonitor:UNIT_AURA(_, unit)
    if unit == "player" then
        self:LFG_UPDATE()
    end
end

local timeElapsed = 0
eventFrame:SetScript("OnUpdate", function(_, elapsed)
    timeElapsed = timeElapsed + elapsed
    if timeElapsed >= 1 then
        timeElapsed = 0
        rdfMonitor:LFG_UPDATE()
    end
end)
eventFrame:Hide()
