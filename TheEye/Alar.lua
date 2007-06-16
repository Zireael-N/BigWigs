﻿------------------------------
--      Are you local?      --
------------------------------

local boss = AceLibrary("Babble-Boss-2.2")["Al'ar"]
local L = AceLibrary("AceLocale-2.2"):new("BigWigs"..boss)
local L2 = AceLibrary("AceLocale-2.2"):new("BigWigsCommonWords")

local started = nil
local prior = nil
local fireball = nil
local occured = true

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function() return {
	cmd = "Alar",

	engage_message = "%s engaged - Phase 1",

	meteor = "Meteor",
	meteor_desc = "Estimated Meteor Timers.",
	meteor_warning = "Possible Meteor in ~5sec",
	meteor_message = "Meteor! Next in ~54sec",
	meteor_nextbar = "Next Meteor",

	flamepatch = "Flame Patch on You",
	flamepatch_desc = "Warn for a Flame Patch on You.",
	flamepatch_trigger = "You are afflicted by Flame Patch.",
	flamepatch_message = "Flame Patch on YOU!",

	armor = "Melt Armor",
	armor_desc = "Warn who gets Melt Armor.",
	armor_trigger = "^([^%s]+) ([^%s]+) afflicted by Melt Armor.$",
	armor_other = "Melt Armor: %s",
	armor_you = "Melt Amor on YOU!",

	icon = "Raid Icon",
	icon_desc = "Place a Raid Icon on the player with Melt Armor(requires promoted or higher).",
} end )

L:RegisterTranslations("frFR", function() return {
	engage_message = "%s engagé - Phase 1",

	meteor = "Météore",
	meteor_desc = "Délais estimés entre les météores.",
	meteor_warning = "Météore probable dans ~5 sec.",
	meteor_message = "Météore ! Prochain dans ~54 sec.",
	meteor_nextbar = "Prochain météore",

	flamepatch = "Gerbe de flammes sur vous",
	flamepatch_desc = "Préviens quand une Gerbe de flammes est sur vous.",
	flamepatch_trigger = "Vous subissez les effets de Gerbe de flammes.",
	flamepatch_message = "Gerbe de flammes sur VOUS !",

	armor = "Fondre armure",
	armor_desc = "Préviens quand un joueur est affecté par Fondre armure.",
	armor_trigger = "^([^%s]+) ([^%s]+) les effets .* Fondre armure.$",
	armor_other = "Fondre armure : %s",
	armor_you = "Fondre armure sur VOUS !",

	icon = "Icône",
	icon_desc = "Place une icône de raid sur la personne affectée par Fondre armure (nécessite d'être promu ou mieux).",
} end )

L:RegisterTranslations("koKR", function() return {
	engage_message = "%s 전투 개시 - 1 단계",

	meteor = "유성",
	meteor_desc = "대략적인 유성 타이머입니다.",
	meteor_warning = "약 5초 이내 유성 주의",
	meteor_message = "유성! 다음은 약 54초 이내",
	meteor_nextbar = "다음 유성",

	flamepatch = "당신에 화염 파편",
	flamepatch_desc = "당신에 화염 파편에 대한 경고입니다.",
	flamepatch_trigger = "당신은 화염 파편에 걸렸습니다.",
	flamepatch_message = "당신에 화염 파편!",

	armor = "방어구 녹이기",
	armor_desc = "방어구 녹이기에 걸린 사람에 대한 경고입니다.",
	armor_trigger =  "^([^|;%s]*)(.*)방어구 녹이기에 걸렸습니다.$",
	armor_other = "방어구 녹이기: %s",
	armor_you = "당신에 방어구 녹이기!",

	icon = "전술 표시",
	icon_desc = "방어구 녹이기에 걸린 플레이어에에게 전술 표시를 지정합니다 (승급자 이상 권한 요구).",
} end )

----------------------------------
--      Module Declaration      --
----------------------------------

local mod = BigWigs:NewModule(boss)
mod.zonename = AceLibrary("Babble-Zone-2.2")["Tempest Keep"]
mod.otherMenu = "The Eye"
mod.enabletrigger = boss
mod.toggleoptions = {"meteor", "flamepatch", -1, "armor", "icon", "enrage", "bosskill"}
mod.revision = tonumber(("$Revision$"):sub(12, -3))

------------------------------
--      Initialization      --
------------------------------

function mod:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")

	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "debuff")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "debuff")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "debuff")

	self:RegisterEvent("BigWigs_RecvSync")
	self:TriggerEvent("BigWigs_ThrottleSync", "AlArArmor", 5)

	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "CheckForEngage")
	self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH", "GenericBossDeath")

	started = nil
end

------------------------------
--      Event Handlers      --
------------------------------

function mod:CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE(msg)
	if self.db.profile.flamepatch and msg == L["flamepatch_trigger"] then
		self:Message(L["flamepatch_message"], "Personal", true, "Alarm")
	end
end

function mod:BigWigs_RecvSync(sync, rest, nick)
	if self:ValidateEngageSync(sync, rest) and not started then
		started = true
		prior = nil
		fireball = nil
		occured = true
		if self:IsEventRegistered("PLAYER_REGEN_DISABLED") then
			self:UnregisterEvent("PLAYER_REGEN_DISABLED")
		end
		self:Message(L["engage_message"]:format(boss), "Attention")
		self:ScheduleRepeatingEvent("BWAlarTargetSeek", self.AlarCheck, 1, self)
		self:ScheduleEvent("BWAlarNilOccured", function() occured = nil end, 15, self)
	elseif sync == "AlArArmor" and rest and self.db.profile.armor then
		if rest == UnitName("player") then
			self:Message(L["armor_you"], "Personal", true, "Long")
			self:Message(L["armor_other"]:format(rest), "Attention", nil, nil, true)
			self:Bar(L["armor_other"]:format(rest), 60, "Spell_Fire_Immolation")
		else
			self:Message(L["armor_other"]:format(rest), "Attention")
			self:Bar(L["armor_other"]:format(rest), 60, "Spell_Fire_Immolation")
		end
		if self.db.profile.icon then
			self:Icon(rest)
		end
	end
end

function mod:AlarCheck()
	if not self:Scan() and not occured then
		occured = true
		if not prior and self.db.profile.enrage then
			self:DelayedMessage(320, L2["enrage_min"]:format(5), "Positive")
			self:DelayedMessage(440, L2["enrage_min"]:format(3), "Positive")
			self:DelayedMessage(560, L2["enrage_min"]:format(1), "Positive")
			self:DelayedMessage(590, L2["enrage_sec"]:format(30), "Positive")
			self:DelayedMessage(610, L2["enrage_sec"]:format(10), "Urgent")
			self:DelayedMessage(615, L2["enrage_sec"]:format(5), "Urgent")
			self:DelayedMessage(620, L2["enrage_end"]:format(boss), "Attention", nil, "Alarm")
			self:Bar(L2["enrage"], 620, "Spell_Shadow_UnholyFrenzy")
			prior = true
		end
		if fireball and self.db.profile.meteor then
			self:Message(L["meteor_message"], "Urgent", nil, "Alarm")
			self:DelayedMessage(49, L["meteor_warning"], "Important")
			self:Bar(L["meteor_nextbar"], 54, "Spell_Fire_Burnout")
		end
		fireball = true
		self:ScheduleEvent("BWAlarNilOccured", function() occured = nil end, 15, self)
	end
end

function mod:debuff(msg)
	local aplayer, atype = select(3, msg:find(L["armor_trigger"]))
	if aplayer and atype then
		if aplayer == L2["you"] and atype == L2["are"] then
			aplayer = UnitName("player")
		end
		self:Sync("AlArArmor "..aplayer)
	end
end
