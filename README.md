# Broker_PlayerMenu

Small LibDataBroker plugins for World of Warcraft Forever (interface 16001). Requires a broker display such as Bazooka to show the plugins. Libraries are included.

The default branch, `forever`, targets WoW Forever. The previous `main` branch is now named `MoP`.

- **LootMethod:** Shows loot method, loot threshold, and the master looter. Hover for available loot controls, group conversion, instance reset, and leaving your group. Group management depends on your leader permissions. Right-click toggles opting out of loot; Shift-click the reset, conversion, or leave controls to use them.
- **PVPToggle:** Shows your PvP flag, desired state, and remaining unflag timer. Type `/pvp` in chat to toggle PvP. Shift-right-click announces an active timer to your instance group, raid, party, or local chat output when solo. Click without Shift to refresh the display.
- **RezOptions:** Offers resurrection acceptance, corpse retrieval when in range, available self-resurrection options, and spirit release. Shows the release countdown while dead.

Solo loot controls also include the legacy "Ghetto Hearth" and "Ghetto Raid" helpers, which attempt an invite followed by leaving or converting the group. Their availability depends on the game's group rules; Shift-click the raid helper.
