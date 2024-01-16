#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
 
#pragma newdecls required
 
/* BOOLEAN */
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
	description		= "Allows clients to toggle on/off autobunnyhopping.",
	author			= "Kelyan3",
	version			= "1.0.1",
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

	g_CVar_AutoBhopGlobal = CreateConVar("sm_autobhop_global", "0", "Specifies whether to toggle on/off AutoBhop features for players and admins.", FCVAR_NONE, true, 0.0, true, 1.0);
	g_CVar_AutoBhopGlobal.AddChangeHook(ConVarChanged_AutoBhop);

	RegAdminCmd("sm_abstatus", Command_AutoBhopStatus, ADMFLAG_BAN, "Checks a client's AutoBhop status.");

	RegConsoleCmd("sm_ab", Command_AutoBhop, "Toggles on/off AutoBhop.");
	RegConsoleCmd("sm_autobhop", Command_AutoBhop, "Toggles on/off AutoBhop.");

	g_hCookie_ClientAutoBhop = RegClientCookie("autobhop_cookie", "Is autobhop enabled?", CookieAccess_Protected);

	if (g_bLateLoaded)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i))
				continue;

			OnClientCookiesCached(i);
			OnClientPutInServer(i);
		}
	}

	AutoExecConfig(true, "plugin.AutoBhop");

	SetCookieMenuItem(MenuHandler_CookieMenu_AutoBhop, 0, "AutoBhop");
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
public void OnClientDisconnect(int client)
{
	g_bAutoBhop[client] = false;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public void OnClientCookiesCached(int client)
{
	if (!AreClientCookiesCached(client))
		return;

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
	SettingsMenu.ExitBackButton = true;

	char sBuffer[128];
	Format(sBuffer, sizeof(sBuffer), "AutoBhop: %s", g_bAutoBhopGlobal ? (g_bAutoBhop[client] ? "Enabled" : "Disabled") : "Disabled by host.");
	SettingsMenu.AddItem("0", sBuffer, g_bAutoBhopGlobal ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

	SettingsMenu.Display(client, MENU_TIME_FOREVER);
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public int MenuHandler_Menu_AutoBhopSettings(Menu SettingsMenu, MenuAction hAction, int iParam1, int iParam2)
{
	switch (hAction)
	{
		case MenuAction_Select:
		{
			switch (iParam2)
			{
				case 0: ToggleAutoBhop(iParam1);
			}

			DisplaySettingsMenu(iParam1);
		}

		case MenuAction_Cancel:
			ShowCookieMenu(iParam1);

		case MenuAction_End:
			delete SettingsMenu;
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
		ReplyToCommand(client, "[AutoBhop] Cannot use this command on the server console.");
		return Plugin_Handled;
	}

	if (argc < 1)
	{
		ReplyToCommand(client, "\x04[AutoBhop] \x01Usage: sm_abstatus <#userid|name>");
		return Plugin_Handled;
	}

	if (!g_bAutoBhopGlobal)
	{
		ReplyToCommand(client, "\x04[AutoBhop] \x01This command is currently disabled by the host.");
		return Plugin_Handled;
	}

	int iTarget;
	char sTarget[32];

	GetCmdArg(1, sTarget, sizeof(sTarget));

	if ((iTarget = FindTarget(client, sTarget, false)) <= 0)
		return Plugin_Handled;

	ReplyToCommand(client, "\x04[AutoBhop] \x01Checking \x03%N\x01's current AutoBhop status: %s", iTarget, g_bAutoBhop[iTarget] ? "\x04ON" : "\x07FF4040OFF");

	return Plugin_Handled;
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Action Command_AutoBhop(int client, int argc)
{
	if (!client)
	{
		ReplyToCommand(client, "[AutoBhop] Cannot use this command on the server console.");
		return Plugin_Handled;
	}

	if (!g_bAutoBhopGlobal)
	{
		ReplyToCommand(client, "\x04[AutoBhop] \x01This command is currently disabled by the host.");
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

	PrintToChat(client, "\x04[AutoBhop] \x01You have \x04%s \x01autobhop for yourself.", g_bAutoBhop[client] ? "enabled" : "disabled");
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

	g_bAutoBhop[client] = view_as<bool>(StringToInt(sCookieValue));
}
