#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <multicolors>
 
#pragma newdecls required
 
bool g_bAutoBhop[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name			= "Simple AutoBhop Plugin",
	author			= "Kelyan3",
	description		= "A very simple plugin to enable auto bunny hopping forever which client can enable or disable it.",
	version			= "0.1",
	url				= ""
}
 
public void OnPluginStart()
{
	SetCookieMenuItem(MenuHandler_CookieMenu, 0, "AutoBhop");

	RegConsoleCmd("sm_autobhop", Command_AutoBhop, "Enables/Disables AutoBhop");
}
 
public void MenuHandler_CookieMenu(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	switch (action)
	{
		case (CookieMenuAction_DisplayOption):
		{
			Format(buffer, maxlen, "AutoBhop", client);
		}
		case (CookieMenuAction_SelectOption):
		{
			ShowSettingsMenu(client);
		}
	}
}
 
public void ShowSettingsMenu(int client)
{
	Menu menu = new Menu(MenuHandler_SettingsMenu);
	menu.SetTitle("AutoBhop Settings");
	menu.ExitBackButton = true;

	char sBuffer[128];
	Format(sBuffer, sizeof(sBuffer), "AutoBhop: %s", g_bAutoBhop[client] ? "Enabled" : "Disabled");
	menu.AddItem("0", sBuffer);

	menu.Display(client, MENU_TIME_FOREVER);
}
 
public int MenuHandler_SettingsMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case (MenuAction_Select):
		{
			switch (param2)
			{
				case(0): ToggleAutoBhop(param1);
			}

			ShowSettingsMenu(param1);
		}
		case (MenuAction_Cancel):
		{
			ShowCookieMenu(param1);
		}
		case (MenuAction_End):
		{
			delete menu;
		}
	}
}
 
public Action Command_AutoBhop(int client, int argc)
{
	if (!client)
	{
		ReplyToCommand(client, "[SM] You cannot use this command on the server console.");
		return Plugin_Handled;
	}

	ToggleAutoBhop(client);
	return Plugin_Handled;
}
 
public void ToggleAutoBhop(int client)
{
	g_bAutoBhop[client] = !g_bAutoBhop[client];

	CPrintToChat(client, "{cyan}[AutoBhop] {white}You have %s autobhop", g_bAutoBhop[client] ? "enabled" : "disabled");
}
 
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (g_bAutoBhop[client])
	{
		if (IsPlayerAlive(client))
		{
			if (buttons & IN_JUMP)
			{
				if (!(GetEntityFlags(client) & FL_ONGROUND))
				{
					if (!(GetEntityMoveType(client) & MOVETYPE_LADDER))
					{
						if (GetEntProp(client, Prop_Data, "m_nWaterLevel") <= 1)
						{
							buttons &= ~IN_JUMP;
						}
					}
				}
			}
		}
	}

	return Plugin_Continue;
}
