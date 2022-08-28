local addonName, addon = ...

if _G[addonName] ~= addon then
    _G[addonName] = addon
end
local rezOptions = {}
addon.rezOptions = rezOptions

local eventFrame = CreateFrame("Frame", nil, UIParent)
rezOptions.eventFrame = eventFrame
local LibQTip = LibStub("LibQTip-1.0")
local myTooltip
---states to keep track of
local corpseInRange = false
local playerDeadInCorpse = false
---

function populateTooltip_RetrieveCorpse(tooltip)
    local currentLine = tooltip:AddLine(RECOVER_CORPSE)
    tooltip:SetLineScript(currentLine, "OnMouseUp", RetrieveCorpse)
end

local function DoSelfRez(frame, info, button)
    if info then
        C_DeathInfo.UseSelfResurrectOption(info.optionType, info.id)
    end
end

function populateTooltip_SelfRez(tooltip)
    local selfRezOptions = C_DeathInfo.GetSelfResurrectOptions()
    for i = 1, #selfRezOptions do
        local info = selfRezOptions[i]
        local currentLine = tooltip:AddLine(info.name)
        tooltip:SetLineScript(currentLine, "OnMouseUp", DoSelfRez, info)
    end
end

function populateTooltip_PlayerIsDead(tooltip)
    local currentLine = tooltip:AddLine(DEATH_RELEASE)
    tooltip:SetLineScript(currentLine, "OnMouseUp", RepopMe)
end

local function RezOptions_OnLeave(self)
    LibQTip:Release(myTooltip)
    myTooltip = nil
end

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
    if corpseInRange then
        showingTooltip = true
        populateTooltip_RetrieveCorpse(tooltip)
    end
    if C_DeathInfo.GetSelfResurrectOptions() then
        showingtooltip = true
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
    --	text = get_LDB_Text(),
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


function rezOptions:CORPSE_IN_RANGE(event)
    corpseInRange = true
end
function rezOptions:CORPSE_OUT_OF_RANGE(event)
    corpseInRange = false
end
function rezOptions:PLAYER_DEAD(event)

end