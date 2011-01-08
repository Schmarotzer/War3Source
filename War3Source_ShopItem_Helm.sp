




#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include "W3SIncs/War3Source_Interface"

new thisItem;
new String:helmSound0[]="physics/metal/metal_solid_impact_bullet1.wav";
new String:helmSound1[]="physics/metal/metal_solid_impact_bullet2.wav";
new String:helmSound2[]="physics/metal/metal_solid_impact_bullet3.wav";
new String:helmSound3[]="physics/metal/metal_solid_impact_bullet4.wav";

public Plugin:myinfo= {
	name="War3Source Shop - Helm",
	author="Ownz",
	description="War3Source",
	version="1.0",
	url="http://war3source.com/"
};



public OnPluginStart()
{
	War3_PrecacheSound(helmSound0);
	War3_PrecacheSound(helmSound1);
	War3_PrecacheSound(helmSound2);
	War3_PrecacheSound(helmSound3);
	
	LoadTranslations("w3s.item.helm.phrases");
}
public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==100){
	
		thisItem=War3_CreateShopItemT("helm",10,3500);
	}	
}
public OnClientPutInServer(client){
	SDKHook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
}
public OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack); 
}

public Action:SDK_Forwarded_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(hitgroup==1&&War3_GetOwnsItem(victim,thisItem)&&!Perplexed(victim)){
		damage=0.0;
		new random = GetRandomInt(0,3);
		if(random==0){
			EmitSoundToAll(helmSound0,victim);
		}else if(random==1){
			EmitSoundToAll(helmSound1,victim);
		}else if(random==2){
			EmitSoundToAll(helmSound2,victim);
		}else{
			EmitSoundToAll(helmSound3,victim);
		}
		if(War3_GetGame()==TF){
			decl Float:pos[3];
			GetClientEyePosition(victim, pos);
			pos[2] += 4.0;
			War3_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
		}
	}
	return Plugin_Changed;
}
public OnWar3EventDeath(victim){
	if(War3_GetOwnsItem(victim,thisItem)){
		War3_SetOwnsItem(victim,thisItem,false);
	}
}
