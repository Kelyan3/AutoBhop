#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
 
#pragma newdecls required
 
/* BOOLEAN */
bool g_bAutoBhop[MAXPLAYERS + 1];
bool g_bLateLoaded;

/* COOKIES */
Handle g_hCookie_ClientAutoBhop;

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------
public Plugin myinfo =
{
	name			= "AutoBhop",
	description		= "Allows clients to toggle on/off autobunnyhopping.",
	author			= "Kelyan3",
	version			= "1.0.0",
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
	SetCookieMenuItem(MenuHandler_CookieMenu_AutoBhop, 0, "AutoBhop");

	g_hCookie_ClientAutoBhop = RegClientCookie("autobhop_cookie", "Is autobhop enabled?", CookieAccess_Protected);

	RegConsoleCmd("sm_autobhop", Command_AutoBhop, "Toggles on/off AutoBhop.");

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
}

//----------------------------------------------------------------------------------------------------
// Purpose:
//----------------------------------------------------------------------------------------------------}
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
	Format(sBuffer, sizeof(sBuffer), "AutoBhop: %s", g_bAutoBhop[client] ? "Enabled" : "Disabled");
	SettingsMenu.AddItem("0", sBuffer);

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
public Action Command_AutoBhop(int client, int argc)
{
	if (!client)
	{
		ReplyToCommand(client, "[SM] Cannot use this command on the server console.");
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
	if (!g_bAutoBhop[client])
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
