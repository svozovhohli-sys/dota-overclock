// OVERCLOCK :: overlay UI script
// Talks to the server through the vm_custom* events defined in ui/bridge.lua.

"use strict";

var lastState = null;

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

	OverclockTab("hub");
	GameEvents.SendCustomGameEventToServer("oc_request_state", {});
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

function OverclockTab(tab)
{
	var pages = ["hub", "sandbox", "stats", "patch", "roguelike"];
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
