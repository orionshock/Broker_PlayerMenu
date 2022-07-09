--An LDB Feed to easily change loot methods and item quality
local ldblootmethod = {} --Main Object--
local LibQTip = LibStub("LibQTip-1.0")
local eventFrame = CreateFrame("Frame", nil, UIParent)

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

local loot_method_sorted = {"freeforall", "roundrobin", "master", "group", "needbeforegreed"}

local Dungeon_Difficulty_Level = {DUNGEON_DIFFICULTY1, DUNGEON_DIFFICULTY2}
local Dungeon_Difficulty_Short_Name = {"|cff20ff20N|r", "|cffff2020H|r"}

local function tooltip_SetLootMethod(frame, arg, button)
    if button == "LeftButton" then
        LibQTip:Release(myTooltip)
        myTooltip = nil
        SetLootMethod(loot_method_sorted[arg], currentMasterLooterName or "player", currentLootThreshold)
    end
end

local function tooltip_SetLootThreshold(frame, arg, button)
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

local function tooltip_SetDungeonDifficultyID(frame, arg, button)
    if button == "LeftButton" then
        LibQTip:Release(myTooltip)
        myTooltip = nil
        SetDungeonDifficultyID(arg)
    end
end

local function tooltip_ResetInstances(frame, arg, button)
    if IsShiftKeyDown() then
        LibQTip:Release(myTooltip)
        myTooltip = nil
        ResetInstances()
    end
end

local function tooltip_GhettoHearth(frame, arg, button)
    if not InCombatLockdown() then
        InviteUnit("a")
        C_Timer.After(1, LeaveParty)
    end
end

local function tooltip_GhettoRaid(frame, arg, button)
    if IsShiftKeyDown() then
        InviteUnit("a")
        C_Timer.After(1, ConvertToRaid)
    end
end
local function tooltip_ToRaid(frame, arg, button)
    if IsShiftKeyDown() then
        ConvertToRaid()
    end
end

local function tooltip_ToParty(frame, arg, button)
    if IsShiftKeyDown() then
        ConvertToParty()
    end
end

local function tooltip_LeaveParty(frame, arg, button)
    if not InCombatLockdown() and IsShiftKeyDown() then
        LeaveParty()
    end
end

local function populateTooltip_PartyLeader(tooltip)
    if IsInRaid() then
        local currentLine = tooltip:AddLine("Convert To Party (Shift-Click)")
        tooltip:SetLineScript(currentLine, "OnMouseUp", tooltip_ToParty)
        tooltip:AddSeparator(8)
    else
        local currentLine = tooltip:AddLine("Convert To Raid (Shift-Click)")
        tooltip:SetLineScript(currentLine, "OnMouseUp", tooltip_ToRaid)
        tooltip:AddSeparator(8)
    end

    tooltip:AddHeader(LOOT_METHOD)
    tooltip:AddSeparator()
    for i = 1, #loot_method_sorted do
        local currentLine
        if currentLootMethod == loot_method_sorted[i] then
            currentLine = tooltip:AddLine(">> " .. loot_method_strings[loot_method_sorted[i]] .. " <<")
        else
            currentLine = tooltip:AddLine(loot_method_strings[loot_method_sorted[i]])
        end
        tooltip:SetLineScript(currentLine, "OnMouseUp", tooltip_SetLootMethod, i)
    end
    tooltip:AddSeparator(8)
    tooltip:AddHeader(LOOT_THRESHOLD)
    tooltip:AddSeparator()
    local startQuality, maxQuality = 0, 8
    if currentLootMethod ~= "master" then
        startQuality = 2
        maxQuality = 6
    end
    for qualityIndex = startQuality, maxQuality do
        local currentLine
        if currentLootThreshold == qualityIndex then
            currentLine = tooltip:AddLine(">> " .. ITEM_QUALITY_COLORS[qualityIndex].color:WrapTextInColorCode(_G["ITEM_QUALITY" .. qualityIndex .. "_DESC"]) .. " <<")
        else
            currentLine = tooltip:AddLine(ITEM_QUALITY_COLORS[qualityIndex].color:WrapTextInColorCode(_G["ITEM_QUALITY" .. qualityIndex .. "_DESC"]))
        end
        tooltip:SetLineScript(currentLine, "OnMouseUp", tooltip_SetLootThreshold, qualityIndex)
    end
    tooltip:AddSeparator(8)
    tooltip:AddHeader(DUNGEON_DIFFICULTY)
    tooltip:AddSeparator()
    local currentDungeonDifficulty = GetDungeonDifficultyID()
    for index = 1, #Dungeon_Difficulty_Level do
        local currentLine
        if index == currentDungeonDifficulty then
            currentLine = tooltip:AddLine(">> " .. Dungeon_Difficulty_Level[index] .. " <<")
        else
            currentLine = tooltip:AddLine(Dungeon_Difficulty_Level[index])
        end
        tooltip:SetLineScript(currentLine, "OnMouseUp", tooltip_SetDungeonDifficultyID, index)
    end
    tooltip:AddSeparator(4)
    local inInstance, instanceType = IsInInstance()
    if not inInstance then
        local currentLine = tooltip:AddLine(RESET_INSTANCES .. " (Shift Click)")
        tooltip:SetLineScript(currentLine, "OnMouseUp", tooltip_ResetInstances)
    end
    local currentLine = tooltip:AddLine("Leave Party (Shift Click)")
    tooltip:SetLineScript(currentLine, "OnMouseUp", tooltip_LeaveParty)
end

local function populateTooltip_PartyMember(tooltip)
    tooltip:SetColumnLayout(2, "RIGHT", "LEFT")
    tooltip:SetColumnTextColor(1, GameFontNormalLeft:GetTextColor())
    tooltip:AddLine(DUNGEON_DIFFICULTY, Dungeon_Difficulty_Level[GetDungeonDifficultyID()])
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
end

local function populateTooltip_Solo(tooltip)
    local inInstance, instanceType = IsInInstance()
    if not inInstance then --Solo and Outside of an instance
        --
        tooltip:AddHeader(DUNGEON_DIFFICULTY)
        tooltip:AddSeparator()
        local currentDungeonDifficulty = GetDungeonDifficultyID()
        for index = 1, #Dungeon_Difficulty_Level do
            local currentLine
            if index == currentDungeonDifficulty then
                currentLine = tooltip:AddLine(">> " .. Dungeon_Difficulty_Level[index] .. " <<")
            else
                currentLine = tooltip:AddLine(Dungeon_Difficulty_Level[index])
            end
            tooltip:SetLineScript(currentLine, "OnMouseUp", tooltip_SetDungeonDifficultyID, index)
        end
        tooltip:AddSeparator(8)
        --Instance Reset
        local currentLine = tooltip:AddLine(RESET_INSTANCES .. " (Shift Click)")
        tooltip:SetLineScript(currentLine, "OnMouseUp", tooltip_ResetInstances)
        tooltip:AddSeparator(2)
        --Ghetto Raid
        local currentLine = tooltip:AddLine("Ghetto Raid (Shift-Click)")
        tooltip:SetLineScript(currentLine, "OnMouseUp", tooltip_GhettoRaid)
        tooltip:AddSeparator(2)
        --
        local currentLine = tooltip:AddLine("Leave Party (Shift Click)")
        tooltip:SetLineScript(currentLine, "OnMouseUp", tooltip_LeaveParty)
    else --Solo and inside the instance -- so ghetto hearth option.
        local currentLine = tooltip:AddLine("Ghetto Hearth")
        tooltip:SetLineScript(currentLine, "OnMouseUp", tooltip_GhettoHearth)
    end
end

local function LootMethod_OnLeave(self)
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

local fmt_Loot_String = "[%s] %s (%s)%s" --[InstanceDifficulty] Loot Method (LootThreshold) OptOutFlag
local fmt_Loot_ML_String = "[%s] %s: %s (%s)%s" --[InstanceDifficulty] ML: MasterLooter_Name (LootThreshold) OptOutFlag

local function get_LDB_Text(mlName, class)
    local loot_method = loot_method_strings_short[currentLootMethod]
    local loot_threshold = ITEM_QUALITY_COLORS[currentLootThreshold].color:WrapTextInColorCode(_G["ITEM_QUALITY" .. currentLootThreshold .. "_DESC"]:sub(1, 1))
    local optOut = GetOptOutOfLoot() and "*" or ""
    local difficultyID = GetDungeonDifficultyID()
    if mlName then
        return fmt_Loot_ML_String:format(Dungeon_Difficulty_Short_Name[difficultyID] or "?", loot_method, RAID_CLASS_COLORS[class]:WrapTextInColorCode(mlName), loot_threshold, optOut)
    else
        return fmt_Loot_String:format(Dungeon_Difficulty_Short_Name[difficultyID] or "?", loot_method, loot_threshold, optOut)
    end
end

local ldbObject = {
    type = "data source",
    --	text = get_LDB_Text(),
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

eventFrame:SetScript(
    "OnEvent",
    function(self, event, ...)
        if event == "RightButton" then
            SetOptOutOfLoot(not GetOptOutOfLoot())
        end
        if IsInRaid() or IsInGroup() then
            currentLootMethod = GetLootMethod() or "group"
            currentLootThreshold = GetLootThreshold() or "2"
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
            ldbObject.text = SOLO .. (GetOptOutOfLoot() and "*" or "")
        end
    end
)

ldbObject.OnClick = eventFrame:GetScript("OnEvent")
