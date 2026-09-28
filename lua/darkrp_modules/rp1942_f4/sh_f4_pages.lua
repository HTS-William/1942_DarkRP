--[[---------------------------------------------------------------------------
1942 DarkRP - F4 text pages (Rules, RP Definitions, ...)

Every page here becomes its own tab in the F4 menu. Just type the text:

    # Heading          a line starting with "# " becomes a red bar
    #staff Heading     the same, but that section (up to the next heading)
                       only shows to staff (RP1942.F4StaffGroups below)
    - Point            a line starting with "- " becomes a bullet point
    Anything else      a normal line of text
    (empty line)       a bit of space

To add a page, copy one of the blocks below. `icon` is any Garry's Mod
silkicon (see https://wiki.facepunch.com/gmod/Silkicons), or leave it out.
Keep each page's text between its opening and closing double square
brackets, and don't type two closing square brackets in a row inside it.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

-- Who counts as staff for "#staff" sections: admins and superadmins (and any
-- group that inherits from them), plus these usergroups
RP1942.F4StaffGroups = {
    moderator = true,
    operator  = true,
}

-- Also staff: anyone ULX lets use a 42Bros command (lua/ulx/modules/sh/42bros.lua)
local ULX_STAFF = { "ulx train", "ulx event", "ulx makewanted", "ulx addmarket", "ulx factiondoor" }

function RP1942.isF4Staff(ply)
    if not IsValid(ply) then return false end
    if ply:IsAdmin() or RP1942.F4StaffGroups[ply:GetUserGroup()] == true then return true end
    if RP1942.ULX42 and RP1942.staffCan then
        for _, access in ipairs(ULX_STAFF) do
            if RP1942.staffCan(ply, access) then return true end
        end
    end
    return false
end

RP1942.F4Pages = {

    { tab = "Rules", icon = "icon16/error.png", text = [[
# General
- Rule one goes here.
- Rule two goes here.

# Roleplay
- Stay in character outside of OOC chat.
- Fill these in with your server's rules.

# Raiding
- Who can raid, when, and how often.

# Punishments
- What happens when rules are broken.
]] },

    { tab = "RP Definitions", icon = "icon16/book_open.png", text = [[
# Roleplay terms
OOC - Out of character. Type // before a message to talk in OOC chat.
IC - In character. Anything you say normally is said by your character.
NLR - New Life Rule. When you die you forget everything that led to your death, and stay away from where you died for 3 minutes.
RDM - Random Death Match. Killing someone without a roleplay reason.
Prop blocking - Using props to block players, doors or entities.
Prop surfing - Riding props to reach places you otherwise couldn't.
Prop pushing - Pushing players or entities around with props.
Exploiting - Using scripts, hacks, bugs or glitches to get an advantage.
Metagaming - Using out-of-character information (OOC chat, streams, Discord) in character.
Raiding - Breaking into someone's property to take their valuables.

# Your name
- When you first join, the Meldeamt (registration office) asks for your roleplay name: a first and a last name that fits 1942. Random Name suggests one.
- It's the name everyone sees, and the one that will go on your papers.
/register - Open the registration form again, to change your roleplay name
/rpname First Last - Change your roleplay name later

# Keys and menus
F4 - Jobs, the shop, commands and these pages
F3 - Your job's own menu, if it has one (the wardrobe for undercover jobs, the Führer's office...)
TAB - The scoreboard. Hold it to look; click a player to see their card (copy SteamID, Steam profile, mute their voice, send a message). Once you click, it stays open until you press TAB again.
E - Use things, and press buttons on machine panels (look at the button)

# Chat commands
// - Talk to everyone out of character (OOC)
.// - Talk out of character to people near you
/y - Yell, so people further away hear you
/w - Whisper
/me - Describe an action you're doing
/advert - Place an in-character advertisement
/radio - Talk on the radio
/election - Open the Führer election ballot
/roll - Roll a random number (/roll, /roll 20, /roll 5 50, /roll 2d6)
/jobmenu - Open your job's menu (same as F3)

# The factions
Civilians - Everyday people of the town: tradesmen, dealers, doctors and the like.
Resistance - Fighters working against the Reich from the shadows.
Reich - The occupying authority, made up of the units below.
Wehrmacht - The police force. Keeps order, patrols and makes arrests.
Waffen-SS - The elite special unit, called in when the Wehrmacht isn't enough.
Leibstandarte - The Führer's personal bodyguard.
Recruits - Every Reich unit starts at Recruit. Specialisations appear in the job menu once you hold the base job.
Joining the Reich - Anyone can enlist as a Recruit. Getting your rifle (Recruit to Rifleman) needs a vote of the server, and so does taking any other Reich job from outside the Reich (F4 shows Call a vote; in chat /vote plus the job's command). Once you hold a real Reich job, moving up or across is instant. The Führer is elected, and the Gestapo joins quietly, so neither is voted.
Unit music - Each unit has its own music that plays for you (only you) when you get your rifle or a higher job (not for Recruits). rp1942_job_music 0 in the console turns it off; rp1942_job_music_stop stops the current song.

# Wanted by the Reich
- Killing a member of the Reich makes you wanted. A red WANTED tag shows above your name.
- Robbing the supply train also makes you wanted.
- Being arrested or killed clears it, and so does joining the Reich. Otherwise it runs out on its own.
- Members of the Reich can't be arrested. (Undercover agents can, so their cover holds.)

# Martial law
- The Führer can declare martial law (/lockdown). A siren sounds and a banner orders everyone to stay in their homes; anyone found outside may be arrested. /unlockdown lifts it.

# Economy and taxes
- The economy bar at the bottom of the screen shows how the economy is doing. A better economy means higher wages.
- The Führer sets the tax rates. Taxes come out of your wages and go to the Reich treasury.
- The Führer can make a Reich payout: the same amount from the treasury to everyone in the factions he picks (F3, Reich payout).
- Hover the economy bar with your cursor out to see the treasury and every tax rate.
- The Führer can make a Reich payout from the treasury (F3): a total shared evenly between everyone in the factions he picks, or the same amount each. Factions with nobody online are skipped.

# Production
- Bakers, Winemakers, Petroleum Producers and Factory Owners make goods. Buy your equipment in the F4 Shop.
- Machines have brass control panels: look at a button, lever or wheel and press E.
- Ovens, oil derricks and factory lines have a POWER lever. Switching one off pauses it exactly where it is (timers, heat, pressure); switching it back on carries on. Nothing is lost.
- Goods have a quality of 1 to 3 stars: the better you tend the machine, the more you make and the better it is. Better goods sell for more.
- Goods you collect go straight into your pocket. If it's full, the rest are left on top of the machine.
- E picks goods up to carry. Shift+E eats or drinks them (bread, wine, tinned rations).
- Anyone can press a machine's buttons, so keep an eye on yours.

# Baker
- Buy a Bread Oven and Sacks of Flour. Push sacks into the oven: it holds 3 and bakes them one at a time.
- While it bakes the fire cools. STOKE FIRE to keep the needle in the green; too cold or too hot and the batch suffers.
- More time in the green means more loaves (up to 3) and more stars. COLLECT BREAD when it's done, and the next sack goes in.

# Winemaker
- Buy a Wine Barrel and press START. While it ferments it calls for stirring a few times: STIR before its timer runs out.
- Every stir it gets raises the vintage. BOTTLE when it's done for 3 bottles. The barrel is used up.

# Petroleum Producer
- Buy an Oil Derrick. It isn't placed by hand: it's built on the nearest free oil site and bolted down, and it's marked on your screen once built. If every site is taken, it isn't for sale until one frees up.
- It pumps on its own. With the valve shut the pressure climbs; turn the red valve wheel to open it and the pressure falls, then turn it again to shut it. Keep the needle in the green.
- More time in the green means more canisters of crude (up to 3) and a better grade. FILL CANISTERS when the tank is full, and it starts pumping again.
- If the pressure drops to nothing with the valve open, the pump stalls and switches itself off. Switch it back on: the pressure builds up again from zero.
- Don't leave it in the red. After a while an alarm sounds and a red light flashes; if the pressure still isn't brought down, the derrick explodes, and it's gone.

# Factory Owner
- Buy a Factory Line. It runs on its own and makes 2 goods per run.
- Twice a run it halts with a fault: the BELT, BOILER or FUSE lamp flashes. Press the matching repair button (RETHREAD BELT, VENT BOILER or REPLACE FUSE). The wrong one costs extra downtime.
- The less downtime, the better the run, and the better the odds of rare goods: common (rations, boots), uncommon (pots, kettles), rare (clocks) and very rare (radios). COLLECT when the run is done.

# Markets
- Sell goods at a market: SELL one kind of good from your pocket, SELL EVERYTHING, or push goods into the crate.
- Scroll the price board with its arrows or your mouse wheel. Goods you carry are listed first.
- Prices follow the economy, and one good is in demand each hour for a bonus. Arrows show how prices have moved. Sales are taxed like wages.
- Every market sale helps the economy a little, and a better economy means higher wages for everyone. Selling privately to other players doesn't move the economy.

# Money printers
- Banking Printer (Banker only, legal): up to 3. Every print is split with the Reich treasury: 15% when the economy is normal (50), more when it's weak, less when it's strong, so a good economy lets the Banker keep more. A Reich member who destroys a Banking Printer pays R.M. 1,250 for it, into the treasury.
- Money Printer (illegal): up to 3, for anyone outside the Reich except the Banker. It isn't tied to the economy. The Reich can SEIZE it from its panel, or shoot it, for a reward, and its owner is fined 1,250 R.M., paid to the Reich treasury.
- Printers start at 1,000 R.M. a print. Money waits in the tray: COLLECT takes it, and anyone can, so guard your printers.
- They heat up while they run and explode at 100 degrees, taking the money with them. Switch one OFF to let it cool, then back ON. At Cooling tier 5 it stays cool.
- UPGRADES (5 tiers each, bought by the owner): Output (+40% a tier on the Banking Printer, +35% on the Money Printer), Speed (prints sooner), Cooling (heats slower) and Muffler (quieter, but never silent).
- If you join the Reich or become the Banker, your illegal printers are dismantled. Leaving the Banker job returns the Banking Printers.

# Supply train
- About every 20 minutes a Reich supply train rumbles in, sounds its horn as it stops at the station, waits 30 seconds, sounds it again and carries on down the line.
- Anyone outside the Reich can hold E on it to rob a crate. The money goes into your wallet and any weapon into your pocket.
- The Reich is expected to guard it. Whatever isn't stolen goes to the Reich treasury.
- Stay off the tracks while it's moving.

# Undercover (Gestapo and Resistance Operative)
- Press F3 to open your wardrobe. Its tabs list the jobs you can pass as: civilians and the Resistance for the Gestapo, civilians and the Reich for the Operative.
- Picking one puts on that job's clothes and takes its title. Nobody is told. Jobs with several outfits open a model selection: click an outfit to preview it, then Wear This (or double-click).
- Officers, commanders, the Führer and the Resistance Leader can't be impersonated.
- You can also type any cover title in the wardrobe. Your own side always sees your faction tag over your head.
- On the scoreboard you show as your cover. Only your own side and staff see that you're undercover.

# Faction doors
- Some doors belong to a faction or a Reich unit. Its name shows on the door.
- Only members can lock and unlock them, and nobody can buy them.

# Props
- A prop you're holding with the physgun is see-through and passes through players and other props, so it can't push or hurt anyone. This goes for staff too.
- When you let go, it turns solid again as soon as nobody is standing inside it.

# Dumpsters
- Hold E on a dumpster to search it for junk, supplies, poor-quality goods you can sell at a market, and the odd weapon. Hobos find better things.
- Anything useful goes straight into your pocket. If your pocket is full, it lands on the ground.
- Everyone has their own wait before searching the same dumpster again.

# Dead drops (Resistance)
/deaddrop 500 - Hide money in the dumpster you're looking at
/deaddrop weapon - Hide the weapon in your hands
- Any Resistance member who searches that dumpster collects it: money into their wallet, weapons into their pocket. Whatever doesn't fit in their pocket stays in the drop.
- Only the Resistance can see a drop is there.
- If a member of the Reich searches it first, the drop is confiscated.

#staff Staff: where to find things
- Scoreboard (TAB): click a player for Go to, Bring, Return, Spectate, Freeze, Jail, Strip, Slay, God, Cloak, Gag, Mute, Make/Clear wanted, Kick and Ban. Only the ones your rank may use are shown.
- ULX menu (!menu > Cmds > 42Bros): every server command below, with descriptions. They also work as !commands (!train). The /chat versions work too.
- Who may use each one is set per rank in the ULX menu (Groups tab, 42Bros). The chat versions follow the same ticks.
- A player's undercover job shows on the scoreboard for staff, marked UNDERCOVER.

#staff Staff: events, economy and players
!esp - Toggle ESP: every player through walls, anywhere on the map, with name, real job (and cover), rank, health and distance
!eventsettings - World event settings: minutes between events, player minimum, retry when too few are on, each event on/off, start/stop
!setfuhrer <player> - Make someone Führer now, without an election (cancels a running one, replaces the sitting Führer)
!removefuhrer - Remove the sitting Führer from office
/train - Start the supply train now
/event - List world events. /event <id> starts one, /event stop ends the running one (also !stopevent)
!seteconomy 50 - Set the economy bar (1-110)
!treasury 5000 - Add money to the Reich treasury (a negative amount takes it away)
!makewanted <player> <reason> - Make someone wanted by the Reich
!clearwanted <player> - Clear someone's wanted status

#staff Staff: production
!prodspawn - The production spawner: ovens, flour, barrels, factory lines, derricks, markets, both printers, dumpsters and every good at any quality (into your pocket or at your crosshair). Also Finish its timer, Remove it and Save / Unsave it for the machine you're looking at. Z undoes a spawn.
/saveprod - Look at a machine or dumpster placed from !prodspawn (or any production machine): it's saved for this map and comes back after every restart, frozen and owned by nobody
/saveprodall - Save every machine you placed from !prodspawn that isn't saved yet
/unsaveprod - Look at a saved machine: remove it for good
/prodsaves - Count the saved machines on this map and highlight them for a minute
/addmarket - Place a market where you're looking (saved for this map)
/removemarket - Remove the market you're looking at
/addoilsite - Mark an oil site where you're looking; a bought derrick is built on the nearest free one, facing where you stood (saved for this map)
/removeoilsite - Remove the oil site nearest where you're looking, and its derrick
/oilsites - Show every oil site on this map for a minute
rp1942_panel_move / _size / _face / _mount / _print (console) - Fine-tune where a machine's panel sits, then print the line for the config

#staff Staff: map setup
/factiondoor - Look at a door and set its faction (reich, resistance, civilian, wehrmacht, waffen_ss, leibstandarte or none)
/adddumpster - Place a dumpster where you're looking (saved for this map)
/removedumpster - Remove the dumpster you're looking at
/getdumpsterpos - Copy every dumpster on this map to your clipboard as code, to hardcode them in the dumpster's config.lua
!testexplosion <damage> <radius> - Set off a test explosion where you're aiming (it does real damage)
]] },

}
