--RDF Monitor --
--Show Lockout timer if present on LDB Display
--Show progress of getting group if  in queue
--show nothing if not in queue.

--[[
    GetLFGDeserterExpiration()
    GetLFGRandomCooldownExpiration()
    SecondsToTime(ceil(GetLFGRandomCooldownExpiration() - GetTime()))
C_LFGList.HasActiveEntryInfo()

GetLFGQueueStats(category)

]]

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
}
local libLDB = LibStub:GetLibrary("LibDataBroker-1.1")
libLDB:NewDataObject("RDFQueueMonitor", ldbObject)

local colorStrings = {
    tankNeeds = {
        [0] = "|c0080FF00T|r", --Green Found Tank
        [1] = "|c00A0A0A0T|r", --Gray, Waiting for Tank
    },
    healerNeeds = {
        [0] = "|c0080FF00H|r", --Green Found Healer
        [1] = "|c00A0A0A0H|r", --Gray Wating for DPS
    },
    dpsNeeds = {
        [0] = "|c0080FF00DDD|r",             --Green Found 3 DPS, Not Waiting for Any More
        [1] = "|c0080FF00DD|r|c00A0A0A0D|r", --Green Found 2 DPS, Waiting for 1 more
        [2] = "|c0080FF00D|r|c00A0A0A0DD|r", --Green Found 1 DPS, Waiting for 2 more
        [3] = "|c00A0A0A0DDD|r",             --Gray - Waiting for 3 DPS
    }
}

function rdfMonitor:LFG_UPDATE(event, ...)
    local hasData, leaderNeeds, tankNeeds, healerNeeds, dpsNeeds, _, _, _, _, _, _, _, _, _, _, _, queuedTime =
        GetLFGQueueStats(1)
    if hasData then --we're in a queue
        local fmted_TimeInQueue = SecondsToTime(GetTime() - queuedTime, true)
        ldbObject.text          = (colorStrings.tankNeeds[tankNeeds]) ..
            (colorStrings.healerNeeds[healerNeeds]) .. (colorStrings.dpsNeeds[dpsNeeds]) .. " -- " .. fmted_TimeInQueue
    else
        ldbObject.text = ""
    end
end

rdfMonitor.LFG_QUEUE_STATUS_UPDATE = rdfMonitor.LFG_UPDATE

local function HasCoolDownCheck(self, event, ...)
    if UnitHasLFGRandomCooldown("player") and GetLFGRandomCooldownExpiration() then
        eventFrame:Show()
    else
        eventFrame:Hide()
    end
end

local interval, timeElapsed = 1, 0
eventFrame:SetScript("OnUpdate", function(self, elapsed)
    timeElapsed = timeElapsed + elapsed
    if elapsed > interval then
        timeElapsed = 0
        if UnitHasLFGRandomCooldown("player") and GetLFGRandomCooldownExpiration() then
            ldbObject.text = "|cFFFF0000" .. SecondsToTime(GetLFGRandomCooldownExpiration() - GetTime()) .. "|r"
        else
            self:Hide()
            rdfMonitor:LFG_UPDATE()
        end
    end
end)


rdfMonitor.PLAYER_ENTERING_WORLD = HasCoolDownCheck
rdfMonitor.UNIT_AURA = HasCoolDownCheck
rdfMonitor.GROUP_ROSTER_UPDATE = HasCoolDownCheck
