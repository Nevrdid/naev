--[[
<?xml version='1.0' encoding='utf8'?>
<mission name="Taiomi 9">
 <unique />
 <chance>0</chance>
 <location>None</location>
 <done>Taiomi 8</done>
 <notes>
  <campaign>Taiomi</campaign>
 </notes>
</mission>
--]]
--[[
   Taiomi 09

   Player has to make a deal with a smuggler to bring goods to bastion.
]]--
local vn = require "vn"
local vni = require "vnimage"
local fmt = require "format"
local taiomi = require "common.taiomi"
local escort = require "escort"
local fleet = require "fleet"
--local der = require 'common.derelict'
--local pilotai = require "pilotai"
local lmisn = require "lmisn"

local reward = taiomi.rewards.taiomi09
local title = _("Smuggler's Deal")
local base, basesys = spob.getS("One-Wing Goddard")
local smugden, smugsys = spob.getS("Darkshed")
local startspob, startsys = spob.getS("Arrakis")
local fightsys = system.get("Gamel")
local handoffsys = system.get("Bastion")
local handoffpos = vec2.new( 8e3, 3e3 )

--[[
   0: mission started
   1: made deal with smuggler
   2: escort from xxx to bastion
   3: fight done
   4: cutscene done
--]]
mem.state = 0

function create ()
   if not misn.claim{ startsys, fightsys, handoffsys } then
      warn(_("Unable to claim system that should be claimable!"))
      misn.finish(false)
   end

   -- Store if the player knows the station
   mem.smugden_known = smugden:known()

   misn.accept()

   -- Mission details
   misn.setTitle( title )

   misn.setDesc(fmt.f(_("You have been tasked to contact smugglers at {smugden} ({smugsys}) to obtain new materials for the citizens of {basesys}."),
      {smugden=smugden, smugsys=smugsys, basesys=basesys}))
   misn.setReward( fmt.credits(reward) )

   mem.marker = misn.markerAdd( smugden )

   misn.osdCreate( title, {
      fmt.f(_("Find the smuggler in {spob} ({sys})"),{spob=smugden, sys=smugsys}),
   } )

   hook.enter( "enter" )
   hook.land( "land" )
end

local land_smuggler, land_escorts, land_final
function land ()
   local scur = spob.cur()
   if mem.state==0 and scur==smugden then
      land_smuggler()
   elseif mem.state==1 and scur==startspob then
      land_escorts()
   elseif mem.state==4 and scur==base then
      land_final()
   end
end

function land_smuggler ()
   vn.clear()
   vn.scene()
   local s = vn.Character.new( _("Smuggler"), { image=vni.generic() } )
   local scav = vni.soundonly( 1, {pos="farleft"} )
   vn.transition()

   if mem.smugden_known then
      vn.na(fmt.f(_([[You land on {spob} and follow the directions Scavenger gave you to locate the smuggler. Although you are somewhat familiar with the layout of {spob}, Scavenger's instructions take you to an area you have never visited before.]]),
         {spob=smugden}))
   else
      vn.na(fmt.f(_([[You land on {spob} and follow the directions Scavenger gave you to locate the smuggler. Following Scavenger's you head into the depths of the station.]]),
         {spob=smugden}))
   end
   vn.na(_([[Making your way through the labyrinth of dimly lit corridors and rooms, you finally make it to the airlock to your destination.]]))
   vn.menu{
      {_([[Knock.]]), "cont01_knock"},
      {_([[Barge in.]]), "cont01_barge"},
   }

   vn.appear( s )
   vn.label("cont01_knock")
   vn.na(_([[As soon as you knock, you are told to come in just to find yourself looking down the barrel of a plasma shotgun.]]))
   vn.jump("cont01")

   vn.label("cont01_barge")
   vn.na(_([[You barge in unannounced, and quickly find yourself looking down the barrel of a plasma shotgun.]]))
   vn.jump("cont01")

   vn.label("cont01")
   s(_([["Giv'me a reason not to blow ye brains to make some abstract art on them wall behind'ye."]]))
   vn.menu{
      {_([[Put your hands up.]]), "cont02_hands"},
      {_([[Try to tackle them.]]), "cont02_tackle"},
   }

   local tackled = false
   vn.label("cont02_hands")
   vn.na(_([[You put your hands up non-aggressively and mention that you bring a deal to the table.]]))
   s(_([["Let's see about that. Keep 'em hands up."]]))
   s(_([[The pat you down and find the holodrive you have containing Scavenger's deal. They take it despite your objections, and begin playback.]]))
   vn.jump("cont02")

   vn.label("cont02_tackle")
   vn.func( function () tackled = true end )
   vn.na(_([[You begin to move and immediately are hit on the shoulder flinging you helplessly against the wall. Then suddenly an intense burning sensation begins to spread from your shoulder.]]))
   s(_([["Shouldn't of done that. Be glad I set them settin' to non-lethal."]]))
   s(_([[Barely able to make what is going on due to the pain, you can make out them whistling to themself as they approach you. Still stunned and unable to react, they pat you down and take a holodrive you have containing Scavenger's deal.]]))
   s(_([[With you still writhing in pain, they begin playback.]]))
   vn.jump("cont02")

   vn.label("cont02")
   vn.appear( scav )
   vn.na(_([[The holodrive begins playing a sound-only file. You recognize the voice as Scavenger's.]]))
   scav(_([["Hello. Who I am is not important, but it has come to my attention that you are in possession of large amounts of contraband hypergate components."]]))
   scav(_([["Such components are heavily marked and it is unlikely that anybody would be able to use them without arising suspicions from the Empire. While you could try to take it apart to reuse some components, that is a waste of the full potential of your contraband."]]))
   scav(_([["I believe we could reach a mutual agreement to take the contraband off your hands. Take a look at the attached sample. There is more where this comes from."]]))
   scav(fmt.f(_([["I need the cargo delivered to the location marked in the {sys} system. The individual there will provide escort."]]),
      {sys=handoffsys}))
   vn.na(_([[The audio playback ends.]]))
   vn.disappear( scav )

   s(_([["Let us see what we have here…"]]))
   vn.na(_([[They fiddle with the console to access the rest of the contents of the holodrive.]]))
   s(_([[Suddenly they break out into a chuckle.
"Ho-ho-ho, that is mighty interesting, ain't it? Your client must be really interested in getting their hands on them hardware."
Their put away their weapon.]]))

   vn.func( function ()
      if not tackled then
         vn.jump("cont03")
      end
   end )
   s(_([[They gesture towards your burning shoulder.
"Let me fix that in a jiffy. Stay still hun."]]))
   s(_([[They approach you and spray your injury with what appears to be some wound sealing spray.
"That'll let you get back to your ship. You might want to get it checked up though, or the skin grows back funny. Now back to business!"]]))

   vn.label("cont03")
   s(_([["So I've decided to, umm, carefully think it over, and I thinks we got a deal!"]]))
   s(fmt.f(_([["Them convoy with them parts be at {spob} in the {sys} system. I'll send word about them deal and have them meet you at the spaceport."]]),
      {spob=startspob, sys=startsys}))
   s(fmt.f(_([["We'll do our part with them convoy, but it'll be your job to keep it in one piece to {destsys}. Not that I think people gonna be waitin' fer a convoy to that empty place."]]),
      {destsys=handoffsys}))
   vn.na(_([[You feel like you've overstayed your due and head out back to the station to go on with the job.]]))

   vn.func( function ()
      if not tackled then
         vn.jump("cont04")
      end
   end )
   vn.na(_([[You don't feel any pain in your shoulder, but it doesn't look too good, but you should recover. At least they didn't aim at your head. Time to get back to your ship before the painkillers wear out.]]))

   vn.label("cont04")
   vn.run()

   misn.osdCreate( title, {
      fmt.f(_("Rendezvous with smugglers at {spob} ({sys})"),{spob=startspob, sys=startsys}),
   } )
   misn.markerMove( startspob )
   mem.state = 1
end

function land_escorts ()
   vn.clear()
   vn.scene()
   vn.transition()
   vn.na(fmt.f(_([[You land and are quickly greeted by smugglers. They briefly introduce themselves, and say they'll be delivering the promised cargo to the specified location at {sys} before leaving on shuttles. After the formality head back to their ships to await your departure.]]),
      {sys=handoffsys}))
   vn.run()

   local ships = { "Mule", "Mule", "Mule" }
   escort.init( ships, {
      func_pilot_create = "escort_spawn",
   } )
   escort.setDest( handoffsys, "escort_success", "escort_failure" )

   misn.osdCreate( title, {
      fmt.f(_("Escort the smugglers to {sys}"),{sys=handoffsys}),
   } )
   mem.state = 2
end

local function escort_faction ()
   return faction.dynAdd( "Pirate", "taiomi_convoy", _("Smugglers"), {clear_enemies=true, clear_allies=true} )
end

-- luacheck: globals escort_spawn
function escort_spawn( p )
   p:setFaction( escort_faction() )
end

-- luacheck: globals escort_success
function escort_success ()
   -- Not actually done yet
   for e in ipairs(escort.pilots()) do
      e:control(true)
      local pos = handoffpos + vec2.newP( 200*rnd.rnd(), rnd.angle() )
      e:moveto( pos )
   end
   escort_inpos()
end

function escort_inpos ()
   local notstopped = false
   for k,p in ipairs(escort.pilots()) do
      if not p:isStopped() then
         notstopped = true
         break
      end
   end
   if notstopped then
      hook.timer( 1, "escort_inpos" )
   else
      hook.timer( 3, "cutscene00" )
   end
end

function cutscene00()
   player.cinematics( true )
   local pp = player.pilot()
   pp:setInvincible(true)
   pp:control(true)
   pp:brake()

   local ep = escort.pilots()
   for k,v in ipairs(ep) do
      v:brake()
   end
   camera.set( ep[1] )

   hook.timer( 6, "cutscene01" )
end

function cutscene01()
   local ep = escort.pilots()
   local fconvoy = escort_faction()
   local leavers = {}
   local j = jump.get( system.cur(), fightsys )
   for k,v in ipairs(ep) do
      local p = pilot.add("Schroedinger", fconvoy, v:pos())
      p:setDir( v:dir() )
      p:setInvisible( true )
      p:setInvincible( true )
      p:control()
      p:hyperspace( j )
      if #leavers==0 then
         p:broadcast(_("Deal is done, time to scram!"), true )
      end
      table.insert( leavers, p )
   end

   hook.timer( 8, "cutscene99" )
end

function cutscene99()
   player.cinematics( false )
   local pp = player.pilot()
   pp:setInvincible(false)
   pp:control(false)
   camera.set()
   mem.state = 4

   misn.osdCreate( title, {
      fmt.f(_("Return to {spob} ({sys})"),{spob=base, sys=basesys}),
   } )
end

function enter ()
   local scur = system.cur()
   if scur==fightsys then
      local fct = var.peek( "taiomi_convoy_fct" ) or "Empire"
      local flt
      if fct== "Soromid" then
         flt = {
            "Soromid Nyx",
            "Soromid Odium",
            "Soromid Odium",
            "Soromid Reaver",
            "Soromid Reaver",
            "Soromid Reaver",
            "Soromid Reaver",
         }
      elseif fct=="Dvaered" then
         flt = {
            "Dvaered Vigilance",
            "Dvaered Phalanx",
            "Dvaered Phalanx",
            "Dvaered Vendetta",
            "Dvaered Vendetta",
            "Dvaered Vendetta",
            "Dvaered Vendetta",
         }
      else
         flt = {
            "Empire Pacifier",
            "Empire Admonisher",
            "Empire Admonisher",
            "Empire Lancelot",
            "Empire Lancelot",
            "Empire Lancelot",
            "Empire Lancelot",
         }
      end

      pilot.toggleSpawn(false)
      pilot.clear()

      local function add_fleet( pos )
         pos = pos or vec2.newP( scur:radius()*rnd.rnd(), rnd.angle() )
         local p = fleet.add( 1, flt, fct, pos )
         for k,v in ipairs(p) do
            local m = v:memory()
            m.loiter = math.huge
            m.doscans = true
         end
         return p
      end

      if mem.state < 2 then
         for i=1,4 do
            add_fleet()
         end
      else
         -- TODO add patrols that fight
         add_fleet()
      end
   elseif scur==handoffsys then
      hook.timer( 5, "almost_there" )
   end
end

function almost_there ()
   local pe = escort.pilots()
   pe[1]:broadcast(_("Almost there! Head to the rendezvous point!"))
end

-- luacheck: globals escort_failure
function escort_failure ()
   lmisn.fail(_("The smuggler ships were all destroyed!"))
end

function land_final ()
   vn.clear()
   vn.scene()
   local s = vn.newCharacter( taiomi.vn_scavenger() )
   vn.transition( taiomi.scavenger.transition )
   vn.na(_([[You board the Goddard and and find eagerly Scavenger waiting for you.]]))
   s(_([[""]]))
   vn.sfxVictory()
   vn.na( fmt.reward(reward) )
   vn.done( taiomi.scavenger.transition )
   vn.run()

   player.pay( reward )
   taiomi.log.main(_(""))
   misn.finish(true)
end
