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

# The factions
Civilians - Everyday people of the town: tradesmen, dealers, doctors and the like.
Resistance - Fighters working against the Reich from the shadows.
Reich - The occupying authority, made up of the units below.
Wehrmacht - The police force. Keeps order, patrols and makes arrests.
Waffen-SS - The elite special unit, called in when the Wehrmacht isn't enough.
Leibstandarte - The Führer's personal bodyguard.
Recruits - Every Reich unit starts at Recruit. Specialisations appear in the job menu once you hold the base job.

# Wanted by the Reich
- Killing a member of the Reich makes you wanted. A red WANTED tag shows above your name.
- Robbing the supply train also makes you wanted.
- Being arrested or killed clears it, and so does joining the Reich. Otherwise it runs out on its own.

# Economy and taxes
- The economy bar at the bottom of the screen shows how the economy is doing. A better economy means higher wages.
- The Führer sets the tax rates. Taxes come out of your wages and go to the Reich treasury.
- Hover the economy bar with your cursor out to see the treasury and every tax rate.

# Production and markets
- Ovens, wine barrels, oil derricks, factory lines and markets have panels: look at a button and press E.
- Ovens, oil derricks and factory lines have a POWER lever. Switching one off pauses it where it is; switching it back on carries on.
- Bakers buy ovens and sacks of flour in the F4 Shop and push sacks into the oven (it queues 3). While it bakes, keep the fire in the green with STOKE FIRE: more time in the green means more loaves and better bread. COLLECT BREAD when it's done.
- Winemakers buy wine barrels and press START. While it ferments it calls for stirring: STIR before the timer runs out. Every stir raises the vintage. BOTTLE when it's done.
- Petroleum Producers buy an oil derrick. It's built on the nearest free oil site and bolted down (it's marked on your screen once built). It pumps on its own. With the valve shut the pressure climbs; turn the valve wheel to open it and the pressure falls, then turn it again to shut it. Keep it in the green for more canisters of crude and a better grade. If the pressure drops to nothing with the valve open, the pump stalls and switches itself off: switch it back on, and the pressure builds up again from zero. Don't leave it in the red: after a while an alarm sounds, and if the pressure still isn't brought down, the derrick explodes. FILL CANISTERS when the tank is full.
- Factory Owners buy a factory line. It halts twice a run: the BELT, BOILER or FUSE lamp flashes, and you press the matching repair (the wrong one costs extra time). The less downtime, the better the run and the better the odds of rare goods like clocks and radios. COLLECT when the run is done.
- Goods have a quality of 1 to 3 stars, and better goods sell for more.
- Sell goods at a market: SELL a kind of good from your pocket, SELL EVERYTHING, or push goods into the crate. Prices follow the economy, and one good is in demand each hour for a bonus. Sales are taxed like wages.
- Every market sale helps the economy a little, and a better economy means higher wages for everyone. Selling privately to other players doesn't move the economy.
- E picks goods up to carry. Shift+E eats bread or drinks wine.

# Supply train
- About every 20 minutes a Reich supply train pulls into the station, waits briefly, then carries on down the line.
- Anyone outside the Reich can hold E on it to rob a crate. The money goes into your wallet and any weapon into your pocket.
- The Reich is expected to guard it. Whatever isn't stolen goes to the Reich treasury.
- Stay off the tracks while it's moving.

# Undercover (Gestapo and Resistance Operative)
- Press F3 to open your wardrobe. Its tabs list the jobs you can pass as: civilians and the Resistance for the Gestapo, civilians and the Reich for the Operative.
- Picking one puts on that job's clothes and takes its title. Nobody is told. Jobs with several outfits open a model selection: click an outfit to preview it, then Wear This (or double-click).
- Officers, commanders, the Führer and the Resistance Leader can't be impersonated.
- You can also type any cover title in the wardrobe. Your own side always sees your faction tag over your head.

# Faction doors
- Some doors belong to a faction or a Reich unit. Its name shows on the door.
- Only members can lock and unlock them, and nobody can buy them.

# Dumpsters
- Hold E on a dumpster to search it for junk, supplies and the odd weapon. Hobos find better things.
- Anything useful goes straight into your pocket. If your pocket is full, it lands on the ground.
- Everyone has their own wait before searching the same dumpster again.

# Dead drops (Resistance)
/deaddrop 500 - Hide money in the dumpster you're looking at
/deaddrop weapon - Hide the weapon in your hands
- Any Resistance member who searches that dumpster collects it: money into their wallet, weapons into their pocket. Whatever doesn't fit in their pocket stays in the drop.
- Only the Resistance can see a drop is there.
- If a member of the Reich searches it first, the drop is confiscated.

#staff Staff commands
All of these are also in the ULX menu (!menu > Cmds > 42Bros) with descriptions, and as !commands (!train). Who may use each is set per rank in the ULX menu (Groups tab, 42Bros).
/train - Start the supply train now
/event - List world events. /event stop ends the running one
!stopevent - End the running world event
!seteconomy 50 - Set the economy bar (1-110)
!treasury 5000 - Add money to the Reich treasury (a negative amount takes it away)
!makewanted <player> <reason> - Make someone wanted by the Reich
!clearwanted <player> - Clear someone's wanted status
/factiondoor - Look at a door and set its faction (reich, resistance, civilian, wehrmacht, waffen_ss, leibstandarte or none)
/adddumpster - Place a dumpster where you're looking (saved for this map)
/removedumpster - Remove the dumpster you're looking at
/addmarket - Place a market where you're looking (saved for this map)
/removemarket - Remove the market you're looking at
/addoilsite - Mark an oil site where you're looking; a bought derrick is built on the nearest free one, facing where you stood (saved for this map)
/removeoilsite - Remove the oil site nearest where you're looking, and its derrick
/oilsites - Show every oil site on this map for a minute
!prodspawn - Open the production spawner: machines, flour and goods at any quality, plus finish/remove for the machine you're looking at
!testexplosion <damage> <radius> - Set off a test explosion where you're aiming (it does real damage)
rp1942_panel_move / _size / _face / _mount / _print (console) - Fine-tune where a prop's panel sits, then print the line for the config
]] },

}
