local addonName, addon = ...

-- WoW Forever uses the enum-based C_PartyInfo loot API.
local ldblootmethod = {}
addon.ldblootmethod = ldblootmethod
local LibQTip = LibStub("LibQTip-1.0")
local eventFrame = CreateFrame("Frame", nil, UIParent)
ldblootmethod.eventFrame = eventFrame

local currentLootMethod, currentLootThreshold, currentMasterLooterName, myTooltip

local removeprefix = LOOT .. ": "
local loot_method_strings = {
    [Enum.LootMethod.Freeforall] = LOOT_FREE_FOR_ALL:gsub(removeprefix, ""),
    [Enum.LootMethod.Roundrobin] = LOOT_ROUND_ROBIN:gsub(removeprefix, ""),
    [Enum.LootMethod.Needbeforegreed] = LOOT_NEED_BEFORE_GREED:gsub(removeprefix, ""),
    [Enum.LootMethod.Group] = LOOT_GROUP_LOOT:gsub(removeprefix, ""),
    [Enum.LootMethod.Masterlooter] = LOOT_MASTER_LOOTER:gsub(removeprefix, ""),
    [Enum.LootMethod.Personal] = DEFAULT
}

local loot_method_strings_short = {
    [Enum.LootMethod.Freeforall] = "FFA",
    [Enum.LootMethod.Roundrobin] = "RR",
    [Enum.LootMethod.Needbeforegreed] = "NB4G",
    [Enum.LootMethod.Group] = "GrpLoot",
    [Enum.LootMethod.Masterlooter] = "ML",
    [Enum.LootMethod.Personal] = "Personal"
}

local loot_method_sorted = {
    Enum.LootMethod.Freeforall,
    Enum.LootMethod.Roundrobin,
    Enum.LootMethod.Masterlooter,
    Enum.LootMethod.Group,
    Enum.LootMethod.Needbeforegreed,
    Enum.LootMethod.Personal,
}

local function tooltip_SetLootMethod(_, arg, button)
    if button == "LeftButton" then
        LibQTip:Release(myTooltip)
        myTooltip = nil
        if C_PartyInfo.IsLootMethodAvailable(arg) then
            local lootMaster = arg == Enum.LootMethod.Masterlooter
                and (currentMasterLooterName or GetUnitName("player", true)) or nil
            C_PartyInfo.SetLootMethod(arg, lootMaster)
        end
    end
end

local function tooltip_GroupManageFunc(_, arg, button)
    if button == "LeftButton" and IsShiftKeyDown() then
        if arg == 1 then
            C_PartyInfo.ConvertToRaid()
        elseif arg == 2 then
            C_PartyInfo.ConvertToParty()
        elseif arg == 3 then
            ResetInstances()
        end
        LibQTip:Release(myTooltip)
        myTooltip = nil
    end
end

local function tooltip_SetLootThreshold(_, arg, button)
    if button == "LeftButton" then
        LibQTip:Release(myTooltip)
        myTooltip = nil
        SetLootThreshold(arg)
    end
end

local function tooltip_ResetInstances()
    if IsShiftKeyDown() then
        ResetInstances()
    end
end

local function tooltip_LeaveParty()
    if not InCombatLockdown() and IsShiftKeyDown() then
        C_PartyInfo.LeaveParty()
    end
end

local function tooltip_GhettoHearth()
    if not InCombatLockdown() then
        C_PartyInfo.InviteUnit("a")
        C_Timer.After(
            1,
            function()
                C_PartyInfo.LeaveParty()
            end
        )
    end
end

local function tooltip_GhettoRaid()
    if IsShiftKeyDown() then
        C_PartyInfo.InviteUnit("a")
        C_Timer.After(
            1,
            function()
                C_PartyInfo.ConvertToRaid()
            end
        )
    end
end

local function populateTooltip_PartyLeader(tooltip)
    tooltip:SetColumnLayout(2, "CENTER", "CENTER")

    local tipLine
    tooltip:AddHeader(LOOT_METHOD, "Manage")
    tooltip:AddSeparator()

    local groupManage_Sorted = {
        [1] = IsInGroup() and not IsInRaid() and CONVERT_TO_RAID or nil,
        [2] = IsInRaid() and CONVERT_TO_PARTY or nil,
        [3] = not IsInInstance() and RESET_INSTANCES or nil
    }

    local availableMethods = {}
    for _, method in ipairs(loot_method_sorted) do
        if C_PartyInfo.IsLootMethodAvailable(method) then
            availableMethods[#availableMethods + 1] = method
        end
    end
    for i = 1, math.max(#availableMethods, 3) do
        local ev = availableMethods[i]
        local display = loot_method_strings[ev] or ""
        local currentLine
        if currentLootMethod == ev then
            currentLine = tooltip:AddLine(">> " .. display .. " <<", groupManage_Sorted[i])
        else
            currentLine = tooltip:AddLine(display, groupManage_Sorted[i])
        end
        if ev then
            tooltip:SetCellScript(currentLine, 1, "OnMouseUp", tooltip_SetLootMethod, ev)
        end
        if groupManage_Sorted[i] then
            tooltip:SetCellScript(currentLine, 2, "OnMouseUp", tooltip_GroupManageFunc, i)
        end
    end

    if currentLootMethod ~= Enum.LootMethod.Personal
        and C_PartyInfo.IsLootMethodAvailable(currentLootMethod) then
        tooltip:AddSeparator(8)

        tipLine = tooltip:AddHeader(LOOT_THRESHOLD, "")
        tooltip:SetCell(tipLine, 1, LOOT_THRESHOLD, nil, "CENTER", 2)
        tooltip:SetColumnLayout(2, "CENTER", "CENTER")
        tooltip:AddSeparator()
        tooltip:AddLine("2", "4")
        tipLine = tooltip:AddLine("3", "5")
        local matrix = {
            [2] = { tipLine - 1, 1 }, --2
            [3] = { tipLine, 1 },     --3
            [4] = { tipLine - 1, 2 }, --4
            [5] = { tipLine, 2 }      --5
        }

        for qualityIndex, data in pairs(matrix) do
            if data then
                if currentLootThreshold == qualityIndex then
                    tooltip:SetCell(data[1], data[2],
                        ">> " ..
                        ITEM_QUALITY_COLORS[qualityIndex].color:WrapTextInColorCode(_G
                            ["ITEM_QUALITY" .. qualityIndex .. "_DESC"]) .. " <<")
                else
                    tooltip:SetCell(data[1], data[2],
                        ITEM_QUALITY_COLORS[qualityIndex].color:WrapTextInColorCode(_G
                            ["ITEM_QUALITY" .. qualityIndex .. "_DESC"]))
                end
                tooltip:SetCellScript(data[1], data[2], "OnMouseUp", tooltip_SetLootThreshold, qualityIndex)
            end
        end
    end

    tooltip:AddSeparator(8)

    local currentLine = tooltip:AddLine(1)
    tooltip:SetLineScript(currentLine, "OnMouseUp", tooltip_LeaveParty)
    tooltip:SetCell(currentLine, 1, PARTY_LEAVE, nil, "CENTER", 2)
end

local function populateTooltip_PartyMember(tooltip)
    tooltip:SetColumnLayout(2, "RIGHT", "LEFT")
    tooltip:SetColumnTextColor(1, GameFontNormalLeft:GetTextColor())

    --currentLootMethod, currentLootThreshold, currentMasterLooterName
    tooltip:AddLine(LOOT_METHOD, loot_method_strings[currentLootMethod] or "?")
    --if masterlooter - put the ML Name here
    if currentLootMethod == Enum.LootMethod.Masterlooter and currentMasterLooterName then
        local _, class = UnitClass(currentMasterLooterName)
        if class then
            tooltip:AddLine("Loot Master", RAID_CLASS_COLORS[class]:WrapTextInColorCode(currentMasterLooterName))
        else
            tooltip:AddLine("Loot Master", currentMasterLooterName)
        end
    end
    tooltip:AddLine(LOOT_THRESHOLD,
        ITEM_QUALITY_COLORS[currentLootThreshold].color:WrapTextInColorCode(_G
            ["ITEM_QUALITY" .. currentLootThreshold .. "_DESC"]))
    --
    tooltip:AddSeparator()
    local currentLine = tooltip:AddLine("Leave Party", "(Shift Click)")
    tooltip:SetLineScript(currentLine, "OnMouseUp", tooltip_LeaveParty)
    tooltip:SetCell(currentLine, 1, PARTY_LEAVE, nil, "CENTER", 2)
end

local function populateTooltip_Solo(tooltip)
    tooltip:SetColumnLayout(2, "CENTER", "CENTER")

    local inInstance = IsInInstance()
    if not inInstance then --Solo and Outside of an instance
        local tipLine = tooltip:AddLine("Ghetto Hearth", "Ghetto Raid")
        tooltip:SetCellScript(tipLine, 1, "OnMouseUp", tooltip_GhettoHearth)
        tooltip:SetCellScript(tipLine, 2, "OnMouseUp", tooltip_GhettoRaid)
        tooltip:AddSeparator(4)


        --Instance Reset / Instructions
        local currentLine = tooltip:AddLine(RESET_INSTANCES, "(Shift Click alot)")
        tooltip:SetCellScript(currentLine, 1, "OnMouseUp", tooltip_ResetInstances)
        tooltip:AddSeparator(1)
        --
        currentLine = tooltip:AddLine(PARTY_LEAVE)
        tooltip:SetCell(currentLine, 1, PARTY_LEAVE, nil, "CENTER", 2)
        tooltip:SetLineScript(currentLine, "OnMouseUp", tooltip_LeaveParty)
    else --Solo and inside the instance -- so ghetto hearth option.
        local currentLine = tooltip:AddLine("Ghetto Hearth")
        tooltip:SetLineScript(currentLine, "OnMouseUp", tooltip_GhettoHearth)
    end
end

local function LootMethod_OnLeave()
    LibQTip:Release(myTooltip)
    myTooltip = nil
end

local function LootMethod_OnEnter(self)
    if myTooltip and myTooltip:IsShown() then
        return
    end
    local tooltip = LibQTip:Acquire("LDBLootMethod", 1, "CENTER")
    if not tooltip then
        return
    end
    myTooltip = tooltip
    if UnitIsGroupLeader("player") then
        populateTooltip_PartyLeader(tooltip)
    elseif not IsInGroup() then
        populateTooltip_Solo(tooltip)
    else
        populateTooltip_PartyMember(tooltip)
    end

    tooltip:SetAutoHideDelay(.01, self, LootMethod_OnLeave)
    tooltip:SmartAnchorTo(self)
    tooltip:Show()
end
local function get_LDB_Text(mlName, class)
    local loot_method = loot_method_strings_short[currentLootMethod] or "?"
    local loot_threshold = ITEM_QUALITY_COLORS[currentLootThreshold].color:WrapTextInColorCode(_G
        ["ITEM_QUALITY" .. currentLootThreshold .. "_DESC"]:sub(1, 1))
    local optOut = GetOptOutOfLoot() and "*" or ""
    if mlName then
        local masterLooterText = mlName
        if class and RAID_CLASS_COLORS[class] then
            masterLooterText = RAID_CLASS_COLORS[class]:WrapTextInColorCode(mlName)
        end
        return string.format("%s: %s (%s)%s",
            loot_method,
            masterLooterText,
            loot_threshold,
            optOut
        )
    else
        return string.format("%s (%s)%s", loot_method, loot_threshold, optOut)
    end
end

local ldbObject = {
    type = "data source",
    label = "LootMethod",
    icon = "133785", --"inv_misc_coin_02"
    OnEnter = LootMethod_OnEnter
}

local libLDB = LibStub:GetLibrary("LibDataBroker-1.1")
libLDB:NewDataObject("LootMethod", ldbObject)

eventFrame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("GROUP_JOINED")
eventFrame:RegisterEvent("GROUP_LEFT")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")

eventFrame:RegisterEvent("INSTANCE_BOOT_START")
eventFrame:RegisterEvent("INSTANCE_BOOT_STOP")

eventFrame:SetScript(
    "OnEvent",
    function(self, event)
        currentLootMethod = C_PartyInfo.GetLootMethod()
        currentLootThreshold = GetLootThreshold() or 2

        if event == "RightButton" then
            SetOptOutOfLoot(not GetOptOutOfLoot())
        end
        if (event == "INSTANCE_BOOT_START") then
            self:Show()
            return
        elseif (event == "INSTANCE_BOOT_STOP") then
            self:Hide()
        end
        if IsInRaid() or IsInGroup() then
            if currentMasterLooterName and not (UnitInRaid(currentMasterLooterName) or UnitInParty(currentMasterLooterName)) then
                currentMasterLooterName = nil
            end

            if currentLootMethod == Enum.LootMethod.Masterlooter then
                local _, partyID, raidID = C_PartyInfo.GetLootMethod()
                local unit = raidID and ("raid" .. raidID)
                    or (partyID == 0 and "player")
                    or (partyID and ("party" .. partyID))
                currentMasterLooterName = unit and GetUnitName(unit, true) or nil
                local _, class = UnitClass(unit or "player")
                ldbObject.text = get_LDB_Text(currentMasterLooterName, class)
            else
                ldbObject.text = get_LDB_Text()
            end
            if myTooltip and myTooltip:IsShown() then
                LibQTip:Release(myTooltip)
                myTooltip = nil
            end
        else
            ldbObject.text = SOLO .. (GetOptOutOfLoot() and "*" or "")
        end
    end
)

ldbObject.OnClick = function(_, button)
    eventFrame:GetScript("OnEvent")(eventFrame, button)
end
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:Hide()

local timeElapsed = 0
eventFrame:SetScript(
    "OnUpdate",
    function(self, elapsed)
        timeElapsed = timeElapsed + elapsed
        if timeElapsed > 1 then
            timeElapsed = 0
            local bootTime = GetInstanceBootTimeRemaining()
            if not bootTime or bootTime <= 0 then
                self:Hide()
                self:GetScript("OnEvent")(self, "INSTANCE_BOOT_STOP")
            else
                ldbObject.text = string.format("Boot: %s", bootTime)
            end
        end
    end
)
