// OVERCLOCK :: key bindings
// The keys F5..F10 are declared in addoninfo.txt -> Default_Keys. Each key maps
// to a console command; below we register those commands with the UI so main
// Dota dispatches them to us.

"use strict";

function OCEnsureOpen()
{
	var body = $("#Body");
	if (body && body.BHasClass("OverclockBodyHidden"))
	{
		body.SetHasClass("OverclockBodyHidden", false);
	}
}

function OCShowTab(tab)
{
	OCEnsureOpen();
	if (typeof OverclockTab === "function")
	{
		OverclockTab(tab);
	}
}

function OCInitKeys()
{
	Game.AddCommand("OC_ToggleHub", function () { OCShowTab("hub"); }, "", 0);
	Game.AddCommand("OC_ToggleSandbox", function () { OCShowTab("sandbox"); }, "", 0);
	Game.AddCommand("OC_ToggleStats", function () { OCShowTab("stats"); }, "", 0);
	Game.AddCommand("OC_TogglePatch", function () { OCShowTab("patch"); }, "", 0);
	Game.AddCommand("OC_ToggleRoguelike", function () { OCShowTab("roguelike"); }, "", 0);
	Game.AddCommand("OC_OpenModifierConsole", function () { OCShowTab("sandbox"); }, "", 0);
}

// Defer so overclock.js globals and the panels exist first.
$.Schedule(0.1, function ()
{
	try
	{
		OCInitKeys();
	}
	catch (e)
	{
		$.Msg("[OVERCLOCK] key bind failed: ", e);
	}
});
