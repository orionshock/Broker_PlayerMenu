--luacheck: no max line length
--luacheck: globals LibStub CreateFrame LOOT LOOT_FREE_FOR_ALL LOOT_ROUND_ROBIN LOOT_NEED_BEFORE_GREED LOOT_GROUP_LOOT
--luacheck: globals DUNGEON_DIFFICULTY1 DUNGEON_DIFFICULTY2 SetLootMethod SetLootThreshold SetDungeonDifficultyID
--luacheck: globals IsShiftKeyDown ResetInstances InviteUnit C_Timer LeaveParty InviteUnit ConvertToRaid ConvertToParty
--luacheck: globals InCombatLockdown IsInRaid LOOT_METHOD LOOT_THRESHOLD ITEM_QUALITY_COLORS GetDungeonDifficultyID
--luacheck: globals IsInInstance RESET_INSTANCES GameFontNormalLeft DUNGEON_DIFFICULTY LOOT_MASTER_LOOTER
--luacheck: globals UIParent UnitClass RAID_CLASS_COLORS UnitIsGroupLeader IsInGroup GetOptOutOfLoot SetOptOutOfLoot
--luacheck: globals GetLootMethod GetLootThreshold UnitInRaid UnitInParty GetRaidRosterInfo SOLO RAID_DIFFICULTY1 RAID_DIFFICULTY2
--luacheck: globals SetRaidDifficultyID CONVERT_TO_RAID CONVERT_TO_PARTY RAID_DIFFICULTY GetRaidDifficultyID PARTY_LEAVE

--An LDB Feed to easily change loot methods and item quality
local addonName, addon = ...

if _G[addonName] ~= addon then
    _G[addonName] = addon
end

local ldblootmethod = {} --Main Object--
addon.ldblootmethod = ldblootmethod
local LibQTip = LibStub("LibQTip-1.0")
local eventFrame = CreateFrame("Frame", nil, UIParent)
ldblootmethod.eventFrame = eventFrame

--Reoccuring Elements--
local currentLootMethod, currentLootThreshold, currentMasterLooterName, myTooltip

local removeprefix = LOOT .. ": "
local loot_method_strings = {
    ["freeforall"] = LOOT_FREE_FOR_ALL:gsub(removeprefix, ""),
    ["roundrobin"] = LOOT_ROUND_ROBIN:gsub(removeprefix, ""),
    ["needbeforegreed"] = LOOT_NEED_BEFORE_GREED:gsub(removeprefix, ""),
    ["group"] = LOOT_GROUP_LOOT:gsub(removeprefix, ""),
    ["master"] = LOOT_MASTER_LOOTER:gsub(removeprefix, "")
}

local loot_method_strings_short = {
    ["freeforall"] = "FFA",
    ["roundrobin"] = "RR",
    ["needbeforegreed"] = "NB4G",
    ["group"] = "GrpLoot",
    ["master"] = "ML"
}

local loot_method_sorted = {
    "freeforall",
    "group",
    "master"
}

local groupManage_Sorted = {
    [1] = IsInGroup() and not IsInRaid() and CONVERT_TO_RAID or nil,
    [2] = IsInRaid() and CONVERT_TO_PARTY or nil,
    [3] = not IsInInstance() and RESET_INSTANCES or nil
}

local Color = {
    ["Green"] = CreateColorFromHexString("FF20FF20"),
    ["Red"] = CreateColorFromHexString("FFFF2020"),
    ["Blue"] = CreateColorFromHexString("FF0070DD")
}

local RaidOrDungeonDifficultyLevel = {
    [001] = Color.Green:WrapTextInColorCode(DUNGEON_DIFFICULTY1),
    [002] = Color.Red:WrapTextInColorCode(DUNGEON_DIFFICULTY2),
    [003] = Color.Green:WrapTextInColorCode("10 Normal"),
    [004] = Color.Green:WrapTextInColorCode("25 Normal"),
    [005] = Color.Red:WrapTextInColorCode("10 Heroic"),
    [006] = Color.Red:WrapTextInColorCode("25 Heroic"),
    [009] = "40 Player",
    [014] = "General Raid",
    [148] = "20 Player",
    [173] = Color.Green:WrapTextInColorCode(DUNGEON_DIFFICULTY1),
    [174] = Color.Red:WrapTextInColorCode(DUNGEON_DIFFICULTY2),
    [175] = Color.Green:WrapTextInColorCode(RAID_DIFFICULTY1),
    [176] = Color.Green:WrapTextInColorCode(RAID_DIFFICULTY2),
    [193] = Color.Red:WrapTextInColorCode("10 Heroic"),
    [194] = Color.Red:WrapTextInColorCode("25 Heroic")
}
local RaidOrDungeonDifficultyShortName = {
    [001] = Color.Green:WrapTextInColorCode("N"), --"N" Normal Green
    [002] = Color.Red:WrapTextInColorCode("H"), --"H" Heroic Red
    [003] = Color.Green:WrapTextInColorCode("10"), --10 Normal Green
    [004] = Color.Green:WrapTextInColorCode("25"), --25 Normal Red
    [005] = Color.Red:WrapTextInColorCode("10H"), --10 Heroic Green
    [006] = Color.Red:WrapTextInColorCode("25H"), --25 Heroic Red
    [009] = Color.Blue:WrapTextInColorCode("40"), --40 General Blue, Old World
    [014] = Color.Blue:WrapTextInColorCode("GR"), --General Raid, Blue, Old World - Just a Raid
    [148] = Color.Blue:WrapTextInColorCode("20"), --20 General Blue
    [173] = Color.Green:WrapTextInColorCode("20N"), --20 Normal Mode, Green
    [174] = Color.Red:WrapTextInColorCode("20H"), --20 Heroic Red
    [175] = Color.Green:WrapTextInColorCode("10"), --10 General Green
    [176] = Color.Red:WrapTextInColorCode("25"), --25 General Red
    [193] = Color.Green:WrapTextInColorCode("10"), --10 General Green
    [194] = Color.Red:WrapTextInColorCode("25") --25 General Red
}
--[[
    GetDungeonDifficultyID()
    --Normal => Green
    --Heroic => Red

    GetRaidDifficultyID()
    -"10" Green
    -"25" Red

    -OldWorld/20/40/General => Blue
]]
--Functions Listed in order their used.

local function tooltip_SetLootMethod(_, arg, button)
    if button == "LeftButton" then
        LibQTip:Release(myTooltip)
        myTooltip = nil
        SetLootMethod(loot_method_sorted[arg], currentMasterLooterName or "player", currentLootThreshold)
    end
end

local function tooltip_GroupManageFunc(_, arg, button)
    if button == "LeftButton" and IsShiftKeyDown() then
        if arg == 1 then
            ConvertToRaid()
        elseif arg == 2 then
            ConvertToParty()
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
        if (currentLootMethod == "master") then
            SetLootMethod("master", currentMasterLooterName or "player", arg)
        else
            SetLootThreshold(arg)
        end
    end
end

local function tooltip_SetDungeonDifficultyID(_, arg, button)
    if button == "LeftButton" then
        LibQTip:Release(myTooltip)
        myTooltip = nil
        SetDungeonDifficultyID(arg)
    end
end

local function tooltip_SetRaidDifficultyID(_, arg, button)
    if button == "LeftButton" then
        LibQTip:Release(myTooltip)
        myTooltip = nil
        SetRaidDifficultyID(arg)
    end
end

local function tooltip_ResetInstances()
    if IsShiftKeyDown() then
        ResetInstances()
    end
end

local function tooltip_LeaveParty()
    if not InCombatLockdown() and IsShiftKeyDown() then
        LeaveParty()
    end
end

local function tooltip_GhettoHearth()
    if not InCombatLockdown() then
        InviteUnit("a")
        C_Timer.After(
            1,
            function()
                LeaveParty()
            end
        )
    end
end

local function tooltip_GhettoRaid()
    if IsShiftKeyDown() then
        InviteUnit("a")
        C_Timer.After(
            1,
            function()
                ConvertToRaid()
            end
        )
    end
end

local fmt_GetFormatedInstanceType = DARKYELLOW_FONT_COLOR:WrapTextInColorCode(">> %s <<")
local function GetFormatedInstanceType(currentDungeonDifficulty, index)
    if index == currentDungeonDifficulty then
        return fmt_GetFormatedInstanceType:format(RaidOrDungeonDifficultyLevel[index])
    else
        return RaidOrDungeonDifficultyLevel[index]
    end
end

local function populateTooltip_PartyLeader(tooltip)
    tooltip:SetColumnLayout(2, "CENTER", "CENTER")

    local tipLine
    tooltip:AddHeader(LOOT_METHOD, "Manage")
    tooltip:AddSeparator()

    for i = 1, #loot_method_sorted do
        local currentLine
        if currentLootMethod == loot_method_sorted[i] then
            currentLine = tooltip:AddLine(">> " .. loot_method_strings[loot_method_sorted[i]] .. " <<", groupManage_Sorted[i])
        else
            currentLine = tooltip:AddLine(loot_method_strings[loot_method_sorted[i]], groupManage_Sorted[i])
        end
        tooltip:SetCellScript(currentLine, 1, "OnMouseUp", tooltip_SetLootMethod, i)
        if groupManage_Sorted[i] then
            tooltip:SetCellScript(currentLine, 2, "OnMouseUp", tooltip_GroupManageFunc, i)
        end
    end

    tooltip:AddSeparator(8)

    tipLine = tooltip:AddHeader(LOOT_THRESHOLD, "")
    tooltip:SetCell(tipLine, 1, LOOT_THRESHOLD, nil, "CENTER", 2)
    tooltip:SetColumnLayout(2, "CENTER", "CENTER")
    tooltip:AddSeparator()
    tooltip:AddLine("2", "4")
    tipLine = tooltip:AddLine("3", "5")
    local matrix = {
        [2] = {tipLine - 1, 1}, --2
        [3] = {tipLine, 1}, --3
        [4] = {tipLine - 1, 2}, --4
        [5] = {tipLine, 2} --5
    }

    for qualityIndex, data in pairs(matrix) do
        if data then
            if currentLootThreshold == qualityIndex then
                tooltip:SetCell(data[1], data[2], ">> " .. ITEM_QUALITY_COLORS[qualityIndex].color:WrapTextInColorCode(_G["ITEM_QUALITY" .. qualityIndex .. "_DESC"]) .. " <<")
            else
                tooltip:SetCell(data[1], data[2], ITEM_QUALITY_COLORS[qualityIndex].color:WrapTextInColorCode(_G["ITEM_QUALITY" .. qualityIndex .. "_DESC"]))
            end
            tooltip:SetCellScript(data[1], data[2], "OnMouseUp", tooltip_SetLootThreshold, qualityIndex)
        end
    end

    tooltip:AddSeparator(8)
    --Dungeon Normal/Heroic
    local currentDungeonDifficulty = GetDungeonDifficultyID()
    tipLine = tooltip:AddHeader(DUNGEON_DIFFICULTY)
    tooltip:SetCell(tipLine, 1, DUNGEON_DIFFICULTY, nil, "CENTER", 2)

    tipLine = tooltip:AddLine(GetFormatedInstanceType(currentDungeonDifficulty, 1), GetFormatedInstanceType(currentDungeonDifficulty, 2))
    tooltip:SetCellScript(tipLine, 1, "OnMouseUp", tooltip_SetDungeonDifficultyID, 1)
    tooltip:SetCellScript(tipLine, 2, "OnMouseUp", tooltip_SetDungeonDifficultyID, 2)

    --Raid Difficluty { 10N   25N }, {10H   25H}
    tooltip:AddSeparator()
    local currentRaidDifficulty = GetRaidDifficultyID()
    tipLine = tooltip:AddHeader(RAID_DIFFICULTY)
    tooltip:SetCell(tipLine, 1, DUNGEON_DIFFICULTY, nil, "CENTER", 2)
    tipLine = tooltip:AddLine(GetFormatedInstanceType(currentRaidDifficulty, 3), GetFormatedInstanceType(currentRaidDifficulty, 4))
    tooltip:SetCellScript(tipLine, 1, "OnMouseUp", tooltip_SetRaidDifficultyID, 3)
    tooltip:SetCellScript(tipLine, 2, "OnMouseUp", tooltip_SetRaidDifficultyID, 4)
    tipLine = tooltip:AddLine(GetFormatedInstanceType(currentRaidDifficulty, 5), GetFormatedInstanceType(currentRaidDifficulty, 6))
    tooltip:SetCellScript(tipLine, 1, "OnMouseUp", tooltip_SetRaidDifficultyID, 5)
    tooltip:SetCellScript(tipLine, 2, "OnMouseUp", tooltip_SetRaidDifficultyID, 6)

    tooltip:AddSeparator(8)

    local currentLine = tooltip:AddLine(1)
    tooltip:SetLineScript(currentLine, "OnMouseUp", tooltip_LeaveParty)
    tooltip:SetCell(currentLine, 1, PARTY_LEAVE, nil, "CENTER", 2)
end

local function populateTooltip_PartyMember(tooltip)
    tooltip:SetColumnLayout(2, "RIGHT", "LEFT")
    tooltip:SetColumnTextColor(1, GameFontNormalLeft:GetTextColor())
    tooltip:AddLine(DUNGEON_DIFFICULTY, RaidOrDungeonDifficultyLevel[GetDungeonDifficultyID()] or "??")
    tooltip:AddLine(RAID_DIFFICULTY, RaidOrDungeonDifficultyLevel[GetRaidDifficultyID()] or "¿¿")
    tooltip:AddSeparator()
    --currentLootMethod, currentLootThreshold, currentMasterLooterName
    tooltip:AddLine(LOOT_METHOD, loot_method_strings[currentLootMethod])
    --if masterlooter - put the ML Name here
    if (currentLootMethod == "master") and (currentMasterLooterName ~= "") then
        local _, class = UnitClass(currentMasterLooterName)
        if class then
            tooltip:AddLine("Loot Master", RAID_CLASS_COLORS[class]:WrapTextInColorCode(currentMasterLooterName))
        else
            tooltip:AddLine("Loot Master", currentMasterLooterName)
        end
    end
    tooltip:AddLine(LOOT_THRESHOLD, ITEM_QUALITY_COLORS[currentLootThreshold].color:WrapTextInColorCode(_G["ITEM_QUALITY" .. currentLootThreshold .. "_DESC"]))
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

        --Dungeon Normal/Heroic
        local currentDungeonDifficulty = GetDungeonDifficultyID()
        tipLine = tooltip:AddHeader(DUNGEON_DIFFICULTY)
        tooltip:SetCell(tipLine, 1, DUNGEON_DIFFICULTY, nil, "CENTER", 2)

        tipLine = tooltip:AddLine(GetFormatedInstanceType(currentDungeonDifficulty, 1), GetFormatedInstanceType(currentDungeonDifficulty, 2))
        tooltip:SetCellScript(tipLine, 1, "OnMouseUp", tooltip_SetDungeonDifficultyID, 1)
        tooltip:SetCellScript(tipLine, 2, "OnMouseUp", tooltip_SetDungeonDifficultyID, 2)

        --Raid Difficluty { 10N   25N }, {10H   25H}
        tooltip:AddSeparator()
        local currentRaidDifficulty = GetRaidDifficultyID()
        tipLine = tooltip:AddHeader(RAID_DIFFICULTY)
        tooltip:SetCell(tipLine, 1, DUNGEON_DIFFICULTY, nil, "CENTER", 2)
        tipLine = tooltip:AddLine(GetFormatedInstanceType(currentRaidDifficulty, 3), GetFormatedInstanceType(currentRaidDifficulty, 4))
        tooltip:SetCellScript(tipLine, 1, "OnMouseUp", tooltip_SetRaidDifficultyID, 3)
        tooltip:SetCellScript(tipLine, 2, "OnMouseUp", tooltip_SetRaidDifficultyID, 4)
        tipLine = tooltip:AddLine(GetFormatedInstanceType(currentRaidDifficulty, 5), GetFormatedInstanceType(currentRaidDifficulty, 6))
        tooltip:SetCellScript(tipLine, 1, "OnMouseUp", tooltip_SetRaidDifficultyID, 5)
        tooltip:SetCellScript(tipLine, 2, "OnMouseUp", tooltip_SetRaidDifficultyID, 6)

        tooltip:AddSeparator(8)
        --Instance Reset / Instructions
        local currentLine = tooltip:AddLine(RESET_INSTANCES, "(Shift Click alot)")
        tooltip:SetCellScript(currentLine, 1, "OnMouseUp", tooltip_ResetInstances)
        tooltip:AddSeparator(1)
        --
        currentLine = tooltip:AddLine("Leave")
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
local fmt_shortInstanceDisplay = DARKYELLOW_FONT_COLOR:WrapTextInColorCode("[%s||%s]")
local fmt_Loot_String = fmt_shortInstanceDisplay .. " %s (%s)%s" --[InstanceDifficulty-RaidDifficulty] Loot Method (LootThreshold) OptOutFlag
local fmt_Loot_ML_String = fmt_shortInstanceDisplay .. " %s: %s (%s)%s" --[InstanceDifficulty-RaidDifficulty] ML: MasterLooter_Name (LootThreshold) OptOutFlag

local function get_LDB_Text(mlName, class)
    local loot_method = loot_method_strings_short[currentLootMethod]
    local loot_threshold = ITEM_QUALITY_COLORS[currentLootThreshold].color:WrapTextInColorCode(_G["ITEM_QUALITY" .. currentLootThreshold .. "_DESC"]:sub(1, 1))
    local optOut = GetOptOutOfLoot() and "*" or ""
    local dungeonDifficultyID = GetDungeonDifficultyID()
    local raidDifficultyID = GetRaidDifficultyID()
    if mlName then
        return fmt_Loot_ML_String:format(
            RaidOrDungeonDifficultyShortName[dungeonDifficultyID] or "?",
            RaidOrDungeonDifficultyShortName[raidDifficultyID] or "¿",
            loot_method,
            RAID_CLASS_COLORS[class]:WrapTextInColorCode(mlName),
            loot_threshold,
            optOut
        )
    else
        return fmt_Loot_String:format(RaidOrDungeonDifficultyShortName[dungeonDifficultyID] or "?", RaidOrDungeonDifficultyShortName[raidDifficultyID] or "¿", loot_method, loot_threshold, optOut)
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
        currentLootMethod = GetLootMethod() or "group"
        currentLootThreshold = GetLootThreshold() or "2"

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
            if not (UnitInRaid(currentMasterLooterName) or UnitInParty(currentMasterLooterName)) then
                currentMasterLooterName = nil
            end

            if currentLootMethod == "master" then
                for i = 1, 40 do
                    local name, _, _, _, _, class, _, _, _, _, isML = GetRaidRosterInfo(i)
                    if isML and name then
                        ldbObject.text = get_LDB_Text(name, class)
                        currentMasterLooterName = name
                    end
                end
            else
                ldbObject.text = get_LDB_Text()
            end
            if myTooltip and myTooltip:IsShown() then
                LibQTip:Release(myTooltip)
                myTooltip = nil
            end
        else
            ldbObject.text = get_LDB_Text() --SOLO .. (GetOptOutOfLoot() and "*" or "")
        end
    end
)

ldbObject.OnClick = eventFrame:GetScript("OnEvent")

local timeElapsed = 0
eventFrame:SetScript(
    "OnUpdate",
    function(self, elapsed)
        timeElapsed = timeElapsed + elapsed
        if timeElapsed > 1 then
            timeElapsed = 0
            local bootTime = GetInstanceBootTimeRemaining()
            if bootTime == 0 then
                self:Hide()
            else
                ldbObject.text = string.format("Boot: %s", bootTime)
            end
        end
    end
)
