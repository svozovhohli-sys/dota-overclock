--[[
	OVERCLOCK :: data/game_rules.lua
	Declarative catalog of game-rule tunables. rules/manager.lua turns each
	entry into a live parameter in the "Правила" section and re-applies the
	value to the engine.

	Entry schema:
		{
			id      = "starting_gold",
			label   = "Стартовое золото",
			section = "Золото и опыт",
			type    = "number" | "bool",
			min, max, step, unit,           -- number only
			default = 600,
			kind    = "gr" | "gm" | "convar",
			method  = "SetStartingGold",    -- gr/gm: GameRules / GameMode method
			name    = "dota_...",           -- convar: variable name
			desc    = "tooltip",
		}

	kind semantics:
		gr     -> GameRules:<method>(value)
		gm     -> GameRules:GetGameModeEntity():<method>(value)
		convar -> core/convars.lua (int for bool, auto for number)
--]]

return {
	-- preparation ------------------------------------------------------------
	{ id = "pregame_time", label = "Время до старта", section = "Подготовка",
	  type = "number", min = 0, max = 180, step = 5, unit = "с", default = 0,
	  kind = "gr", method = "SetPreGameTime" },
	{ id = "strategy_time", label = "Время стратегии", section = "Подготовка",
	  type = "number", min = 0, max = 180, step = 5, unit = "с", default = 0,
	  kind = "gr", method = "SetStrategyTime" },
	{ id = "showcase_time", label = "Время показа героев", section = "Подготовка",
	  type = "number", min = 0, max = 180, step = 5, unit = "с", default = 0,
	  kind = "gr", method = "SetShowcaseTime" },

	-- gold & xp --------------------------------------------------------------
	{ id = "starting_gold", label = "Стартовое золото", section = "Золото и опыт",
	  type = "number", min = 0, max = 100000, step = 50, default = 600,
	  kind = "gr", method = "SetStartingGold" },
	{ id = "gold_per_tick", label = "Пассивное золото / тик", section = "Золото и опыт",
	  type = "number", min = 0, max = 1000, step = 1, default = 0,
	  kind = "gr", method = "SetGoldPerTick" },
	{ id = "lose_gold_on_death", label = "Терять золото при смерти", section = "Золото и опыт",
	  type = "bool", default = false, kind = "gm", method = "SetLoseGoldOnDeath" },
	{ id = "use_custom_levels", label = "Свои уровни героя", section = "Золото и опыт",
	  type = "bool", default = false, kind = "gm", method = "SetUseCustomHeroLevels" },
	{ id = "custom_max_level", label = "Макс. уровень героя", section = "Золото и опыт",
	  type = "number", min = 1, max = 100, step = 1, default = 30,
	  kind = "gm", method = "SetCustomHeroMaxLevel" },

	-- heroes & respawn -------------------------------------------------------
	{ id = "respawning", label = "Респаун героев", section = "Герои и респаун",
	  type = "bool", default = true, kind = "gr", method = "SetHeroRespawnEnabled" },
	{ id = "fixed_respawn", label = "Фикс. время респауна", section = "Герои и респаун",
	  type = "number", min = 0, max = 180, step = 1, unit = "с", default = 3,
	  kind = "gm", method = "SetFixedRespawnTime" },
	{ id = "buyback_enabled", label = "Выкуп (buyback)", section = "Герои и респаун",
	  type = "bool", default = false, kind = "gm", method = "SetBuybackEnabled" },
	{ id = "same_hero", label = "Разрешить одинаковых героев", section = "Герои и респаун",
	  type = "bool", default = true, kind = "gr", method = "SetSameHeroSelectionEnabled" },

	-- fountain ---------------------------------------------------------------
	{ id = "fountain_hp_pct", label = "Реген HP фонтана", section = "Фонтан",
	  type = "number", min = 0, max = 100, step = 1, unit = "%/с", default = 10,
	  kind = "gm", method = "SetFountainPercentageHealthRegen" },
	{ id = "fountain_mp_pct", label = "Реген маны фонтана", section = "Фонтан",
	  type = "number", min = 0, max = 100, step = 1, unit = "%/с", default = 10,
	  kind = "gm", method = "SetFountainPercentageManaRegen" },
	{ id = "fountain_mp_const", label = "Реген маны фонтана (конст.)", section = "Фонтан",
	  type = "number", min = 0, max = 1000, step = 1, default = 0,
	  kind = "gm", method = "SetFountainConstantManaRegen" },

	-- world ------------------------------------------------------------------
	{ id = "creep_spawning", label = "Спавн крипов", section = "Мир",
	  type = "bool", default = true, kind = "gr", method = "SetCreepSpawningEnabled" },
	{ id = "daynight_disabled", label = "Отключить смену дня/ночи", section = "Мир",
	  type = "bool", default = false, kind = "gm", method = "SetDaynightCycleDisabled" },
	{ id = "backdoor_protection", label = "Защита башен от бэкдора", section = "Мир",
	  type = "bool", default = true, kind = "gm", method = "SetTowerBackdoorProtectionEnabled" },

	-- shop & comfort ---------------------------------------------------------
	{ id = "universal_shop", label = "Универсальный магазин", section = "Магазин",
	  type = "bool", default = true, kind = "gr", method = "SetUseUniversalShopMode" },
	{ id = "free_courier", label = "Бесплатный курьер", section = "Магазин",
	  type = "bool", default = false, kind = "gm", method = "SetFreeCourierModeEnabled" },
	{ id = "sticky_item_disabled", label = "Сброс покупки предметов", section = "Магазин",
	  type = "bool", default = true, kind = "gm", method = "SetStickyItemDisabled" },
	{ id = "recommended_items_disabled", label = "Скрыть рекомендованные", section = "Магазин",
	  type = "bool", default = false, kind = "gm", method = "SetRecommendedItemsDisabled" },

	-- presentation -----------------------------------------------------------
	{ id = "announcer_disabled", label = "Выключить комментатора", section = "Подача",
	  type = "bool", default = true, kind = "gm", method = "SetAnnouncerDisabled" },
	{ id = "weather_disabled", label = "Выключить погоду", section = "Подача",
	  type = "bool", default = true, kind = "gm", method = "SetWeatherEffectsDisabled" },
}
