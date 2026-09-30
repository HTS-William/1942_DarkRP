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
local ULX_STAFF = { "ulx train", "ulx event", "ulx makewanted", "ulx addmarket", "ulx factiondoor", "ulx banksettings" }

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
- Every job's description ends with RAID = YES or RAID = NO.
- RAID = YES: Civilian, Doctor, Thief, Pro Thief, every Resistance job, and the Reich (except the ones below).
- RAID = NO: Hobos, the producers (Baker, Winemaker, Petroleum Producer, Factory Owner), the dealers (Black Market, Cherkesov, German Supplier), the Reich Banker, the Reich Scientist and the Führer.
- When, and how often: fill this in with your server's rules.

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
- Sitting: hold your walk key (Alt by default) and press E while looking at a bench, a chair, the ground or a prop to sit there; press E again to get up. Plain E never sits, so doors, machines, dumpsters and crates keep their own E action. !sitstuck frees you if you get stuck sitting; !spawn takes you to spawn (neither works while arrested, wanted, in a fight or robbing the bank).
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
Civilians - Everyday people of the town: doctors, bankers, hobos and the like.
Production - The trades that make goods to sell: Baker, Winemaker, Petroleum Producer and Factory Owner.
Resistance - Fighters working against the Reich from the shadows. The Black Market and Cherkesov dealers are listed with them (anyone can deal). Thieves carry a lockpick; once you're a Thief, the Pro Thief (one at a time) gets a professional lockpick that's several times faster.
Reich - The occupying authority, made up of the units below.
Wehrmacht - The police force. Keeps order, patrols and makes arrests.
Waffen-SS - The elite special unit, called in when the Wehrmacht isn't enough.
Leibstandarte - The Führer's personal bodyguard (StG 44 and P38). Only for those already in the Reich: switch to it from any Reich job, no vote. Pick any of its three uniforms in F4.
Batons - Every Reich job carries the stun, arrest and unarrest batons. Reich jobs that can raid (RAID = YES) also carry a battering ram.
Riflemen - The Wehrmacht and Waffen-SS start at Rifleman. Its specialisations appear in the job menu once you hold it.
Joining the Reich - Taking a Reich job from outside the Reich needs a vote of the server (F4 shows Call a vote; in chat /vote plus the job's command, e.g. /votewehrrifleman). Once you're in, moving up or across is instant. The vote only says you'd like to join the Reich, never which job, so the Gestapo is voted in too without being exposed. The Führer is elected instead.
Unit music - Each unit has its own music that plays for you (only you) when you join it (as a Rifleman, or the Leibstandarte). Moving through its specialisations doesn't replay it. rp1942_job_music 0 in the console turns it off; rp1942_job_music_stop stops the current song.

# Wanted by the Reich
- Killing a member of the Reich makes you wanted. A red WANTED tag shows above your name.
- Robbing the supply train also makes you wanted.
- Being arrested or killed clears it, and so does joining the Reich. Otherwise it runs out on its own.
- Members of the Reich can't be arrested. (Undercover agents can, so their cover holds.)

# Fire
- Molotovs, WP grenades and the flamethrower set the ground alight, and any big explosion (grenades, dynamite, rockets, a printer or derrick going up) can leave fires behind. Fire spreads along the ground for a while, burns anyone standing in it (the thrower gets the kill) and sets props alight, then burns itself out.
- Fire never starts in water, and each patch can only grow so far.
- Fire Extinguisher (F4 Shop, Tools) - Spray at the flames to put them out, and at a burning player. It never runs out. Every fire you put out pays 20 RM, unless you lit it yourself.

# Orders
- Your faction's orders (Reich Orders, Resistance Plans) show in the top-left corner; Reich alerts appear below them. The Führer and the Reich officers set the Reich's; the Resistance Leader sets the Resistance's (/agenda). rp1942_orders_hud 0 in the console hides the panel.

# Laws
- The Führer makes the laws from his menu (F3, Laws): add, remove, reset, or place a law board. Every law board shows them. The first laws are fixed and can't be removed.

# Martial law
- The Führer can declare martial law (/lockdown). A siren sounds and a banner orders everyone to stay in their homes; anyone found outside may be arrested. /unlockdown lifts it.

# Economy and taxes
- The economy bar at the bottom of the screen shows how the economy is doing. A better economy means higher wages.
- The Führer sets the tax rates. Taxes come out of your wages and go to the Reich treasury.
- Hover the economy bar with your cursor out to see the treasury and every tax rate.
- The Führer can make a Reich payout from the treasury (F3): a total shared evenly between everyone in the factions he picks, or the same amount each. Factions with nobody online are skipped.

# Arms dealers
- The Black Market Dealer, the Cherkesov Dealer and the German Supplier buy weapons from their own stock (F3) and sell them on to other players. The weapon appears in front of you.
- Ammunition is sold in the F4 Shop (Ammunition), one box per calibre: 9mm Parabellum, 7.92mm Mauser, .45 ACP, 7.62mm Tokarev and so on. Each dealer's menu shows which ammo a weapon takes. Grenades, molotovs, mines, explosive charges, flamethrower fuel, crossbow bolts and flare rounds are sold there too. One grenade refill fits any grenade.
- Weapons come loaded: guns with a full magazine; a grenade, molotov, dynamite bundle or mine comes with itself to throw or place; the flamethrower with a tank of fuel.
- Buying more than one (set the amount next to Buy, up to 20) brings a crate: press E on it to take one weapon out at a time. Shoot a crate to pieces and what's left inside is lost.
- Black Market: anti-tank launchers, explosives and grenades, silenced guns, submachine guns and more. Cherkesov: Soviet and Allied rifles, machine guns, anti-tank rifles and more. Their prices are fixed: the economy doesn't change them.
- German Supplier (Reich): German service weapons for the Reich. Its prices follow the economy: up to 40% cheaper when the economy is strong, up to 50% dearer when it's weak. The menu shows the current difference.

# Bank robbery
- The Reichsbank vault holds the Reich treasury. Anyone outside the Reich (except the Reich Banker) can press E on it to rob it, when at least 5 Reich officials are in the city and the bank isn't on alert (45 minutes after the last robbery).
- The alarm sounds and everyone is told. The robber is WANTED. For the first 30 seconds, others can press E on the vault to ask to join; the robber decides who gets in.
- Hold the bank for 10 minutes: the robber must stay alive, free and near the vault. If the robber dies, is arrested or leaves the bank, it fails, and the Reich member who stopped them gets a reward.
- If the robber holds out, the WHOLE treasury is split evenly between the robber and the crew still alive and near the vault.

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
- More time in the green means more canisters of crude (up to 3, around R.M. 1,000 each at a market) and a better grade. FILL CANISTERS when the tank is full, and it starts pumping again.
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
- Banking Printer (Reich Banker only, legal): up to 3. Every print is split with the Reich treasury: 15% when the economy is normal (50), more when it's weak, less when it's strong, so a good economy lets the Reich Banker keep more. A Reich member who destroys a Banking Printer pays R.M. 1,250 for it, into the treasury.
- Money Printer (illegal): up to 3, for anyone outside the Reich except the Reich Banker. It isn't tied to the economy. The Reich can SEIZE it from its panel, or shoot it, for a reward, and its owner is fined 1,250 R.M., paid to the Reich treasury.
- Printers start at 1,000 R.M. a print. Money waits in the tray: COLLECT takes it, and anyone can, so guard your printers.
- They heat up while they run and explode at 100 degrees, taking the money with them. Switch one OFF to let it cool, then back ON. At Cooling tier 5 it stays cool.
- UPGRADES (5 tiers each, bought by the owner): Output (+40% a tier on the Banking Printer, +35% on the Money Printer), Speed (prints sooner), Cooling (heats slower) and Muffler (quieter, but never silent).
- If you join the Reich or become the Reich Banker, your illegal printers are dismantled. Leaving the Reich Banker job returns the Banking Printers.

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
- ULX menu (!menu > Cmds > 42Bros): every server command below, with descriptions. Type them with ! in chat (!train) or ulx in console (ulx train). There are no / versions.
- Who may use each one is set per rank in the ULX menu (Groups tab, 42Bros).
- A player's undercover job shows on the scoreboard for staff, marked UNDERCOVER.
- Staff tools (keypad checker, ram, batons, weapon checker) only come with the Staff on Duty job, at the bottom of the job list (only staff see it). Go on duty to handle a sit; in any other job you spawn like everyone else.
- Law boards: spawn one from !prodspawn (Law Board) and !saveprod it to keep it after restarts.

#staff Staff: events, economy and players
!esp - Toggle ESP: every player through walls, anywhere on the map, with name, real job (and cover), rank, health and distance
!eventsettings - World event settings: minutes between events, player minimum, retry when too few are on, each event on/off, start/stop
!setfuhrer <player> - Make someone Führer now, without an election (cancels a running one, replaces the sitting Führer)
!removefuhrer - Remove the sitting Führer from office
!train - Start the supply train now
!event <id> - Start a world event (train). !stopevent ends the running one
!seteconomy 50 - Set the economy bar (1-110)
!treasury 5000 - Add money to the Reich treasury (a negative amount takes it away)
!makewanted <player> <reason> - Make someone wanted by the Reich
!clearwanted <player> - Clear someone's wanted status

#staff Staff: production
!prodspawn - The production spawner: ovens, flour, barrels, factory lines, derricks, markets, both printers, dumpsters, the bank vault and every good at any quality (into your pocket or at your crosshair). Also Finish its timer, Remove it and Save / Unsave it for the machine you're looking at. Z undoes a spawn.
!saveprod - Look at a machine or dumpster placed from !prodspawn (or any production machine): it's saved for this map and comes back after every restart, frozen and owned by nobody
!saveprodall - Save every machine you placed from !prodspawn that isn't saved yet
!unsaveprod - Look at a saved machine: remove it for good
!prodsaves - Count the saved machines on this map and highlight them for a minute
!addmarket - Place a market where you're looking (saved for this map)
!removemarket - Remove the market you're looking at
!addoilsite - Mark an oil site where you're looking; a bought derrick is built on the nearest free one, facing where you stood (saved for this map)
!removeoilsite - Remove the oil site nearest where you're looking, and its derrick
!oilsites - Show every oil site on this map for a minute
rp1942_panel_move / _size / _face / _mount / _print (console) - Fine-tune where a machine's panel sits, then print the line for the config

#staff Staff: bank robbery
!addvault - Place the Reichsbank vault where you're looking (saved for this map). !removevault removes the one you're looking at
!banksettings - The bank robbery settings (length, cooldown, join window, Reich needed, crew size, bank radius, reward, vault model, alarm) with the status and debug buttons
!bankstart [name] - Start a robbery now with that player (or you) as the robber, ignoring every requirement
!bankstop - Call off the robbery (no payout, no cooldown)
!bankfinish - End the timer now: the robbery succeeds and pays out
!bankcooldown - Clear the cooldown
!bankstatus - What the bank is doing right now

#staff Staff: map setup
!factiondoor - Look at a door and set its faction (reich, resistance, civilian, wehrmacht, waffen_ss, leibstandarte or none)
!adddumpster - Place a dumpster where you're looking (saved for this map)
!removedumpster - Remove the dumpster you're looking at
!getdumpsterpos - Copy every dumpster on this map to your clipboard as code, to hardcode them in the dumpster's config.lua
!testexplosion <damage> <radius> - Set off a test explosion where you're aiming (it does real damage)

#staff Staff: fire
!fire [spots] - Light a fire where you're looking (it spreads like any other)
!extinguish - Put out every fire within 400 units of where you're looking
!extinguishall - Put out every fire on the map
!firestatus - How many fires are burning, and every setting
rp1942_fire 0/1, rp1942_fire_spreading 0/1 (server console or server.cfg) - The fire system on or off, and whether fire spreads or only burns where it was lit. Saved
!firesetting <setting> [value] - Change a fire setting (enabled 0 turns the system off; spreading 0 stops it spreading; spreadChance, maxFires, damagePerSecond, blastChance, lifeMin/lifeMax...). Saved in data/rp1942/fire.json. No value shows the current one, no setting lists them
]] },

}
