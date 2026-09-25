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
]] },

}
