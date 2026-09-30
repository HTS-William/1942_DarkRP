--[[---------------------------------------------------------------------------
1942 DarkRP - the Führer's decisions: THE QUESTIONS (edit freely)

Each question: `id` (never change it once live: it's how repeats are
tracked), the situation `text`, and three `answers`. Each answer:
    text      what the Führer says
    impact    "low", "moderate" or "high"  (odds and economy points:
              sh_decisions.lua, RP1942.Decisions.impacts)
    success   what the Führer reads if it works
    failure   what the Führer reads if it doesn't
Add as many questions as you like; they're dealt in a shuffled order.
---------------------------------------------------------------------------]]
RP1942 = RP1942 or {}
RP1942.Decisions = RP1942.Decisions or {}

RP1942.Decisions.questions = {
    {
        id = "stalingrad",
        text = [==[The Russians have renewed a massive counter-offensive in the city of Stalingrad, If they cut off Army Group B, We’ll lose the potential oil gains in the East.]==],
        answers = {
            {
                impact  = "high",
                text    = [==[Assemble nearby divisions from within Army Group B to hold the city!]==],
                success = [==[The defenses hold! The Russians are retreating like cowards! It seems our front lines remain intact as well!]==],
                failure = [==[We lost the city and the Russians have decimated the divisions we sent in which has endangered the whole southern front line around Stalingrad!]==],
            },
            {
                impact  = "moderate",
                text    = [==[Form a new division from recruiting the local population! Get them the weapons and uniforms they need to serve the Fatherland!]==],
                success = [==[Our newly made foreign legion has held the city, but it was at a hefty cost of resources.]==],
                failure = [==[The foreign legion has capitulated and surrendered to the Russians! What a waste of time and resources!]==],
            },
            {
                impact  = "low",   -- (not labelled in the original: the cautious option)
                text    = [==[We should weather this storm, I have trust in our generals to hold the city and our gains!]==],
                success = [==[Our forces were able to slow the Russians, but they have dug into the city, We still own a majority of the city.]==],
                failure = [==[Our forces were able to slow the Russians, but they have dug into the city, The Russians however hold a majority of the city.]==],
            },
        },
    },
    {
        id = "arms_rivalry",
        text = [==[A weapons manufacturing rivalry has taken form in the Fatherland between a Small arms factory and an Armored Vehicles factory, each has formed pacts with similar companies. If we decide to support one, the others will drop our contracts and we’ll lose their support.]==],
        answers = {
            {
                impact  = "high",
                text    = [==[We shall invest in the Panzers! I want the Tiger II Heavy Bombers by Christmas, Damn it!]==],
                success = [==[Our investment with the armored vehicles sector has rewarded us with newer, more reliable panzers! Requiring less fuel and maintenance overall. Sadly, No Tiger Heavy Bombers yet.]==],
                failure = [==[The factories have rolled out cost cutting measures and our newly built tanks are poorly constructed, breaking down and using more fuel than before, What even was the point of the investment!?]==],
            },
            {
                impact  = "moderate",
                text    = [==[We shall invest in Small arms! We can live without a few tanks, but our men need weapons to fight!]==],
                success = [==[The investment towards small arms manufacturing has rewarded us with new, cheap to build and reliable weapons that will reach the front lines soon in the east.]==],
                failure = [==[Defects we’re found in the newly built weapons from the various factories we invested in, Many of them jam frequently and need to be retooled to work right. What a nightmare!]==],
            },
            {
                impact  = "low",
                text    = [==[Their budgets are fine for now, We need more civilian production!]==],
                success = [==[The New Fuhrer-Refrigerator is an international hit! We are exporting more Appliances than we are building Guns or Tanks!]==],
                failure = [==[Many of the Consumer goods and appliances we invested in are low quality trash, Similar quality to that of french stuff, What a disgrace.]==],
            },
        },
    },
    {
        id = "researchers",
        text = [==[A few researchers enter your office; They are showing off a few of their recent projects to garner some project money to ‘grease the wheels of progress’ so to speak. You pick from them two of the most promising projects out of the bunch.]==],
        answers = {
            {
                impact  = "high",
                text    = [==[The medical device, Projekt Blitzherz will truly revolutionize medicine! We will fund them!]==],
                success = [==[The prototype defibrillator has been a massive success, we’ve been able to save many lives both on the front lines as well as at home.]==],
                failure = [==[This piece of junk was a mistake, It doesn’t even work but infact shocks the one using it really hard, dang near almost killing our medics! What a piece of crap.]==],
            },
            {
                impact  = "moderate",
                text    = [==[The combat stimulant, Projekt Blitzlauf seems quite the game changer, Get me my Check book!]==],
                success = [==[The combat stimulant seems to be a success! Our forces haven’t slept for 6 days and have marched non-stop! We will be unstoppable!]==],
                failure = [==[This ‘combat’ stimulant has been a disaster! All of our men have become addicts and refuse to fight at all until they get more of the drug!]==],
            },
            {
                impact  = "low",
                text    = [==[Send these quacks away, We don’t need any more pseudo-science, Just more Tanks!]==],
                success = [==[Your choice to refuse the scientists was well rewarded, many of them turned out to be con artists and crazy people.]==],
                failure = [==[Your choice to refuse the scientists was poorly made, Many of them are accomplished in their fields and have defected to the Allies and are making great discoveries, both in civilian and military..]==],
            },
        },
    },
    {
        id = "stalag_spies",
        text = [==[It comes to your attention by one of your aids that one of the Stalags in one of the occupied territories allegedly harbors a cell of allied spies, The camp staff claims no such thing exists. But something must be done to squash the rumors.]==],
        answers = {
            {
                impact  = "high",
                text    = [==[What a disgrace! I want all the staff and guard personnel fired for spreading such ridiculous rumors!]==],
                success = [==[The rumors have ceased, and much of the murmurs of spies has faded away, no doubt this rumor came about from shear boredom among the personnel.]==],
                failure = [==[As it turns out there really was a spy network in the Stalag, Many of the prisoners escaped, still at large, and many classified documents have gone missing! What a disaster!]==],
            },
            {
                impact  = "moderate",
                text    = [==[Outrageous! Send in my best Gestapo agents and route out the spies!]==],
                success = [==[The Stalag indeed harbored a spy network and various resistance cell connections, Our agents were able to infiltrate their network and crush their operation!]==],
                failure = [==[Our agents have confirmed that nothing out of the ordinary was found in this Stalag, No spies or networks were found, What a waste of time and resources.]==],
            },
            {
                impact  = "low",
                text    = [==[I see NOTHING!!]==],
                success = [==[Your loud outburst startles your aid and she flees the room taking all of the documents and papers on the matter with her, you feel.. Accomplished!]==],
                failure = [==[Your loud outburst triggers your aid’s fight or flight response and she forcefully slaps you in the face, She flees the room and leaves you in your burning pain on your face. Am I crying? Alittle.]==],
            },
        },
    },
    {
        id = "bismarck_ii",
        text = [==[While enjoying a bowl of Ice Cream, One of your big expensive battle ships had been sunk in the Atlantic by Allied forces, One of your admirals suggests having another, bigger battleship be built! He presents the plans for the Bismarck II, The first ever Super Heavy Battleship design.]==],
        answers = {
            {
                impact  = "high",
                text    = [==[Quad Cannon Turrets, A huge Radar array and an Ice cream parlor? Genius!! Build this NOW!]==],
                success = [==[By some miracle, as well with 30 different ship building companies and several millions of reichmarks. The Bismarck II was launched in all of its glory and has already claimed several Allied naval groups alone.]==],
                failure = [==[By no surprise to anyone with a functioning brain, The super heavy Battleship was completely obliterated by allied bombings during its early construction on the dry dock, What a horrible waste of money and resources.]==],
            },
            {
                impact  = "moderate",
                text    = [==[This seems a little too expensive, Lets just cut a few things, But keep the Ice cream parlor! Ice cream will be good for the sailors!]==],
                success = [==[The construction on the Bismarck II has finished, Featuring a quarter of the original plans firepower and armor, and the ice cream is fresh and cold!]==],
                failure = [==[The ship was hit during a few bombing raids, but survived the construction and has launched, but it was torpedeod and sank shortly after leaving port due to a nearby Swordfish plane. What a shame.]==],
            },
            {
                impact  = "low",
                text    = [==[This is insane! We will not build any new Battleships!]==],
                success = [==[The admiral thanks you for hearing him out and leaves, Now back to more important things. My Banana split! Yummy!!]==],
                failure = [==[The admiral gives you a look of disdain and angrily walks out of your office slamming the door, in doing so a large clump of dust decends from the ceiling and lands in your bowl of cold Ice cream. You will not recover from this betrayal.]==],
            },
        },
    },
    {
        id = "partisans",
        text = [==[A large cell of Belorussian partisans are tearing through the country side behind our front lines. Laying waste to any railroads that supply our armies with precious rations, weapons, ammo and tanks. We must do something about this!]==],
        answers = {
            {
                impact  = "high",
                text    = [==[Send in our most fierce fighters from all branches to hunt these scoundrels down and hang anyone who harbors them!]==],
                success = [==[Our efforts to destroy the large partisan cell was a success, Though not without a few war crimes.. We won’t worry about that, We’re Winning!!]==],
                failure = [==[The units we sent in was a little over zealous with their efforts and committed atrocious war crimes in their path, turning most of the locals against us, ultimately joining the partisan cell.]==],
            },
            {
                impact  = "moderate",
                text    = [==[Send in a task force of Gestapo agents to uncover their lair, They must have a base of operations!]==],
                success = [==[Our efforts to find the partisans was a success, and we were able to destroy them and their encampment, but more likely another group will come.]==],
                failure = [==[The agents we sent we’re unable to find the partisans and have seemingly gone into hiding, We’ll have to try and get them another time.]==],
            },
            {
                impact  = "low",
                text    = [==[Increase our railway security, double the patrols, double the guards. I want railways secure!]==],
                success = [==[The increase security on the railways have significantly decreased the partisans effectiveness, They will be eliminated if they act so recklessly from now on.]==],
                failure = [==[Despite our increased security, Our railways are still being destroyed and our front line morale has taken a hit from the delayed deliveries.]==],
            },
        },
    },
    {
        id = "strikes",
        text = [==[Many of the workers back in the Fatherland have begun to question the war, Despite your propaganda ministers best efforts, the people are beginning to doubt your leadership, and are starting strikes. you must set an example!]==],
        answers = {
            {
                impact  = "high",
                text    = [==[Defeatists! I want all of them hanged for this treason! No one should question my leadership!]==],
                success = [==[After a few people hanged per city and town, The dissenting voices and strikes have completely silenced, and the workers are in fact working twice as hard ever since under performing in job quota’s were deemed ‘Defeatist and treason’]==],
                failure = [==[Many of the hangings have sparked outrage from the towns and cities, many of them have actively begun underground resistance movements. Our gestapo agents will have to work overtime to crush these movements now.]==],
            },
            {
                impact  = "moderate",
                text    = [==[These workers must go back to work, Goebbels! Produce a film to encourage the people to return to work!]==],
                success = [==[Your propaganda minister, through some hardship and several drinks no doubt, Produced a film that was a massive hit with the people, Most but not all of the dissenting workers have returned to work.]==],
                failure = [==[After debuting at cinemas all over Germany, the film was reviewed poorly and many saw through its hollow corny messaging as a propaganda, many of the workers returned the next day to continue the strikes.]==],
            },
            {
                impact  = "low",
                text    = [==[Fine, Whatever, Let them strike. We have better things to do then appease these traitors!]==],
                success = [==[Though many of the strikers remain, many of them have returned back to the factories.]==],
                failure = [==[Much of the strikers remain, and they are beginning to voice demands for ending the war and better working conditions.]==],
            },
        },
    },
    {
        id = "bombed_factory",
        text = [==[One of our largest consumer factories was destroyed during an air raid. We shouldn’t waste any precious time, We need to invest in a new potential project on this plot!]==],
        answers = {
            {
                impact  = "high",
                text    = [==[Excellent! We should build a secret laboratory under the remains of the factory so we can prioritize top secret experiments and technology!]==],
                success = [==[Our secret lab has accelerated our cutting edge technology that is slowly making its way into both our civilian sector but more importantly our military sector.]==],
                failure = [==[Something went wrong and the underground structured caved in during construction, We lost a few decent architects in the cave in as well..]==],
            },
            {
                impact  = "moderate",
                text    = [==[We should build a Flak Tower so this will never happen again!]==],
                success = [==[The construction was completed ahead of schedule, It is fully operational and has even taken down a couple of squadrons of bombers, reducing their air raid effectiveness down by 30%!]==],
                failure = [==[The construction has stalled at the site and unfortunately was hit during a massive air raid, None of the construction remains. What a waste of time.]==],
            },
            {
                impact  = "low",
                text    = [==[Forget the new projects, Just rebuild the factory.]==],
                success = [==[The construction of the factory was complete, and with the new machinery has increased productivity by 50%!]==],
                failure = [==[Much of the factory was complete but during its construction it was hit with more air raids, much of the equipment is peppered with shrapnel and most of the windows are blown out already, but it is still operational.]==],
            },
        },
    },
    {
        id = "captains_of_industry",
        text = [==[While holding a meeting with your captains of industry, one of them addresses you directly about funding for some of the consumer goods. Claiming you’ve neglected the civilian sector in favor of the war effort. The others have an expression that tells you they agree with the man.]==],
        answers = {
            {
                impact  = "high",
                text    = [==[Fine! We will divert more funds to the civilian sector.]==],
                success = [==[Elated by our decision, many of the companies are producing finer and higher quality products, invigorating our economy across the reich!]==],
                failure = [==[Despite being so charitable, Many of the consumer goods companies have taken our investments and have made very little if no changes to their products, Stagnating our economy even further. Filthy no good rats!]==],
            },
            {
                impact  = "moderate",
                text    = [==[How dare you! Thanks to your insolence, We’re going to double the military’s budget, and cut yours in half!]==],
                success = [==[The doubled budget to the military has greased some obscure projects that have started to prove their worth in the field, Although at the cost of consumer goods, many of the companies producing goods are trying to make the most from their halved investments.]==],
                failure = [==[Most of the military arms companies have pocketed the cash with zero improvements, taking this increased investments as a payday, along with that many of our consumer companies have moved to other more reasonable countries, in the allied territories..]==],
            },
            {
                impact  = "low",
                text    = [==[The budget is fine for the civilian sector, We have no need to increase funding. Now, stop your belly aching.]==],
                success = [==[The room is quiet but continues business as usual until the meeting is over and the discussion is forgotten.]==],
                failure = [==[The room is silent, many of the business leaders have a pained expression, the meeting goes on but an awkwardness lingers through out. Yikes.]==],
            },
        },
    },
    {
        id = "deputy_flight",
        text = [==[While waking up from bed you find a letter from your deputy, It reads that  he plans to steal a plane, fly over the English channel, and Parachute into Britain to discuss with powerful reich sympathizers to get Britain out of the war, In your rage while reading, you learn that he has just been captured and the British radio broadcasts are celebrating this capture.]==],
        answers = {
            {
                impact  = "high",
                text    = [==[Damn that idiot! That fool has made us look like Imbeciles! I want him assassinated now! He must never get a chance speak again!]==],
                success = [==[Your most competent spies were able to infiltrate the mainland, with some difficulty but ultimately they were able to kill your deputy along with that, they were able to find classified allied documents regarding future plans in the war!]==],
                failure = [==[Unfortunately, Your plot was discovered by resistance cells in France, they even captured valuable documents on various projects due to our agents being concentrated in one area for this operation.]==],
            },
            {
                impact  = "moderate",
                text    = [==[This must be rectified, Send in a team of our best to get him out, so he may answer for his crimes!]==],
                success = [==[A team of your best brandonburgers infiltrate the british mainland and are able to free and capture your deputy from local authorities, you receive word that they’ll be back in the mainland soon so he may face the actions of his crime!]==],
                failure = [==[In a series of unfortunately bad decisions, your best brandonburgers who were to infiltrate the British mainland, while on their way over the english channel by plane had entered rough weather and poor visiability sadly crashed into the Dover cliffs..]==],
            },
            {
                impact  = "low",
                text    = [==[Damned fool! I want his office dismantled and everything to do with him destroyed! If he ever sets foot in Germany I want him shot!]==],
                success = [==[Though you no longer have a deputy, it doesn’t seem the impact of your former deputy’s capture has changed much of anything, and the war continues as it did the day before.]==],
                failure = [==[Your former deputy will be a stain forever blotted over the Reich for all time, What an embarrassment!]==],
            },
        },
    },
    {
        id = "fuel_shortage",
        text = [==[The front lines are dragging and many of your citizens are having a hard time with the fuel shortages, We need fuel to keep both the war and the economy from collapsing!]==],
        answers = {
            {
                impact  = "high",
                text    = [==[We must renew a massive offensive in the East to secure the oil fields! Forget Stalingrad, We’ll just take the fields right from under them!]==],
                success = [==[Army Group South makes a move into the oil fields of the Caucuses, Surprisingly with success. Though we don’t have all of the oil fields, We hold most and we can extract all that we need to continue!]==],
                failure = [==[The operation was a failure, In our effort to redirect Army groups, we opened some of our flanks to assaults, Several pockets have opened and we had to pull back our efforts in the East, loosing much of our gains.]==],
            },
            {
                impact  = "moderate",
                text    = [==[Surely Japan has some fuel to spare right?]==],
                success = [==[By some miracle you and your foreign minister strike an oil deal with Japan, and the outlandish plan to deliver the oil through Uboats retrofitted as oil tankers, and it seems to work. Its not much, but it’ll help.]==],
                failure = [==[For whatever reason either through misjudgment of geography or shear desperation, you actually ask the Japanese to trade oil and predictably, They laugh hysterically over the phone then hang up.]==],
            },
            {
                impact  = "low",
                text    = [==[Just increase rationing what we have for the people and prioritize fuel supplies to effective divisions!]==],
                success = [==[Although your citizens are unhappy with the rationing for fuel, It seems to work and many of your effective divisions are able to fuel their vehicles, but keeping horses on standby, just in case.]==],
                failure = [==[Your efforts to ration the fuel seems to have done little to alleviate the mounting pressure from both the people and the military.]==],
            },
        },
    },
    {
        id = "architect",
        text = [==[Your most trusted architect enters your office, He tells you that he has an incredible investment opportunity, He wants the Reich to fund one of his building projects, He claims that it’ll generate tons of jobs and money for the Reich, when its completed. In several years..]==],
        answers = {
            {
                impact  = "high",
                text    = [==[In several years?! Well, I suppose I can divert some funds. After all this Reich should last a thousand years so what is a few years right?]==],
                success = [==[The Project is underway, the monolithic structure in the heart of the Reich is being started and as the cash flows into it, So does the jobs and with it the economy booms a bit!]==],
                failure = [==[The Monolithic project has just barely begun and has already run into problems, from faulty concrete to contractors pocketing large sums of the money. What a mess.]==],
            },
            {
                impact  = "moderate",
                text    = [==[Sounds really expensive, Perhaps I could fund it if we can bring the cost down, Perhaps still generate just as much money right?]==],
                success = [==[The project is underway, though not as grand as your architect wanted, it has generated some much needed jobs and stimulation of the economy.]==],
                failure = [==[With much of the grandness removed from the original plans and cost cutting, It doesn’t seem to generate as much worker interest thus a stagnation in the economy in the Reich, ultimately making it less appealing than most other jobs.]==],
            },
            {
                impact  = "low",
                text    = [==[No, We will not be investing in anymore grand projects, We are at war! Go design my next super bunker.]==],
                success = [==[Just as you mention it, He pulls from his back with many containers of blueprints and plans a detailed project of said Super bunker, He says that this project would be vastly more cheaper than the one he presented originally.]==],
                failure = [==[Your architect looks at you with an offended expression, He lets out a few negative remarks and storms out, Something something, I quit, Something something. Whatever.]==],
            },
        },
    },
    {
        id = "jet_prototypes",
        text = [==[While reviewing some of the upcoming prototype aircraft, you notice a few designs that peak your interest, They are jet engine aircraft! Excited by the prospect of getting one of these to the front line, you must choose one to fund as you only have enough to push one of these into field testing.]==],
        answers = {
            {
                impact  = "high",
                text    = [==[Wow, The Ho-229 looks interesting! Perhaps this can be the solution to our air raid problems!]==],
                success = [==[With the increased funding to the Ho-229 project, many of the engineers were able to get various scientific advances with it, Not only is it faster than most propeller aircraft, but its new Radar absorbing coating allows for It to be nearly undetectable by ground based radar!]==],
                failure = [==[The funding of the Ho-229 project has not be as rewarding as one would hope, The test aircraft showed promise, but has been left partially built for several months, No production models seem to be planned, What a waste of state funds.]==],
            },
            {
                impact  = "moderate",
                text    = [==[We MUST invest in the Me-262! It will be the greatest bomber ever!]==],
                success = [==[Your investment in the Me-262 program has been greatly rewarded, The funding was able to iron out various design quirks and also made ways in making the engines more fuel efficient, as well as easier and cheaper to manufacture, Soon Bf-109 factories will be retooled to make them!]==],
                failure = [==[Although the aircraft is a sound design, sadly it is under baked with terrible teething issues and bar the test aircraft from seeing much flight time, perhaps we could have invested in more Bf-109’s..]==],
            },
            {
                impact  = "low",
                text    = [==[Perhaps we should prioritize our efforts on existing aircraft designs.]==],
                success = [==[With our investments going into current production models of aircraft, we’ve made some minor improvements to our aircraft line up to better increase fuel efficiency and production costs.]==],
                failure = [==[Although dumping more money into the existing designs overall was a safe decision, unfortunately no new improvements or cost cutting measures were made.]==],
            },
        },
    },
}
