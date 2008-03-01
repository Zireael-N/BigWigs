﻿------------------------------
--      Are you local?      --
------------------------------

local lady = BB["Lady Sacrolash"]
local lock = BB["Grand Warlock Alythess"]
local boss = BB["The Eredar Twins"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)

local db = nil
local wipe = nil

local pName = UnitName("player")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "EredarTwins",

	engage_trigger = "",
	wipe_bar = "Respawn",

	nova = "Shadow Nova",
	nova_desc = "Warn for Shadow Nova being cast.",

	conflag = "Conflagration",
	conflag_desc = "Warn for Conflagration being cast.",

	pyro = "Pyrogenics",
	pyro_desc = "Warn who gains and removes Pyrogenics.",
	pyro_gain = "%s gained Pyrogenics",
	pyro_remove = "%s removed Pyrogenics",
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = BZ["Sunwell Plateau"]
mod.enabletrigger = {lady, lock}
mod.toggleoptions = {"nova", "conflag", -1, "pyro", "bosskill"}
mod.revision = tonumber(("$Revision$"):sub(12, -3))

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Nova", 45332)
	self:AddCombatListener("SPELL_CAST_SUCCESS", "Conflag", 45333)
	self:AddCombatListener("SPELL_AURA_APPLIED", "PyroGain", 45230)
	self:AddCombatListener("SPELL_AURA_STOLEN", "PyroRemove", 45230)
	self:AddCombatListener("SPELL_AURA_REMOVED", "PyroRemove", 45230)


	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")

	--self:AddCombatListener("UNIT_DIED", "GenericBossDeath")

	db = self.db.profile
	if wipe and BigWigs:IsModuleActive(boss) then
		self:Bar(L["wipe_bar"], 90, 44670)
		wipe = nil
	end
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:Nova()
	if db.nova then
		self:Message(L["nova"], "Urgent", nil, nil, nil, 45329)
	end
end

function mod:Conflag()
	if db.conflag then
		self:Message(L["conflag"], "Attention", nil, nil, nil, 45333)
	end
end

function mod:PyroGain(unit, spellID)
	if unit == boss and db.pyro then
		self:Message(L["pyro_gain"]:format(unit), "Positive", nil, nil, nil, spellID)
		self:Bar(L["pyro"], 15, spellID)
	end
end

function mod:PyroRemove(_, _, source)
	if db.pyro then
		self:Message(L["pyro_remove"]:format(source), "Positive")
		self:TriggerEvent("BigWigs_StopBar", self, L["pyro"])
	end
end

