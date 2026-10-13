// OVERCLOCK :: overlay UI script
// Talks to the server through the vm_custom* events defined in ui/bridge.lua.

"use strict";

var lastState = null;
var paramById = {};

// --------------------------------------------------------------------------
// lifecycle
// --------------------------------------------------------------------------

function Init()
{
	// Keep the default gameplay HUD we care about visible. Our manifest mounts
	// an extra panel on top of the HUD slot, so re-enable the vanilla pieces.
	GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_PANEL, true);
	GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ACTION_MINIMAP, true);
	GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_TIMEOFDAY, false);
	GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, true);
	GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD, true);

	GameEvents.Subscribe("oc_state", OnState);
	GameEvents.Subscribe("oc_stats", OnStats);
	GameEvents.Subscribe("oc_notify", OnNotify);
	GameEvents.Subscribe("oc_params", OnParams);
	GameEvents.Subscribe("oc_abilities", OnAbilities);

	OverclockTab("hub");
	GameEvents.SendCustomGameEventToServer("oc_request_state", {});
	GameEvents.SendCustomGameEventToServer("oc_action", { action: "param_get", id: "" });
}

// --------------------------------------------------------------------------
// server -> client
// --------------------------------------------------------------------------

function OnState(data)
{
	lastState = data;

	if (data.mode !== undefined)
	{
		$("#StatusMode").text = "Mode: " + data.mode;
	}
	if (data.paused !== undefined)
	{
		$("#StatusPaused").text = "Paused: " + (data.paused ? "yes" : "no");
	}
	if (data.players !== undefined)
	{
		$("#StatusPlayers").text = "Players: " + data.players;
	}
	if (data.spawned !== undefined)
	{
		$("#StatusSpawned").text = "Spawned: " + data.spawned;
	}

	RenderRun(data.run);
}

function OnStats(rows)
{
	var parent = $("#DpsList");
	parent.RemoveAndDeleteChildren();
	rows = rows || [];
	for (var i = 0; i < rows.length; i++)
	{
		var r = rows[i];
		AddListRow(parent,
			r.name + "   DPS " + r.dps.toFixed(1) + "   peak " + r.peak.toFixed(1) + "   total " + Math.floor(r.total),
			null, null);
	}
}

function OnNotify(data)
{
	$.Msg("[OVERCLOCK] ", data.text);
}

// --------------------------------------------------------------------------
// ability browser results
// --------------------------------------------------------------------------

function OnAbilities(data)
{
	var parent = $("#AbilityResults");
	if (!parent) { return; }
	parent.RemoveAndDeleteChildren();
	var results = (data && data.results) || [];
	if (data && data.note)
	{
		var note = $.CreatePanel("Label", parent, "");
		note.AddClass("OverclockText");
		note.text = data.note;
	}
	for (var i = 0; i < results.length; i++)
	{
		var dump = results[i];
		var head = $.CreatePanel("Label", parent, "");
		head.AddClass("OverclockH2");
		head.text = dump.ability;
		var values = dump.values || [];
		for (var j = 0; j < values.length; j++)
		{
			AddListRow(parent, values[j].key + " = " + FormatNum(values[j].value), null, null);
		}
	}
}

// --------------------------------------------------------------------------
// live parameters
// --------------------------------------------------------------------------

function OnParams(data)
{
	var list = (data && data.params) || [];
	paramById = {};
	for (var i = 0; i < list.length; i++)
	{
		paramById[list[i].id] = list[i];
	}
	RenderParams(list);
}

function RenderParams(list)
{
	var parent = $("#ParamList");
	parent.RemoveAndDeleteChildren();

	var lastSection = null;
	for (var i = 0; i < list.length; i++)
	{
		var p = list[i];
		if (p.section !== lastSection)
		{
			lastSection = p.section;
			var head = $.CreatePanel("Label", parent, "");
			head.AddClass("OverclockH2");
			head.text = p.section;
		}
		AddParamRow(parent, p);
	}
}

function AddParamRow(parent, p)
{
	var row = $.CreatePanel("Panel", parent, "");
	row.AddClass("OverclockListRow");

	var label = $.CreatePanel("Label", row, "");
	label.AddClass("OverclockListText");
	label.text = p.label;

	var ctrl = $.CreatePanel("Panel", row, "");
	ctrl.AddClass("OverclockParamCtrl");

	if (p.type === "bool")
	{
		var b = MakeBtn(ctrl, p.value ? "вкл" : "выкл");
		b.SetHasClass("OverclockToggleOn", p.value === true);
		b.SetPanelEvent("onactivate", function () { OverclockParamSet(p.id, (p.value ? 0 : 1)); });
	}
	else if (p.type === "enum")
	{
		var eb = MakeBtn(ctrl, String(p.value));
		eb.SetPanelEvent("onactivate", function () { OverclockParamCycle(p.id); });
	}
	else if (p.type === "action")
	{
		var ab = MakeBtn(ctrl, "выполнить");
		ab.SetPanelEvent("onactivate", function () { OverclockParamInvoke(p.id); });
	}
	else if (p.type === "text")
	{
		var te = $.CreatePanel("TextEntry", ctrl, "");
		te.AddClass("OverclockInput");
		te.text = (p.value === null || p.value === undefined) ? "" : String(p.value);
		var tb = MakeBtn(ctrl, "ok");
		tb.SetPanelEvent("onactivate", function () { OverclockParamSet(p.id, te.text); });
	}
	else
	{
		var minus = MakeBtn(ctrl, "-");
		minus.SetPanelEvent("onactivate", function () { OverclockParamStep(p.id, -1); });

		var val = $.CreatePanel("Label", ctrl, "");
		val.AddClass("OverclockParamValue");
		val.text = FormatNum(p.value) + (p.unit ? p.unit : "");

		var plus = MakeBtn(ctrl, "+");
		plus.SetPanelEvent("onactivate", function () { OverclockParamStep(p.id, 1); });
	}
}

function MakeBtn(parent, text)
{
	var btn = $.CreatePanel("Button", parent, "");
	btn.AddClass("OverclockButton");
	var bl = $.CreatePanel("Label", btn, "");
	bl.text = text;
	return btn;
}

function FormatNum(v)
{
	if (v === null || v === undefined) { return "-"; }
	if (typeof v === "number")
	{
		if (v === Math.floor(v)) { return String(v); }
		return v.toFixed(2);
	}
	return String(v);
}

// --------------------------------------------------------------------------
// state rendering
// --------------------------------------------------------------------------

function RenderRun(run)
{
	if (!run || !run.active)
	{
		$("#RunWave").text = "Wave: -";
		$("#RunDepth").text = "Depth: -";
		$("#RunGold").text = "Gold: -";
		$("#RunEnemies").text = "Enemies: -";
		$("#RunPrompt").text = "";
		$("#RunChoices").RemoveAndDeleteChildren();
		return;
	}

	$("#RunWave").text = "Wave: " + run.wave;
	$("#RunDepth").text = "Depth: " + run.depth;
	$("#RunGold").text = "Gold: " + run.gold;
	$("#RunEnemies").text = "Enemies: " + run.enemies_alive;

	var parent = $("#RunChoices");
	parent.RemoveAndDeleteChildren();

	if (run.status === "curse")
	{
		$("#RunPrompt").text = $.Localize("#overclock_run_curse");
		var curses = run.pending_curses || [];
		for (var i = 0; i < curses.length; i++)
		{
			(function (c)
			{
				AddListRow(parent, c.name + " — " + c.desc, "Выбрать",
					function () { OverclockAction("run_curse", c.id); });
			})(curses[i]);
		}
	}
	else if (run.status === "reward")
	{
		$("#RunPrompt").text = $.Localize("#overclock_run_reward");
		var rewards = run.pending_rewards || [];
		for (var j = 0; j < rewards.length; j++)
		{
			(function (r)
			{
				AddListRow(parent, r.name + " — " + r.desc, "Взять",
					function () { OverclockAction("run_reward", r.id); });
			})(rewards[j]);
		}
	}
	else if (run.status === "shop")
	{
		$("#RunPrompt").text = $.Localize("#overclock_run_shop") + " (" + run.gold + "g)";
		var items = run.shop || [];
		for (var k = 0; k < items.length; k++)
		{
			(function (it)
			{
				AddListRow(parent, it.name + " [" + it.cost + "g] — " + it.desc, "Купить",
					function () { OverclockAction("run_buy", it.id); });
			})(items[k]);
		}
	}
	else
	{
		$("#RunPrompt").text = "Идёт бой…";
	}
}

// --------------------------------------------------------------------------
// helpers
// --------------------------------------------------------------------------

function AddListRow(parent, text, buttonText, onClick)
{
	var row = $.CreatePanel("Panel", parent, "");
	row.AddClass("OverclockListRow");

	var label = $.CreatePanel("Label", row, "");
	label.AddClass("OverclockListText");
	label.text = text;

	if (buttonText && onClick)
	{
		var btn = $.CreatePanel("Button", row, "");
		btn.AddClass("OverclockButton");
		var bl = $.CreatePanel("Label", btn, "");
		bl.text = buttonText;
		btn.SetPanelEvent("onactivate", onClick);
	}
	return row;
}

// --------------------------------------------------------------------------
// UI -> server  (called from XML onactivate)
// --------------------------------------------------------------------------

function OverclockAction(action, id)
{
	GameEvents.SendCustomGameEventToServer("oc_action", { action: action, id: id });
}

function OverclockCmd(raw)
{
	GameEvents.SendCustomGameEventToServer("oc_cmd", { raw: raw });
}

function OverclockSpawn()
{
	var input = $("#SpawnInput");
	if (input && input.text && input.text.length > 0)
	{
		OverclockCmd("spawn " + input.text);
		input.text = "";
	}
}

function OverclockParamSet(id, value)
{
	GameEvents.SendCustomGameEventToServer("oc_action", { action: "param_set", id: id, value: String(value) });
}

function OverclockParamStep(id, dir)
{
	var p = paramById[id];
	if (!p) { return; }
	var step = (p.step !== undefined && p.step !== null && p.step > 0) ? p.step : 1;
	var v = (typeof p.value === "number") ? p.value : parseFloat(p.value);
	if (isNaN(v)) { v = 0; }
	v = v + dir * step;
	if (p.min !== undefined && p.min !== null && v < p.min) { v = p.min; }
	if (p.max !== undefined && p.max !== null && v > p.max) { v = p.max; }
	OverclockParamSet(id, v);
}

function OverclockParamCycle(id)
{
	var p = paramById[id];
	if (!p || !p.options || p.options.length === 0) { return; }
	var idx = 0;
	for (var i = 0; i < p.options.length; i++)
	{
		if (p.options[i][0] === p.value) { idx = i; break; }
	}
	var next = p.options[(idx + 1) % p.options.length][0];
	OverclockParamSet(id, next);
}

function OverclockParamInvoke(id)
{
	GameEvents.SendCustomGameEventToServer("oc_action", { action: "param_invoke", id: id });
}

function OverclockParamsRefresh()
{
	GameEvents.SendCustomGameEventToServer("oc_action", { action: "param_get", id: "" });
}

function OverclockTab(tab)
{
	var pages = ["hub", "sandbox", "stats", "patch", "roguelike", "params"];
	for (var i = 0; i < pages.length; i++)
	{
		var page = $("#Page-" + pages[i]);
		if (page)
		{
			page.SetHasClass("OverclockPageHidden", pages[i] !== tab);
		}
	}
}

function OverclockToggle()
{
	var body = $("#Body");
	if (body)
	{
		body.SetHasClass("OverclockBodyHidden", !body.BHasClass("OverclockBodyHidden"));
	}
}

(function ()
{
	Init();
})();
