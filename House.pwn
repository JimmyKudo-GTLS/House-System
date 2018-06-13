/*
}=====================================[Kudo's House System]============================================={
|Current Version: 1.0                                                                                   |
|For a full list of features, visit Forum thread.                                                       |
|__ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ __ _|				*/


//==================={Includes}=========================

#include <a_samp> //SAMP Team
#include <a_mysql> //BlueG - MySQL R41-4
#include <streamer> //streamer - Y-LESS
#include <sscanf2> //sscanf - Y_LESS, Emmet_ and maddinat0r
#include <zones> //Zones - Cueball
#include <izcmd> //Zeex
//======================================================

//============={MySQL Defines}================
#define DB_HOST "localhost"
#define DB_USER "root"
#define DB_NAME "csrp"
#define DB_PASS ""
//============================================

//==========={Other Defines & Variables}====
new MySQL:sqlConn; //Connection Establisher
new TotalHouses = 0;

//Pickup IDs
#define PICKUP_NEWHOUSE 19524 //Yellow House Icon
#define PICKUP_HOUSWOWNED 1273 //Green House Icon

#define GREEN_COLOR 0x33AA33AA
#define MAX_HOUSES 1000  //Because, 1024 is the limit of Global/Player 3DTextLabels.

//==========================================

//=================={forwards}================

forward LoadHouses(); //For Loading houses from database
forward OnCreateHouse(playerid, houseID, price, Float:HX, Float:HY, Float:HZ);
forward OnDeleteHouse(playerid, houseID);
forward OnDeleteAllHouses(playerid);
forward OnUpdateHouseExterior(playerid, HouseID, Float:HX, Float:HY, Float:HZ, Interior);
forward OnUpdateHouseInterior(playerid, HouseID, Float:HX, Float:HY, Float:HZ, Interior);
forward OnUpdateHouseDesc(playerid, HouseID, desc[]);
forward OnUpdateHouseOwner(playerid, HouseID, owner[]);
forward OnUpdateHousePrice(playerid, HouseID, price);
forward OnHouseLeft(playerid, HouseID);
forward OnHouseSold(playerid, targetid, HouseID, price);
forward SendPlayerInside(playerid, HouseID);
forward SendPlayerOutside(playerid, HouseID);

//============================================

//==============={Enums}======================
enum hInfo
{
	hID,
	hAdd[35],
	Text3D: hLabel,
	hDesc[128],
	bool:hOwned,
	hOwner[MAX_PLAYER_NAME+1],
	bool:hLocked,
	hMapIcon,
	hPickupModel,
	hPrice,
	hInteriorE,
	hInteriorI,
	Float: hExteriorX,
	Float: hExteriorY,
	Float: hExteriorZ,
	Float: hInteriorX,
	Float: hInteriorY,
	Float: hInteriorZ,
	bool:hCustInt,
 	bool:hIDUsed
};
new HouseInfo[MAX_HOUSES][hInfo];
//============================================

/*Dialogs*/

#define DIALOG_EDIT_HOUSE_1 1000
#define	DIALOG_EDIT_HOUSE_2 1001
#define	DIALOG_EDIT_EXTERIOR 1002
#define	DIALOG_EXT_X 1003
#define	DIALOG_EXT_Y 1004
#define	DIALOG_EXT_Z 1005
#define	DIALOG_EDIT_INTERIOR 1006
#define	DIALOG_INT_X 1007
#define	DIALOG_INT_Y 1008
#define	DIALOG_INT_Z 1009
#define DIALOG_INT_I 1010
#define	DIALOG_EDIT_DESC 1011
#define	DIALOG_EDIT_OWNER 1012
#define DIALOG_EDIT_PRICE 1013
#define DIALOG_HOUSE_ACCEPT 1014
#define DIALOG_HOUSE_LEAVE 1015

public OnFilterScriptInit()
{
	print("\n==========[House System Loaded]=========");
	print(" \n");
	print("==========================================\n");
	
	
	sqlConn = mysql_connect(DB_HOST, DB_USER, DB_PASS, DB_NAME);

	if(mysql_errno() != 0)
		printf ("\nConnection from Database Failed.\n");

	else printf ("\nConnected to Database.\n");

	mysql_log(ERROR | WARNING);
	
	mysql_tquery(sqlConn,"SELECT * from `houses`","LoadHouses"); //Loading Houses
	
	return 1;
}

public OnFilterScriptExit()
{
	DestroyAllDynamicMapIcons();
	DestroyAllDynamic3DTextLabels();
	DestroyAllDynamicPickups();
	return 1;
}

public OnPlayerConnect(playerid)
{
	SetPVarInt(playerid, "DeletingHouseID", -1);
	return 1;
}

//====================================================[Other Functions]========================================
GetHouseID()
{
	for(new i=0;i<MAX_HOUSES;i++)
	{
		if(!HouseInfo[i][hIDUsed])
			return i;
	}
	return MAX_HOUSES;
}

PlayerToPoint(Float:radi, playerid, Float:x, Float:y, Float:z)
{
  if(IsPlayerConnected(playerid))
  {
    new Float:oldposx, Float:oldposy, Float:oldposz;
    new Float:tempposx, Float:tempposy, Float:tempposz;
    GetPlayerPos(playerid, oldposx, oldposy, oldposz);
    tempposx = (oldposx -x);
    tempposy = (oldposy -y);
    tempposz = (oldposz -z);
    if (((tempposx < radi) && (tempposx > -radi)) && ((tempposy < radi) && (tempposy > -radi)) && ((tempposz < radi) && (tempposz > -radi)))
    {
      return 1;
    }
  }
  return 0;
}

GetNearbyHouse(playerid)
{
	for(new i=0; i<MAX_HOUSES; i++)
  	{
      if(PlayerToPoint(1.5, playerid, HouseInfo[i][hExteriorX], HouseInfo[i][hExteriorY], HouseInfo[i][hExteriorZ]))
      	return i;
  	}
	return MAX_HOUSES;
}
GetHouseExitPoint(playerid)
{
    for(new i=0; i<MAX_HOUSES; i++)
  	{
      if(PlayerToPoint(1.5, playerid, HouseInfo[i][hInteriorX], HouseInfo[i][hInteriorY], HouseInfo[i][hInteriorZ]))
      	return i;
  	}
	return MAX_HOUSES;
}

stock IsNumeric(const string[])
{
	for (new i = 0, j = strlen(string); i < j; i++)
	{
		if (string[i] > '9' || string[i] < '0') return 0;
	}
    return 1;
}
//==========================[Custom Public functions]=======================
public LoadHouses()
{
	    
    if(!cache_num_rows())
		return printf("\n[Houses]: 0 Houses were loaded.\n");

	new Label[128], rows;
	cache_get_row_count(rows);
	

	TotalHouses = rows;
	for(new i=0;i<rows;i++)
	{
        cache_get_value_name_int(i, "ID", HouseInfo[i][hID]);

		cache_get_value_name(i, "Address", HouseInfo[i][hAdd], 35);
		cache_get_value_name(i, "Description",HouseInfo[i][hDesc], 128);
		cache_get_value_name(i, "Owner", HouseInfo[i][hOwner], MAX_PLAYER_NAME+1);

  		cache_get_value_name_int(i, "Owned", bool:HouseInfo[i][hOwned]);
        cache_get_value_name_int(i, "Locked", bool:HouseInfo[i][hLocked]);
        cache_get_value_name_int(i, "Price", HouseInfo[i][hPrice]);
        cache_get_value_name_int(i, "InteriorE", HouseInfo[i][hInteriorE]);
        cache_get_value_name_int(i, "InteriorI", HouseInfo[i][hInteriorI]);
        
        cache_get_value_name_float(i, "ExteriorX", HouseInfo[i][hExteriorX]);
        cache_get_value_name_float(i, "ExteriorY", HouseInfo[i][hExteriorY]);
        cache_get_value_name_float(i, "ExteriorZ", HouseInfo[i][hExteriorZ]);
        
        cache_get_value_name_float(i, "InteriorX", HouseInfo[i][hInteriorX]);
        cache_get_value_name_float(i, "InteriorY", HouseInfo[i][hInteriorY]);
        cache_get_value_name_float(i, "InteriorZ", HouseInfo[i][hInteriorZ]);
        
        cache_get_value_name_int(i, "Custom_Interior", bool:HouseInfo[i][hCustInt]);


		//Assigning the Values and all:
		HouseInfo[i][hPickupModel] = CreateDynamicPickup(PICKUP_NEWHOUSE, 1, HouseInfo[i][hExteriorX],  HouseInfo[i][hExteriorY],  HouseInfo[i][hExteriorZ], 0, 0);
		HouseInfo[i][hIDUsed] = true;

		if(HouseInfo[i][hOwned])
		{
            format(Label, sizeof(Label), "Owner: %s\n%s",HouseInfo[i][hOwner],HouseInfo[i][hAdd]);
		}
		else
		{
		    format(Label, sizeof(Label), "%s\nThis House is for sale.\n%s\nPrice: $%d\nDescription: %s\nUse /buyhouse to Buy.",HouseInfo[i][hOwner],HouseInfo[i][hAdd], HouseInfo[i][hPrice], HouseInfo[i][hDesc]);
            HouseInfo[i][hMapIcon] = CreateDynamicMapIcon(HouseInfo[i][hExteriorX], HouseInfo[i][hExteriorY], HouseInfo[i][hExteriorZ], 31, 1);
		}
		HouseInfo[i][hLabel] = CreateDynamic3DTextLabel(Label, GREEN_COLOR, HouseInfo[i][hExteriorX], HouseInfo[i][hExteriorY], HouseInfo[i][hExteriorZ]+0.5,30.0, .testlos = 1, .streamdistance = 30.0);
	}
	printf("\n[Houses]: %d Houses were loaded.\n",rows);
	return 1;
}

public OnCreateHouse(playerid, houseID, price, Float:HX, Float:HY, Float:HZ)
{
	TotalHouses++;
	HouseInfo[houseID][hExteriorX] = HX;
	HouseInfo[houseID][hExteriorY] = HY;
	HouseInfo[houseID][hExteriorZ] = HZ;
	HouseInfo[houseID][hInteriorE] = 0;
	HouseInfo[houseID][hOwned] = false;
	HouseInfo[houseID][hID] = houseID;
	HouseInfo[houseID][hPrice] = price;
	HouseInfo[houseID][hIDUsed] = true;

	new Label[128];
	format(Label, sizeof(Label), "%s\nThis House is for sale.\n%s\nPrice: $%d\nDescription: %s\nUse /buyhouse to Buy.",HouseInfo[houseID][hOwner],HouseInfo[houseID][hAdd], HouseInfo[houseID][hPrice], HouseInfo[houseID][hDesc]);

	HouseInfo[houseID][hLabel] = CreateDynamic3DTextLabel(Label, GREEN_COLOR, HouseInfo[houseID][hExteriorX], HouseInfo[houseID][hExteriorY], HouseInfo[houseID][hExteriorZ]+0.5,30.0, .testlos = 1, .streamdistance = 30.0);
	HouseInfo[houseID][hMapIcon] = CreateDynamicMapIcon(HouseInfo[houseID][hExteriorX], HouseInfo[houseID][hExteriorY], HouseInfo[houseID][hExteriorZ], 31, 1);
	HouseInfo[houseID][hPickupModel] = CreateDynamicPickup(PICKUP_NEWHOUSE, 1, HouseInfo[houseID][hExteriorX],  HouseInfo[houseID][hExteriorY],  HouseInfo[houseID][hExteriorZ], 0, 0);
	format(Label, sizeof(Label), "You have Created a House. House ID: %d. Total Houses Now: %d",houseID, TotalHouses);
	SendClientMessage(playerid, 0xFFFF00AA, Label);
	return 1;
}

public OnDeleteHouse(playerid, houseID)
{
	TotalHouses--;
	if(TotalHouses <= 0) TotalHouses = 0;
	HouseInfo[houseID][hIDUsed] = false;
	HouseInfo[houseID][hID] = MAX_HOUSES;
	DestroyDynamicPickup(HouseInfo[houseID][hPickupModel]);
	DestroyDynamicMapIcon(HouseInfo[houseID][hMapIcon]);
	DestroyDynamic3DTextLabel(HouseInfo[houseID][hLabel]);

	new str[65];
	format(str, sizeof(str), "You have Deleted a House. House ID: %d. TotalHouses Now: %d",houseID,TotalHouses);
	SendClientMessage(playerid, 0xFFAABBFF, str);
	return 1;
}

public OnDeleteAllHouses(playerid)
{
	for(new houseID=0;houseID < TotalHouses; houseID++)
	{
	    if(!HouseInfo[houseID][hIDUsed]) continue;
		HouseInfo[houseID][hIDUsed] = false;
		HouseInfo[houseID][hID] = MAX_HOUSES;
		DestroyDynamicPickup(HouseInfo[houseID][hPickupModel]);
		DestroyDynamicMapIcon(HouseInfo[houseID][hMapIcon]);
		DestroyDynamic3DTextLabel(HouseInfo[houseID][hLabel]);
	}
	TotalHouses=0;
	new str[65];
	format(str, sizeof(str), "You have Deleted all Houses.");
	SendClientMessage(playerid, 0xFFAABBFF, str);
	return 1;
}

public OnUpdateHouseExterior(playerid, HouseID, Float:HX, Float:HY, Float:HZ, Interior)
{
	HouseInfo[HouseID][hExteriorX] = HX;
	HouseInfo[HouseID][hExteriorY] = HY;
	HouseInfo[HouseID][hExteriorZ] = HZ;
	
	HouseInfo[HouseID][hInteriorE] = Interior;

	DestroyDynamicPickup(HouseInfo[HouseID][hPickupModel]);
	DestroyDynamicMapIcon(HouseInfo[HouseID][hMapIcon]);
	DestroyDynamic3DTextLabel(HouseInfo[HouseID][hLabel]);
	
	new Label[128];
	if(HouseInfo[HouseID][hOwned]) format(Label, sizeof(Label), "Owner: %s\n%s",HouseInfo[HouseID][hOwner],HouseInfo[HouseID][hAdd]);
	else format(Label, sizeof(Label), "%s\nThis House is for sale.\n%s\nPrice: $%d\nDescription: %s\nUse /buyhouse to Buy.",HouseInfo[HouseID][hOwner],HouseInfo[HouseID][hAdd], HouseInfo[HouseID][hPrice], HouseInfo[HouseID][hDesc]);

	HouseInfo[HouseID][hLabel] = CreateDynamic3DTextLabel(Label, GREEN_COLOR, HouseInfo[HouseID][hExteriorX], HouseInfo[HouseID][hExteriorY], HouseInfo[HouseID][hExteriorZ]+0.5,30.0, .testlos = 1, .streamdistance = 30.0);
	HouseInfo[HouseID][hMapIcon] = CreateDynamicMapIcon(HouseInfo[HouseID][hExteriorX], HouseInfo[HouseID][hExteriorY], HouseInfo[HouseID][hExteriorZ], 31, 1);
	HouseInfo[HouseID][hPickupModel] = CreateDynamicPickup(PICKUP_NEWHOUSE, 1, HouseInfo[HouseID][hExteriorX],  HouseInfo[HouseID][hExteriorY],  HouseInfo[HouseID][hExteriorZ], 0, 0);

	SetPVarInt(playerid, "EditingHouse", MAX_HOUSES);

	SendClientMessage(playerid, 0xAAFF77, "You have successfully edited this house's exterior");
	return 1;
}

public OnUpdateHouseInterior(playerid, HouseID, Float:HX, Float:HY, Float:HZ, Interior)
{
    HouseInfo[HouseID][hInteriorX] = HX;
	HouseInfo[HouseID][hInteriorY] = HY;
	HouseInfo[HouseID][hInteriorZ] = HZ;

	HouseInfo[HouseID][hInteriorI] = Interior;
	
	SetPVarInt(playerid, "EditingHouse", MAX_HOUSES);
	SendClientMessage(playerid, 0xAAFF77, "You have successfully edited this house's Interior.");
	return 1;
}

public OnUpdateHouseDesc(playerid, HouseID, desc[])
{
	format(HouseInfo[HouseID][hDesc], 128 ,"%s",desc);
	new Label[128];
	
	if(HouseInfo[HouseID][hOwned]) format(Label, sizeof(Label), "Owner: %s\n%s",HouseInfo[HouseID][hOwner],HouseInfo[HouseID][hAdd]);
	else format(Label, sizeof(Label), "%s\nThis House is for sale.\n%s\nPrice: $%d\nDescription: %s\nUse /buyhouse to Buy.",HouseInfo[HouseID][hOwner],HouseInfo[HouseID][hAdd], HouseInfo[HouseID][hPrice], HouseInfo[HouseID][hDesc]);

	UpdateDynamic3DTextLabelText(HouseInfo[HouseID][hLabel], GREEN_COLOR, Label);
	SetPVarInt(playerid, "EditingHouse", MAX_HOUSES);
	SendClientMessage(playerid, 0xAAFF77, "You have successfully edited this house's Description.");
	return 1;
}

public OnUpdateHouseOwner(playerid, HouseID, owner[])
{
	DestroyDynamicMapIcon(HouseInfo[HouseID][hMapIcon]);
    format(HouseInfo[HouseID][hOwner],25,"%s",owner);
	new Label[128];
	
	if(!strcmp(owner, "The State", true))
		HouseInfo[HouseID][hOwned] = false;

	else HouseInfo[HouseID][hOwned] = true;

	if(HouseInfo[HouseID][hOwned]) format(Label, sizeof(Label), "Owner: %s\n%s",HouseInfo[HouseID][hOwner],HouseInfo[HouseID][hAdd]);
	else
	{
		format(Label, sizeof(Label), "%s\nThis House is for sale.\n%s\nPrice: $%d\nDescription: %s\nUse /buyhouse to Buy.",HouseInfo[HouseID][hOwner],HouseInfo[HouseID][hAdd], HouseInfo[HouseID][hPrice], HouseInfo[HouseID][hDesc]);
        HouseInfo[HouseID][hMapIcon] = CreateDynamicMapIcon(HouseInfo[HouseID][hExteriorX], HouseInfo[HouseID][hExteriorY], HouseInfo[HouseID][hExteriorZ], 31, 1);
	}
	UpdateDynamic3DTextLabelText(HouseInfo[HouseID][hLabel], GREEN_COLOR, Label);
	SetPVarInt(playerid, "EditingHouse", MAX_HOUSES);
	if(GetPVarInt(playerid, "IsHouseAdmin")) SendClientMessage(playerid, 0xAAFF77, "You have successfully edited this house's Owner.");
	else SendClientMessage(playerid, 0xAAFF77, "You have successfully bought this house!");
	return 1;
}

public OnUpdateHousePrice(playerid, HouseID, price)
{
	HouseInfo[HouseID][hPrice] = price;
	
	if(!HouseInfo[HouseID][hOwned])
	{
	    new Label[128];
		format(Label, sizeof(Label), "%s\nThis House is for sale.\n%s\nPrice: $%d\nDescription: %s\nUse /buyhouse to Buy.",HouseInfo[HouseID][hOwner],HouseInfo[HouseID][hAdd], HouseInfo[HouseID][hPrice], HouseInfo[HouseID][hDesc]);
        UpdateDynamic3DTextLabelText(HouseInfo[HouseID][hLabel], GREEN_COLOR, Label);
	}
	SetPVarInt(playerid, "EditingHouse", MAX_HOUSES);
	SendClientMessage(playerid, 0xAAFF77, "You have successfully edited this house's Price.");
	return 1;
}

public OnHouseLeft(playerid, HouseID)
{
	new str[64], HouseCost = HouseInfo[HouseID][hPrice]/2;
	format(str, sizeof(str), "Are you sure you want to leave this house? You wil recieve $%d. (Can not be undo).", HouseCost);
	ShowPlayerDialog(playerid, DIALOG_HOUSE_LEAVE, DIALOG_STYLE_MSGBOX,"Are you sure?",str,"{00FF00}Accept","{FF0000}Reject");
	SetPVarInt(playerid, "HouseLeaving",HouseID);
	return 1;
}

public OnHouseSold(playerid, targetid, HouseID, price)
{
    new str[100];
    new pName[MAX_PLAYER_NAME+1]; GetPlayerName(targetid, pName, sizeof(pName));
    format(str, sizeof(str), "You offered {00FFFF}%s {FFFFFF}to buy your house for {FFFF00}$%d{FFFFFF}. Waiting for their reply.",pName, price);
    SendClientMessage(playerid, -1, str);
    GetPlayerName(playerid, pName, sizeof(pName));
	format(str, sizeof(str), "%s wants to sell you his house for $%d. Do you accept?", pName, price);
	ShowPlayerDialog(targetid, DIALOG_HOUSE_ACCEPT, DIALOG_STYLE_MSGBOX,"{FFFFFF}Are you sure?",str,"{00FF00}Accept","{FF0000}Reject");
	SetPVarInt(targetid, "HouseBuying",HouseID);
	SetPVarInt(targetid, "HousePrice",price);
	SetPVarInt(targetid, "BuyingFrom",playerid);
	return 1;
}

public SendPlayerInside(playerid, HouseID)
{
	if(HouseID == MAX_HOUSES) return SendClientMessage(playerid, GREEN_COLOR, "You need to be at a house door.");
	if(HouseInfo[HouseID][hLocked]) return SendClientMessage(playerid, 0xCCAA11FF,"This House is locked.");
	new pName[MAX_PLAYER_NAME+1];
	GetPlayerName(playerid, pName, sizeof(pName));
	if(HouseInfo[HouseID][hLocked] && HouseInfo[HouseID][hOwned] &&!strcmp(pName, HouseInfo[HouseID][hOwner])) return SendClientMessage(playerid, 0xCCAA11FF,"This is your house but its locked. Use /hlock to unlock it.");
	new Float:hx = HouseInfo[HouseID][hInteriorX], Float:hy = HouseInfo[HouseID][hInteriorY], Float:hz = HouseInfo[HouseID][hInteriorZ], hint=HouseInfo[HouseID][hInteriorI], hvw=HouseInfo[HouseID][hID];
	SetPlayerPos(playerid, hx, hy, hz);
	SetPlayerInterior(playerid, hint);
	SetPlayerVirtualWorld(playerid, hvw);
	SendClientMessage(playerid, 0xFF3300FF, "You have Entered a House.");
	SetPVarInt(playerid, "InsideHouse", HouseID);
	return 1;
}

public SendPlayerOutside(playerid, HouseID)
{
	if(HouseID != MAX_HOUSES)
	{
		new Float:hx = HouseInfo[HouseID][hExteriorX], Float:hy = HouseInfo[HouseID][hExteriorY], Float:hz = HouseInfo[HouseID][hExteriorZ], hint=HouseInfo[HouseID][hInteriorE];
		SetPlayerPos(playerid, hx, hy, hz);
		SetPlayerInterior(playerid, hint);
		SetPlayerVirtualWorld(playerid, 0);
		SendClientMessage(playerid, 0xFF3300FF, "You have Exited  a House.");
	}
	else SendClientMessage(playerid, 0xFF3300FF, "You need to be at house exit.");
	return 1;
}

//====================================================================================================

//==================================[Commands]========================================================
CMD:sethadmin(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xF719E166, "[!]you need to be RCON admin to be able to make someone House Admin.");
	
	new giveplayerid, string[65], name[25];
	if(sscanf(params, "u",giveplayerid)) return SendClientMessage(playerid, 0x00FFFFFF, "Usage: /sethadmin [playerid]");
	GetPlayerName(giveplayerid, name, sizeof(name));

	if(GetPVarInt(giveplayerid, "IsHouseAdmin") == 0)
	{
		SetPVarInt(giveplayerid, "IsHouseAdmin", 1);
		SendClientMessage(giveplayerid,-1,"You were made a House Admin.");
		format(string, sizeof(string), "You have made %s[%d] a House Admin. Use /sethadmin again to remove him.", name, giveplayerid);
		SendClientMessage(playerid, -1, string);
	}
	else
	{
        SetPVarInt(giveplayerid, "IsHouseAdmin", 0);
		SendClientMessage(giveplayerid,-1, "Your House Admin privileges were taken away..");
		format(string, sizeof(string), "You have revoked  %s[%d]'s  House Admin status. Use /sethadmin again to make him one.", name, giveplayerid);
		SendClientMessage(playerid, -1, string);
	}
	return 1;
}

CMD:createhouse(playerid, params[])
{
	if(GetPVarInt(playerid, "IsHouseAdmin") == 0) return SendClientMessage(playerid, 0xF719E166, "[!]you need to be house admin inorder to use this command.");

	new desc[128],price, houseID = GetHouseID();
	if(houseID == MAX_HOUSES) return SendClientMessage(playerid, 0x66FFFFAA, "Cant add more houses.");
	if(sscanf(params,"s[128]i",desc,price)) return SendClientMessage(playerid, -1, "Usage:/housecreate [description] [price]");

	new Float:PX, Float:PY, Float:PZ, query[512],zone[28], add[35];
	GetPlayerPos(playerid, PX, PY, PZ);
	GetPlayer2DZone(playerid, zone, sizeof(zone));
	format(add, sizeof(add), "%d, %s, Los Santos",houseID,zone);
	strmid(HouseInfo[houseID][hAdd], add, 0, sizeof(add), 255);
	strmid(HouseInfo[houseID][hDesc], desc, 0, sizeof(desc), 255);
	strmid(HouseInfo[houseID][hOwner], "The State", 0, 9, 255);		

	mysql_format(sqlConn, query, sizeof(query), "INSERT INTO `houses`(`ID`,`ExteriorX`,`ExteriorY`, `ExteriorZ`, `Address`,`Price`, `Description`) VALUES (%d, %f, %f, %f, '%s', %i,'%s')",houseID, PX, PY, PZ, add,price, desc);
	mysql_tquery(sqlConn, query, "OnCreateHouse", "iiifff",playerid, houseID, price, PX, PY, PZ);
	return 1;
}

CMD:deletehouse(playerid, params[])
{
	if(GetPVarInt(playerid, "IsHouseAdmin") == 0) return SendClientMessage(playerid, 0xF719E166, "[!]you need to be house admin inorder to use this command.");
	new HouseID = GetNearbyHouse(playerid);
	if(HouseID == MAX_HOUSES) return SendClientMessage(playerid, 0x333333FF, "You need to be at one of the houses to delete it.");
	new Query[60];
	mysql_format(sqlConn, Query, sizeof(Query), "DELETE FROM `houses` WHERE ID = %i",HouseID);
	mysql_tquery(sqlConn, Query, "OnDeleteHouse","ii",playerid,HouseID);
	return 1;
}

CMD:deleteallhouses(playerid, params[])
{
	if(GetPVarInt(playerid, "IsHouseAdmin") == 0) return SendClientMessage(playerid, 0xF719E166, "[!]you need to be house admin inorder to use this command.");
	if(TotalHouses == 0) return SendClientMessage(playerid, 0x889900FF, "There are already 0 houses in database.");
	new Query[60];
	mysql_format(sqlConn, Query, sizeof(Query), "DELETE FROM `houses`");
	mysql_tquery(sqlConn, Query, "OnDeleteAllHouses","i",playerid);
	return 1;
}

CMD:houseedit(playerid, params[])
{
	if(GetPVarInt(playerid, "IsHouseAdmin") == 0) return SendClientMessage(playerid, 0xF719E166, "[!]you need to be house admin inorder to use this command.");
	ShowPlayerDialog(playerid, DIALOG_EDIT_HOUSE_1, DIALOG_STYLE_INPUT,"Enter House ID","Enter a House ID you want to edit.", "Proceed", "Go Back");
	return 1;
}

CMD:househelp(playerid, params[])
{
	new playercmds[128];
	format(playercmds, sizeof(playercmds)," Player Commands: /hlock{FFFF00}[Lock/Unlock House]{654321} /henter{FFFF00}[Enter House]{654321} /hexit{FFFF00}[Exit House]");
    SendClientMessage(playerid,0x654321FF, playercmds);
	format(playercmds, sizeof(playercmds),"{654321}/leavehouse{FFFF00}[Sell House to The State for Half the price]{654321} /sellhouse {FFFF00}[To sell your house to another player.]{654321}\n");
	SendClientMessage(playerid,0x654321FF, playercmds);
	format(playercmds, sizeof(playercmds),"{654321} /sellhouse {FFFF00}[To sell your house to another player.]{654321}\n");
	SendClientMessage(playerid,0x654321FF, playercmds);
    if(GetPVarInt(playerid, "IsHouseAdmin") == 1) SendClientMessage(playerid, 0x654321FF, "\n Admin Commands: /houseedit /deleteallhouses /deletehouse /createhouse");
	return 1;
}

CMD:henter(playerid, params[])
{
    new HouseID = GetNearbyHouse(playerid);
    SendPlayerInside(playerid, HouseID);
    return 1;
}

CMD:hexit(playerid, params[])
{
    new HouseID = GetHouseExitPoint(playerid);
    SendPlayerOutside(playerid, HouseID);
    return 1;
}

CMD:hlock(playerid, params[])
{
    new HouseID = GetNearbyHouse(playerid);
    if(HouseID == MAX_HOUSES) return SendClientMessage(playerid, 0x99FF33FF, "You need to be at your owned house.");
    new pName[MAX_PLAYER_NAME+1], HouseOwner[MAX_PLAYER_NAME+1];
    GetPlayerName(playerid, pName, sizeof(pName));
	format(HouseOwner, sizeof(HouseOwner), "%s",HouseInfo[HouseID][hOwner]);
	if(strcmp(pName, HouseOwner))
	{
	    SendClientMessage(playerid, 0x99FF33FF, "You need to be at your owned house.");
		return 1;
	}
	if(HouseInfo[HouseID][hLocked])
	{
			HouseInfo[HouseID][hLocked] = false;
			SendClientMessage(playerid, 0xFFFF00FF, "You have {FF0000}Unlocked{FFFF00} your house.");
	}
	else
	{
        	HouseInfo[HouseID][hLocked] = true;
			SendClientMessage(playerid, 0xFFFF00FF, "You have {FF0000}locked{FFFF00} your house.");
	}
	return 1;
}

CMD:buyhouse(playerid, params[])
{
    new HouseID = GetNearbyHouse(playerid);
    if(HouseID == MAX_HOUSES) return SendClientMessage(playerid, 0x99FF33FF, "You need to be at a house to buy it.");
	if(HouseInfo[HouseID][hOwned]) return SendClientMessage(playerid, 0x99FF33FF, "You need to be at a house which is on sale.");
	
	new query[128], pName[MAX_PLAYER_NAME+1], housecost = HouseInfo[HouseID][hPrice];
	GivePlayerMoney(playerid, -housecost);
	SendPlayerInside(playerid, HouseID);
	GetPlayerName(playerid, pName, sizeof(pName));
	mysql_format(sqlConn, query, sizeof(query), "UPDATE `houses` SET Owner='%s', Owned=1 WHERE ID=%d",pName,HouseID);
	mysql_tquery(sqlConn,query,"OnUpdateHouseOwner","iis",playerid, HouseID, pName);
	return 1;
}

CMD:leavehouse(playerid, params[])
{
	new HouseID = GetNearbyHouse(playerid);
	if(HouseID == MAX_HOUSES) return SendClientMessage(playerid, 0x99FF33FF, "You need to be at a house to buy it.");
	if(!HouseInfo[HouseID][hOwned]) return SendClientMessage(playerid, 0x99FF33FF, "You need to be at a house which is not already on sale.");
	new pName[MAX_PLAYER_NAME+1], HouseOwner[MAX_PLAYER_NAME+1];
	GetPlayerName(playerid, pName, sizeof(pName));
	format(HouseOwner, sizeof(HouseOwner), "%s",HouseInfo[HouseID][hOwner]);
	if(strcmp(HouseOwner, pName)) return SendClientMessage(playerid, 4, "You need to be at a house that you own.");
	
	new query[128];
	mysql_format(sqlConn,query, sizeof(query), "UPDATE `houses` SET Owner='The State',Owned=0 WHERE ID = %d",HouseID);
	mysql_tquery(sqlConn,query, "OnHouseLeft","ii",playerid, HouseID);
	return 1;
	
}

CMD:sellhouse(playerid, params[])
{
	new HouseID = GetNearbyHouse(playerid);
	if(HouseID == MAX_HOUSES) return SendClientMessage(playerid, 0x99FF33FF, "You need to be at a house to buy it.");
	if(!HouseInfo[HouseID][hOwned]) return SendClientMessage(playerid, 0x99FF33FF, "You need to be at a house which is not already on sale.");
	new pName[MAX_PLAYER_NAME+1], HouseOwner[MAX_PLAYER_NAME+1];
	GetPlayerName(playerid, pName, sizeof(pName));
	format(HouseOwner, sizeof(HouseOwner), "%s",HouseInfo[HouseID][hOwner]);
	if(strcmp(HouseOwner, pName)) return SendClientMessage(playerid, 4, "You need to be at a house that you own.");

	new targetid, price, Float:px, Float:py, Float:pz;
	if(sscanf(params,"ui",targetid,price)) return SendClientMessage(playerid, -1, "/sellhouse {FFFF00}[Playerid/Name] {FF00FF}[Price]");
	GetPlayerName(targetid, pName, sizeof(pName));
	GetPlayerPos(targetid, px, py, pz);
	if(!PlayerToPoint(5.0,playerid, px, py, pz)) return SendClientMessage(playerid, -1, "You are not close enough with that player.");
	
	new query[128];
	mysql_format(sqlConn,query, sizeof(query), "UPDATE `houses` SET Owner='%s',Owned=1 WHERE ID = %d",pName,HouseID);
	mysql_tquery(sqlConn,query, "OnHouseSold","iiii", playerid, targetid, HouseID, price);
	return 1;
}
//=======================================================================================================================================

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
		case DIALOG_EDIT_HOUSE_1:
		{
			if(!response) return SendClientMessage(playerid, 0x22CCCCBB, "You canceled house edditing.");
			if(!IsNumeric(inputtext)) return ShowPlayerDialog(playerid, DIALOG_EDIT_HOUSE_1, DIALOG_STYLE_INPUT,"Enter House ID","{FF0000}!{FFFFFF}You have to enter a number.", "Proceed", "Go Back");
			new hid = strval(inputtext);
			if(!HouseInfo[hid][hIDUsed]) return SendClientMessage(playerid, 0xFFFFFF, "[{FF0000}!{FF0000}]That house doesnt exist.");
			SetPVarInt(playerid, "EditingHouse",hid);
			new str[65];
			format(str, sizeof(str),"You are now edditing, House ID: {00FF13}%d",hid);
			SendClientMessage(playerid, -1, str);
			format(str, sizeof(str),"House ID:{FF0000}%d",hid);
			ShowPlayerDialog(playerid, DIALOG_EDIT_HOUSE_2,DIALOG_STYLE_LIST,str,"Change Exterior\nChange Interior\nChange Description\nSet Owner\nSet Price","Select","Back");
		}
		case DIALOG_EDIT_HOUSE_2:
		{
            if(!response){
            SetPVarInt(playerid, "EditingHouse", MAX_HOUSES);
			return SendClientMessage(playerid, 0x22CCCCBB, "You canceled house edditing."); }
			
			switch(listitem)
			{
				case 0:
				{
					ShowPlayerDialog(playerid, DIALOG_EDIT_EXTERIOR,DIALOG_STYLE_LIST,"Change House Exterior: ","Set Current Pos\nManually Enter Coordinates","Choose","Cancel");
				}
				case 1:
				{
					ShowPlayerDialog(playerid, DIALOG_EDIT_INTERIOR,DIALOG_STYLE_LIST,"Change House Interior: ","Set Current Pos\nManually Enter Coordinates","Choose","Cancel");
				}
				case 2:
				{
					ShowPlayerDialog(playerid, DIALOG_EDIT_DESC,DIALOG_STYLE_INPUT,"Change Description for House: ", "Enter new description of the house: ","Update","Cancel");
				}
				case 3:
				{
					ShowPlayerDialog(playerid, DIALOG_EDIT_OWNER, DIALOG_STYLE_INPUT,"Change House Owner: ", "Enter the name of new Owner: \n({0000FF}Hint:Type \"{000088}The State{FFFFFF}\" without quotation marks to set House Owned to false.{FFFFFF})","Update","Cancel");
				}
				case 4:
				{
					ShowPlayerDialog(playerid, DIALOG_EDIT_PRICE, DIALOG_STYLE_INPUT,"Change House Price: ", "Enter New Price for the house: ","Update","Cancel");
				}

			}

		}
		//Dialog Exterior Editing------------------------
		case DIALOG_EDIT_EXTERIOR:
		{
            if(!response){
            SetPVarInt(playerid, "EditingHouse", MAX_HOUSES);
			return SendClientMessage(playerid, 0x22CCCCBB, "You canceled house edditing."); }
			
			switch(listitem)
			{
				case 0: //Set Current Position
				{
					new Float:px, Float:py, Float:pz, pint=GetPlayerInterior(playerid), hid=GetPVarInt(playerid, "EditingHouse"), query[256];
					GetPlayerPos(playerid, px, py, pz);
					mysql_format(sqlConn,query,sizeof(query),"UPDATE `houses` SET ExteriorX=%f, ExteriorY=%f, ExteriorZ=%f, InteriorE=%d WHERE ID=%d", px, py, pz, pint, hid);
					mysql_tquery(sqlConn,query,"OnUpdateHouseExterior","ifffii",playerid, hid,  px, py, pz, pint);
				}
				case 1: //Manually Add Coordinates
				{
					ShowPlayerDialog(playerid, DIALOG_EXT_X, DIALOG_STYLE_INPUT,"Exterior X","Insert Coordinate :{FF0000} X","Next","Cancel");
				}
			}
		}
		case DIALOG_EXT_X:
		{
            if(!response){
            SetPVarInt(playerid, "EditingHouse", MAX_HOUSES);
			return SendClientMessage(playerid, 0x22CCCCBB, "You canceled house edditing."); }

			new Float:hx = floatstr(inputtext);
		 	SetPVarFloat(playerid, "PlayerHX", hx);
			ShowPlayerDialog(playerid, DIALOG_EXT_Y, DIALOG_STYLE_INPUT,"Exterior Y","Insert Coordinate :{00FF00} Y","Next","Cancel");
		}
		case DIALOG_EXT_Y:
		{
            if(!response){
            SetPVarInt(playerid, "EditingHouse", MAX_HOUSES);
			return SendClientMessage(playerid, 0x22CCCCBB, "You canceled house edditing."); }

			new Float:hy = floatstr(inputtext);
		 	SetPVarFloat(playerid, "PlayerHY", hy);
			ShowPlayerDialog(playerid, DIALOG_EXT_Z, DIALOG_STYLE_INPUT,"Exterior Z","Insert Coordinate :{0000FF} Z","Finish","Cancel");
		}
		case DIALOG_EXT_Z:
		{
            if(!response){
            SetPVarInt(playerid, "EditingHouse", MAX_HOUSES);
			return SendClientMessage(playerid, 0x22CCCCBB, "You canceled house edditing."); }

			new query[256], Float:hz = floatstr(inputtext), Float:hx = GetPVarFloat(playerid, "PlayerHX"), Float:hy = GetPVarFloat(playerid, "PlayerHY"), hid = GetPVarInt(playerid, "EditingHouse"), pint = GetPlayerInterior(playerid);
			mysql_format(sqlConn,query,sizeof(query),"UPDATE `houses` SET ExteriorX=%f, ExteriorY=%f, ExteriorZ=%f, InteriorE=%d WHERE ID=%d", hx, hy, hz, pint, hid);
			mysql_tquery(sqlConn,query,"OnUpdateHouseExterior","ifffii",playerid, hid,  hx, hy, hz, pint);
		}
		//----------------------------------------------------
		//Dialog Interior Editing-----------------------------
		case DIALOG_EDIT_INTERIOR:
		{
            if(!response){
            SetPVarInt(playerid, "EditingHouse", MAX_HOUSES);
			return SendClientMessage(playerid, 0x22CCCCBB, "You canceled house edditing."); }

			switch(listitem)
			{
				case 0: //Set Current Position
				{
					new Float:px, Float:py, Float:pz, pint=GetPlayerInterior(playerid), hid=GetPVarInt(playerid, "EditingHouse"), query[256];
					GetPlayerPos(playerid, px, py, pz);
					mysql_format(sqlConn,query,sizeof(query),"UPDATE `houses` SET InteriorX=%f, InteriorY=%f, InteriorZ=%f, InteriorI=%d WHERE ID=%d", px, py, pz, pint, hid);
					mysql_tquery(sqlConn,query, "OnUpdateHouseInterior", "ifffii", playerid, hid,  px, py, pz, pint);
				}
				case 1: //Manually Add Coordinates
				{
					ShowPlayerDialog(playerid, DIALOG_INT_X, DIALOG_STYLE_INPUT,"Interior X","Insert Coordinate :{FF0000} X","Next","Cancel");
				}
			}
		}
		case DIALOG_INT_X:
		{
            if(!response){
            SetPVarInt(playerid, "EditingHouse", MAX_HOUSES);
			return SendClientMessage(playerid, 0x22CCCCBB, "You canceled house edditing."); }

			new Float:hx = floatstr(inputtext); SetPVarFloat(playerid, "PlayerHX", hx);
			ShowPlayerDialog(playerid, DIALOG_INT_Y, DIALOG_STYLE_INPUT,"Interior Y","Insert Coordinate :{00FF00} Y","Next","Cancel");
		}
		case DIALOG_INT_Y:
		{
            if(!response){
            SetPVarInt(playerid, "EditingHouse", MAX_HOUSES);
			return SendClientMessage(playerid, 0x22CCCCBB, "You canceled house edditing."); }

			new Float:hy = floatstr(inputtext); SetPVarFloat(playerid, "PlayerHY", hy);
			ShowPlayerDialog(playerid, DIALOG_INT_Z, DIALOG_STYLE_INPUT,"Interior Z","Insert Coordinate :{0000FF} Z","Next","Cancel");
		}
		case DIALOG_INT_Z:
		{
            if(!response){
            SetPVarInt(playerid, "EditingHouse", MAX_HOUSES);
			return SendClientMessage(playerid, 0x22CCCCBB, "You canceled house edditing."); }

            new Float:hz = floatstr(inputtext); SetPVarFloat(playerid, "PlayerHZ", hz);
			ShowPlayerDialog(playerid, DIALOG_INT_I, DIALOG_STYLE_INPUT,"Interior ID","Enter Value for Interior ID","Finish","Cancel");
		}
		case DIALOG_INT_I:
		{
		    if(!response){
            SetPVarInt(playerid, "EditingHouse", MAX_HOUSES);
			return SendClientMessage(playerid, 0x22CCCCBB, "You canceled house edditing."); }

			new query[256], pint = strval(inputtext), Float:hz = GetPVarFloat(playerid, "PlayerHZ"), Float:hx = GetPVarFloat(playerid, "PlayerHX"), Float:hy = GetPVarFloat(playerid, "PlayerHY"), hid = GetPVarInt(playerid, "EditingHouse");
			mysql_format(sqlConn,query,sizeof(query),"UPDATE `houses` SET InteriorX=%f, InteriorY=%f, InteriorZ=%f, InteriorI=%d WHERE ID=%d", hx, hy, hz, pint, hid);
			mysql_tquery(sqlConn,query, "OnUpdateHouseInterior", "ifffii", playerid, hid,  hx, hy, hz, pint);
		}
		//------------------------------------------------------
		case DIALOG_EDIT_DESC:
		{
            if(!response){
            SetPVarInt(playerid, "EditingHouse", MAX_HOUSES);
			return SendClientMessage(playerid, 0x22CCCCBB, "You canceled house edditing."); }
			if(strlen(inputtext) > 128)
			{
			    ShowPlayerDialog(playerid, DIALOG_EDIT_DESC, DIALOG_STYLE_INPUT,"Change Description for House: ", "Invalid size! Max Lenght allowed: 128 Characters ","Update","Cancel");
			}
			new query[128], hid=GetPVarInt(playerid, "EditingHouse"),desc[128];
			format(desc, sizeof(desc), "%s",inputtext);
			mysql_format(sqlConn, query, sizeof(query), "UPDATE `houses` SET Description = '%s' WHERE ID=%i",desc,hid);
			mysql_tquery(sqlConn, query, "OnUpdateHouseDesc","iis",playerid, hid, desc);
		}
		case DIALOG_EDIT_OWNER:
		{
            if(!response){
            SetPVarInt(playerid, "EditingHouse", MAX_HOUSES);
			return SendClientMessage(playerid, 0x22CCCCBB, "You canceled house edditing."); }
			
			if(strlen(inputtext) > 25)
			{
			    ShowPlayerDialog(playerid, DIALOG_EDIT_OWNER,DIALOG_STYLE_INPUT,"Change House Owner: ", "Invalid Name size. Max Length Allowed: 24 Characters","Update","Cancel");
			}
			new query[128], hid=GetPVarInt(playerid, "EditingHouse"), owner[MAX_PLAYER_NAME+1];
			format(owner, sizeof(owner), "%s",inputtext);
			if(!strcmp(owner,"The State",true))
			{
				mysql_format(sqlConn, query, sizeof(query), "UPDATE `houses` SET Owner='The State',Owned=0 WHERE ID=%d",hid);
			}
			else mysql_format(sqlConn, query, sizeof(query), "UPDATE `houses` SET Owner='%s', Owned=1 WHERE ID=%d", owner, hid);

			mysql_tquery(sqlConn,query,"OnUpdateHouseOwner","iis", playerid, hid, owner);
		}
		case DIALOG_EDIT_PRICE:
		{
            if(!response){
            SetPVarInt(playerid, "EditingHouse", MAX_HOUSES);
			return SendClientMessage(playerid, 0x22CCCCBB, "You canceled house edditing."); }
			
			if(!IsNumeric(inputtext)) return SendClientMessage(playerid, -1, "Invalid{0000FF}Price{FFFFFF}!");
			new price = strval(inputtext); if(price < 1) return SendClientMessage(playerid, 0xFF0000, "Minimum Price 0.");
			new query[128], hid = GetPVarInt(playerid, "EditingHouse");
			mysql_format(sqlConn, query, sizeof(query),"UPDATE `houses` SET Price=%d WHERE ID=%d",price,hid);
			mysql_tquery(sqlConn, query, "OnUpdateHousePrice","iii",playerid, hid, price);
		}
		case DIALOG_HOUSE_LEAVE:
		{
		    if(!response) return SendClientMessage(playerid, 0x22CCCCBB, "You chose not to sell the house.");

		    new HouseID = GetPVarInt(playerid, "HouseLeaving");
            HouseInfo[HouseID][hOwned] = false;
			format(HouseInfo[HouseID][hOwner],25, "The State");

			new Label[128], HouseCost = HouseInfo[HouseID][hPrice]/2;
			format(Label, sizeof(Label), "You Sold your house to the state for {FF9911}$%d.", HouseCost);
			SendClientMessage(playerid, -1, Label);
			GivePlayerMoney(playerid, HouseCost);
			
			format(Label, sizeof(Label), "%s\nThis House is for sale.\n%s\nPrice: $%d\nDescription: %s\nUse /buyhouse to Buy.",HouseInfo[HouseID][hOwner],HouseInfo[HouseID][hAdd], HouseInfo[HouseID][hPrice], HouseInfo[HouseID][hDesc]);
			UpdateDynamic3DTextLabelText(HouseInfo[HouseID][hLabel], GREEN_COLOR, Label);
		}
		case DIALOG_HOUSE_ACCEPT:
		{
            if(!response)
			{
                new str[64], pName[25], targetid = GetPVarInt(playerid, "BuyingFrom"); GetPlayerName(targetid, pName, sizeof(pName));
                format(str, sizeof(str), "%s has rejected your house offer.",pName );
				SendClientMessage(playerid, 0x22CCCCBB, "You chose not to buy the house.");
				SendClientMessage(targetid, 0x22CCCCBB, str);
            }
            else
			{
	            new HouseID = GetPVarInt(playerid, "HouseBuying"), targetid=GetPVarInt(playerid, "BuyingFrom"), price=GetPVarInt(playerid, "HousePrice");
				new pName[MAX_PLAYER_NAME+1]; GetPlayerName(playerid, pName, sizeof(pName));
				HouseInfo[HouseID][hOwned] = true;
				format(HouseInfo[HouseID][hOwner],25,"%s",pName);
				new str[100],Label[128];

				format(Label, sizeof(Label), "Owner: %s\n%s",HouseInfo[HouseID][hOwner],HouseInfo[HouseID][hAdd]);format(Label, sizeof(Label), "Owner: %s\n%s",HouseInfo[HouseID][hOwner],HouseInfo[HouseID][hAdd]);
				UpdateDynamic3DTextLabelText(HouseInfo[HouseID][hLabel], GREEN_COLOR, Label);

				format(str, sizeof(str), "You have sold your house to %s for $%d.",pName,price);
				SendClientMessage(targetid, 0x0000EEAA, str);
				GetPlayerName(targetid, pName, sizeof(pName));
				format(str, sizeof(str), "You have purchased a house from %s for $%d.Congratulations!",pName,price);
				SendClientMessage(playerid,0x0000EEAA, str);
				GivePlayerMoney(targetid, price);
				GivePlayerMoney(playerid, -price);
			}
		}
	}
	return 1;
}
