#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#pragma newdecls required


/* BOOLEANS */
bool g_bAutoBhop[MAXPLAYERS + 1] = {false, ...};
bool g_bAutoBhopGlobal;
bool g_bLateLoaded = false;

/* CONVARS */
ConVar g_CVar_AutoBhopGlobal = null;

/* COOKIES */
Handle g_hCookie_ClientAutoBhop = null;


//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Plugin myinfo =
{
	name			= "AutoBhop",
	description		= "Manages autobhopping for players and admins.",
	author			= "Kelyan3",
	version			= "1.0.2",
	url				= "https://steamcommunity.com/id/BeholdTheBahamutSlayer",
};

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrorLength)
{
	g_bLateLoaded = bLate;

	return APLRes_Success;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	g_CVar_AutoBhopGlobal = CreateConVar("sm_autobhop_global", "0", "Specifies whether to enable AutoBhop features for players and admins.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_bAutoBhopGlobal = g_CVar_AutoBhopGlobal.BoolValue;
	g_CVar_AutoBhopGlobal.AddChangeHook(ConVarChanged_AutoBhop);

	AutoExecConfig(true, "plugin.AutoBhop");

	RegAdminCmd("sm_abforce", Command_AutoBhopForce, ADMFLAG_BAN, "Forcefully toggles a client's AutoBhop.");
	RegAdminCmd("sm_autobhopforce", Command_AutoBhopForce, ADMFLAG_BAN, "Forcefully toggles a client's AutoBhop.");

	RegConsoleCmd("sm_abstatus", Command_AutoBhopStatus, "Checks a client's AutoBhop status.");
	RegConsoleCmd("sm_autobhopbstatus", Command_AutoBhopStatus, "Checks a client's AutoBhop status.");

	RegConsoleCmd("sm_ab", Command_AutoBhop, "Toggles AutoBhop for yourself.");
	RegConsoleCmd("sm_autobhop", Command_AutoBhop, "Toggles AutoBhop for yourself.");

	g_hCookie_ClientAutoBhop = RegClientCookie("autobhop_cookie", "Does client wants to enable autobhop?", CookieAccess_Protected);

	SetCookieMenuItem(MenuHandler_CookieMenu_AutoBhop, 0, "AutoBhop");

	/* Handle late load. */
	if (g_bLateLoaded)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsClientInGame(client) || IsFakeClient(client))
				continue;

			OnClientPutInServer(client);

			if (AreClientCookiesCached(client))
				OnClientCookiesCached(client);
		}
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void ConVarChanged_AutoBhop(ConVar hConVar, const char[] sOldValue, const char[] sNewValue)
{
	g_bAutoBhopGlobal = g_CVar_AutoBhopGlobal.BoolValue;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void OnClientCookiesCached(int client)
{
	ReadClientCookies(client);
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void OnClientPutInServer(int client)
{
	ReadClientCookies(client);
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void MenuHandler_CookieMenu_AutoBhop(int client, CookieMenuAction hAction, any aInfo, char[] sBuffer, int iBufferLength)
{
	switch (hAction)
	{
		case CookieMenuAction_DisplayOption:
			Format(sBuffer, iBufferLength, "AutoBhop", client);

		case CookieMenuAction_SelectOption:
			DisplaySettingsMenu(client);
	}
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void DisplaySettingsMenu(int client)
{
	Menu SettingsMenu = new Menu(MenuHandler_Menu_AutoBhopSettings);
	SettingsMenu.SetTitle("AutoBhop Settings");

	char sBuffer[128];
	Format(sBuffer, sizeof(sBuffer), "AutoBhop: %s", g_bAutoBhopGlobal ? (g_bAutoBhop[client] ? "Enabled" : "Disabled") : "Disabled by host.");
	SettingsMenu.AddItem("0", sBuffer, g_bAutoBhopGlobal ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	SettingsMenu.ExitBackButton = true;
	SettingsMenu.Display(client, MENU_TIME_FOREVER);
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public int MenuHandler_Menu_AutoBhopSettings(Menu SettingsMenu, MenuAction hAction, int iParam1, int iParam2)
{
	switch (hAction)
	{
		case MenuAction_End:
			delete SettingsMenu;

		case MenuAction_Cancel:
		{
			if (iParam2 == MenuCancel_ExitBack)
				ShowCookieMenu(iParam1);
		}

		case MenuAction_Select:
		{
			switch (iParam2)
			{
				case 0: ToggleAutoBhop(iParam1);
			}

			DisplaySettingsMenu(iParam1);
		}
	}

	return 0;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action Command_AutoBhopStatus(int client, int argc)
{
	if (!client)
	{
		ReplyToCommand(client, "[SM] Cannot use this command on server console.");
		return Plugin_Handled;
	}

	if (!g_bAutoBhopGlobal)
	{
		ReplyToCommand(client, "[SM] This feature is currently disabled by the host.");
		return Plugin_Handled;
	}

	if (CheckCommandAccess(client, "sm_abstatus", ADMFLAG_GENERIC) && argc)
	{
		char sArgs[64];
		GetCmdArg(1, sArgs, sizeof(sArgs));

		int iTarget;
		if ((iTarget = FindTarget(client, sArgs, true)) == -1)
			return Plugin_Handled;

		if (g_bAutoBhop[iTarget])
		{
			PrintToChat(client, "[SM] Checking %N's autobhop status: %s", iTarget, g_bAutoBhop[iTarget] ? "ON" : "OFF");
			return Plugin_Handled;
		}

		return Plugin_Handled;
	}
	else
	{
		if (g_bAutoBhop[client])
		{
			PrintToChat(client, "[SM] Checking your autobhop status: %s", g_bAutoBhop[client] ? "ON" : "OFF");
			return Plugin_Handled;
		}
	}

	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action Command_AutoBhopForce(int client, int argc)
{
	if (!client)
	{
		ReplyToCommand(client, "[SM] Cannot use this command on server console.");
		return Plugin_Handled;
	}

	if (!g_bAutoBhopGlobal)
	{
		ReplyToCommand(client, "[SM] This feature is currently disabled by the host.");
		return Plugin_Handled;
	}

	if (argc < 1)
	{
		char sCommand[64];
		GetCmdArg(0, sCommand, sizeof(sCommand));
		ReplyToCommand(client, "[SM] Usage: %s <#userid|name> <optional:0|1>", sCommand);
		return Plugin_Handled;
	}

	char sArgs[64];
	GetCmdArg(1, sArgs, sizeof(sArgs));

	int iToggleBhop = -1;

	if (argc >= 2)
	{
		char sArgs2[32];
		GetCmdArg(2, sArgs2, sizeof(sArgs2));

		if (StringToIntEx(sArgs2, iToggleBhop) == 0)
		{
			ReplyToCommand(client, "[SM] Invalid Value.");
			return Plugin_Handled;
		}
	}

	char sTargetName[MAX_TARGET_LENGTH];
	int iTargetList[MAXPLAYERS];
	int iTargetCount;
	bool bIsML;

	if ((iTargetCount = ProcessTargetString(sArgs, client, iTargetList, MAXPLAYERS, COMMAND_FILTER_ALIVE | COMMAND_FILTER_CONNECTED, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for (int i = 0; i < iTargetCount; i++)
	{
		if (iToggleBhop == -1)
			iToggleBhop = !g_bAutoBhop[iTargetList[i]];

		g_bAutoBhop[iTargetList[i]] = iToggleBhop ? true : false;
	}

	ShowActivity2(client, "\x01[SM] \x04", "\x01Forcefully \x04%s \x01autobhop on target \x04%s\x01.", iToggleBhop ? "enabled" : "disabled", sTargetName);

	if (iTargetCount > 1)
		LogAction(client, -1, "\"%L\" has forcefully %s autobhop on target \"%s\".", client, iToggleBhop ? "enabled" : "disabled", sTargetName);
	else
		LogAction(client, iTargetList[0], "\"%L\" has forcefully %s autobhop on target \"%L\".", client, iToggleBhop ? "enabled" : "disabled", iTargetList[0]);

	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action Command_AutoBhop(int client, int argc)
{
	if (!client)
	{
		ReplyToCommand(client, "[SM] Cannot use this command on server console.");
		return Plugin_Handled;
	}

	if (!g_bAutoBhopGlobal)
	{
		ReplyToCommand(client, "[SM] This feature is currently disabled by the host.");
		return Plugin_Handled;
	}

	ToggleAutoBhop(client);

	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void ToggleAutoBhop(int client)
{
	g_bAutoBhop[client] = !g_bAutoBhop[client];

	SetClientCookie(client, g_hCookie_ClientAutoBhop, g_bAutoBhop[client] ? "1" : "");

	PrintToChat(client, "[SM] You have %s autobhop for yourself.", g_bAutoBhop[client] ? "enabled" : "disabled");
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon, int &iSubType, int &iCmdNum, int &iTickCount, int &iSeed, int iMouse[2])
{
	if (!g_bAutoBhop[client] || !g_bAutoBhopGlobal)
		return Plugin_Continue;

	if (IsPlayerAlive(client) && iButtons & IN_JUMP)
	{
		if (!(GetEntityMoveType(client) & MOVETYPE_LADDER) && !(GetEntityFlags(client) & FL_ONGROUND))
		{
			if (GetEntProp(client, Prop_Data, "m_nWaterLevel") <= 1)
				iButtons &= ~IN_JUMP;
		}
	}

	return Plugin_Continue;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
void ReadClientCookies(int client)
{
	char sCookieValue[8];

	GetClientCookie(client, g_hCookie_ClientAutoBhop, sCookieValue, sizeof(sCookieValue));
	if (sCookieValue[0])
		g_bAutoBhop[client] = true;
	else
		g_bAutoBhop[client] = false;
}
