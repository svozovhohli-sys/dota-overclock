--[[
	OVERCLOCK :: data/mechanics.lua
	Catalog of tunable combat mechanics. mechanics/manager.lua turns each entry
	into live parameters and links the implementing modifier.

	Entry schema:
		{
			id      = "bash",
			label   = "Баш",
			kind    = "stat"|"onhit"|"crit"|"cleave"|"lifesteal"
			        |"dot"|"maxhp"|"rupture"|"status",
			scope   = "self" | "target",     -- self: on your hero; target: on enemy
			prop    = "attack_speed",         -- stat kind only
			state   = "rooted",               -- status kind only
			fields  = {
				{ id="chance", label="Шанс", min=0, max=100, step=1, unit="%",
				  default=25, type="number" },
			},
		}

	Adding a new mechanic of an existing kind is one entry here - no new code.
--]]

return {
	-- ===== live stat knobs (self) =========================================
	{ id = "ms", label = "Скорость передвижения", kind = "stat", scope = "self",
	  prop = "move_speed", fields = {
		{ id = "value", label = "Значение", min = -100, max = 400, step = 5, unit = "%", default = 30 } } },
	{ id = "as", label = "Скорость атаки", kind = "stat", scope = "self",
	  prop = "attack_speed", fields = {
		{ id = "value", label = "Значение", min = -200, max = 1500, step = 10, default = 100 } } },
	{ id = "armor", label = "Броня", kind = "stat", scope = "self",
	  prop = "armor", fields = {
		{ id = "value", label = "Значение", min = -100, max = 500, step = 5, default = 20 } } },
	{ id = "magic_resist", label = "Магрезист", kind = "stat", scope = "self",
	  prop = "magic_resist", fields = {
		{ id = "value", label = "Значение", min = -100, max = 200, step = 5, unit = "%", default = 25 } } },
	{ id = "spell_amp", label = "Усиление магии", kind = "stat", scope = "self",
	  prop = "spell_amp", fields = {
		{ id = "value", label = "Значение", min = -100, max = 300, step = 5, unit = "%", default = 30 } } },
	{ id = "cdr", label = "Сокращение перезарядки", kind = "stat", scope = "self",
	  prop = "cdr", fields = {
		{ id = "value", label = "Значение", min = 0, max = 80, step = 1, unit = "%", default = 20 } } },
	{ id = "status_resist", label = "Сопр. статусам", kind = "stat", scope = "self",
	  prop = "status_resist", fields = {
		{ id = "value", label = "Значение", min = 0, max = 90, step = 1, unit = "%", default = 20 } } },
	{ id = "slow_resist", label = "Сопр. замедлению", kind = "stat", scope = "self",
	  prop = "slow_resist", fields = {
		{ id = "value", label = "Значение", min = 0, max = 90, step = 1, unit = "%", default = 20 } } },
	{ id = "evasion", label = "Уклонение", kind = "stat", scope = "self",
	  prop = "evasion", fields = {
		{ id = "value", label = "Значение", min = 0, max = 90, step = 5, unit = "%", default = 25 } } },
	{ id = "hp_regen", label = "Реген HP", kind = "stat", scope = "self",
	  prop = "hp_regen", fields = {
		{ id = "value", label = "Значение", min = -100, max = 3000, step = 10, default = 50 } } },
	{ id = "mana_regen", label = "Реген маны", kind = "stat", scope = "self",
	  prop = "mana_regen", fields = {
		{ id = "value", label = "Значение", min = -100, max = 3000, step = 10, default = 10 } } },
	{ id = "cast_range", label = "Дальность каста", kind = "stat", scope = "self",
	  prop = "cast_range", fields = {
		{ id = "value", label = "Значение", min = -500, max = 3000, step = 25, default = 200 } } },
	{ id = "attack_range", label = "Дальность атаки", kind = "stat", scope = "self",
	  prop = "attack_range", fields = {
		{ id = "value", label = "Значение", min = -300, max = 3000, step = 25, default = 150 } } },
	{ id = "heal_amp", label = "Усиление лечения", kind = "stat", scope = "self",
	  prop = "heal_amp", fields = {
		{ id = "value", label = "Значение", min = -100, max = 300, step = 5, unit = "%", default = 25 } } },

	-- ===== on-hit procs (self) ============================================
	{ id = "bash", label = "Баш (оглушение)", kind = "onhit", scope = "self", fields = {
		{ id = "chance", label = "Шанс", min = 0, max = 100, step = 1, unit = "%", default = 25 },
		{ id = "bonus_damage", label = "Бонус урона", min = 0, max = 3000, step = 10, default = 100 },
		{ id = "damage_type", label = "Тип урона", type = "enum", default = "magical",
		  options = { { "magical", "маг." }, { "physical", "физ." }, { "pure", "чист." } } },
		{ id = "stun", label = "Оглушение", min = 0, max = 10, step = 0.1, unit = "с", default = 1.0 } } },
	{ id = "mana_break", label = "Сжигание маны", kind = "onhit", scope = "self", fields = {
		{ id = "chance", label = "Шанс", min = 0, max = 100, step = 1, unit = "%", default = 100 },
		{ id = "burn_mana", label = "Сжечь маны", min = 0, max = 500, step = 5, default = 50 },
		{ id = "bonus_damage", label = "Бонус урона", min = 0, max = 1000, step = 10, default = 0 },
		{ id = "damage_type", label = "Тип урона", type = "enum", default = "physical",
		  options = { { "magical", "маг." }, { "physical", "физ." }, { "pure", "чист." } } } } },
	{ id = "poison", label = "Отравление с удара", kind = "onhit", scope = "self", fields = {
		{ id = "chance", label = "Шанс", min = 0, max = 100, step = 1, unit = "%", default = 100 },
		{ id = "dot_dps", label = "Урон/с", min = 0, max = 1000, step = 5, default = 30 },
		{ id = "dot_duration", label = "Длительность", min = 0, max = 30, step = 1, unit = "с", default = 6 } } },
	{ id = "bonus_proc", label = "Пробивающий удар (прок)", kind = "onhit", scope = "self", fields = {
		{ id = "chance", label = "Шанс", min = 0, max = 100, step = 1, unit = "%", default = 25 },
		{ id = "bonus_damage", label = "Бонус урона", min = 0, max = 3000, step = 10, default = 200 },
		{ id = "damage_type", label = "Тип урона", type = "enum", default = "magical",
		  options = { { "magical", "маг." }, { "physical", "физ." }, { "pure", "чист." } } } } },
	{ id = "crit", label = "Критический удар", kind = "crit", scope = "self", fields = {
		{ id = "chance", label = "Шанс", min = 0, max = 100, step = 1, unit = "%", default = 25 },
		{ id = "mult", label = "Множитель", min = 1, max = 20, step = 0.5, unit = "x", default = 2.0 } } },
	{ id = "cleave", label = "Рассекающий удар", kind = "cleave", scope = "self", fields = {
		{ id = "radius", label = "Радиус", min = 50, max = 2000, step = 25, default = 300 },
		{ id = "percent", label = "Процент урона", min = 0, max = 300, step = 5, unit = "%", default = 40 } } },
	{ id = "lifesteal", label = "Кража жизни", kind = "lifesteal", scope = "self", fields = {
		{ id = "percent", label = "Процент", min = 0, max = 300, step = 5, unit = "%", default = 25 } } },

	-- ===== target debuffs =================================================
	{ id = "rupture", label = "Разрыв (урон за движение)", kind = "rupture", scope = "target", fields = {
		{ id = "per_100", label = "Урон / 100 ед.", min = 0, max = 1000, step = 5, default = 100 },
		{ id = "duration", label = "Длительность", min = 1, max = 30, step = 1, unit = "с", default = 8 } } },
	{ id = "dot_magic", label = "Периодический урон", kind = "dot", scope = "target", fields = {
		{ id = "dps", label = "Урон/с", min = 0, max = 1000, step = 5, default = 50 },
		{ id = "interval", label = "Интервал", min = 0.1, max = 3, step = 0.1, unit = "с", default = 1.0 },
		{ id = "damage_type", label = "Тип урона", type = "enum", default = "magical",
		  options = { { "magical", "маг." }, { "physical", "физ." }, { "pure", "чист." } } },
		{ id = "duration", label = "Длительность", min = 1, max = 60, step = 1, unit = "с", default = 8 } } },
	{ id = "maxhp_burn", label = "Выжигание % HP", kind = "maxhp", scope = "target", fields = {
		{ id = "percent_per_sec", label = "% HP/с", min = 0, max = 100, step = 0.5, unit = "%", default = 5 },
		{ id = "interval", label = "Интервал", min = 0.1, max = 3, step = 0.1, unit = "с", default = 0.5 },
		{ id = "duration", label = "Длительность", min = 1, max = 60, step = 1, unit = "с", default = 6 } } },
	{ id = "root", label = "Обездвиживание (root)", kind = "status", scope = "target",
	  state = "rooted", fields = {
		{ id = "duration", label = "Длительность", min = 0, max = 30, step = 0.5, unit = "с", default = 3 } } },
	{ id = "silence", label = "Немота (silence)", kind = "status", scope = "target",
	  state = "silenced", fields = {
		{ id = "duration", label = "Длительность", min = 0, max = 30, step = 0.5, unit = "с", default = 4 } } },
	{ id = "disarm", label = "Обезоруживание", kind = "status", scope = "target",
	  state = "disarmed", fields = {
		{ id = "duration", label = "Длительность", min = 0, max = 30, step = 0.5, unit = "с", default = 4 } } },
	{ id = "hex", label = "Превращение (hex)", kind = "status", scope = "target",
	  state = "hexed", fields = {
		{ id = "duration", label = "Длительность", min = 0, max = 30, step = 0.5, unit = "с", default = 3 } } },
	{ id = "break", label = "Подавление пассивок", kind = "status", scope = "target",
	  state = "passives_disabled", fields = {
		{ id = "duration", label = "Длительность", min = 0, max = 30, step = 0.5, unit = "с", default = 5 } } },
	{ id = "mute", label = "Заглушение предметов", kind = "status", scope = "target",
	  state = "muted", fields = {
		{ id = "duration", label = "Длительность", min = 0, max = 30, step = 0.5, unit = "с", default = 5 } } },
}
