--[[---------------------------------------------------------------------------
1942 DarkRP - F4 text pages (Rules, RP Definitions, ...)

Every page here becomes its own tab in the F4 menu. Just type the text:

    # Heading          a line starting with "# " becomes a red bar
    - Point            a line starting with "- " becomes a bullet point
    Anything else      a normal line of text
    (empty line)       a bit of space

To add a page, copy one of the blocks below. `icon` is any Garry's Mod
silkicon (see https://wiki.facepunch.com/gmod/Silkicons), or leave it out.
Keep each page's text between its opening and closing double square
brackets, and don't type two closing square brackets in a row inside it.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}

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

# Supply train
- About every 20 minutes a Reich supply train pulls into the station, waits briefly, then carries on down the line.
- Anyone outside the Reich can hold E on it to rob a crate of money and German weapons.
- The Reich is expected to guard it. Whatever isn't stolen goes to the Reich treasury.
- Stay off the tracks while it's moving.

# Faction doors
- Some doors belong to a faction or a Reich unit. Its name shows on the door.
- Only members can lock and unlock them, and nobody can buy them.

# Dumpsters
- Hold E on a dumpster to search it for junk, supplies and the odd weapon. Hobos find better things.
- Everyone has their own wait before searching the same dumpster again.

# Dead drops (Resistance)
/deaddrop 500 - Hide money in the dumpster you're looking at
/deaddrop weapon - Hide the weapon in your hands
- Any Resistance member who searches that dumpster collects everything in it. Only the Resistance can see a drop is there.
- If a member of the Reich searches it first, the drop is confiscated.

# Staff commands
/train - Start the supply train now
/event - List world events. /event stop ends the running one
/factiondoor - Look at a door and set its faction (reich, resistance, civilian, wehrmacht, waffen_ss, leibstandarte or none)
/adddumpster - Place a dumpster where you're looking (saved for this map)
/removedumpster - Remove the dumpster you're looking at
]] },

}
