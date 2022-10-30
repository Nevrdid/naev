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
   1: met smuggler
   2: made deal with smuggler
   3: escort from xxx to bastion
   4: fight done
   5: cutscene done
--]]
mem.state = 0

function create ()
   if not misn.claim{ startsys, fightsys, handoffsys } then
      warn(_("Unable to claim system that should be claimable!"))
      misn.finish(false)
   end

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
   if mem.state == 0 and scur==smugden then
      land_smuggler()
   elseif mem.state==3 and scur==startspob then
      land_escorts()
   elseif mem.state==5 and scur==base then
      land_final()
   end
end

function land_smuggler ()
   vn.clear()
   vn.scene()
   local s = vn.Character.new( _("Smuggler"), { image=vni.generic() } )
   vn.transition()

   vn.na(fmt.f(_([[You land on {spob} and follow the directions Scavenger gave you to locate the smugglers.]]),
      {spob=smugden}))

   vn.appear( s )

   vn.run()

   misn.osdCreate( title, {
      fmt.f(_("Rendezvous with smugglers at {spob} ({sys})"),{spob=startspob, sys=startsys}),
   } )
   misn.markerMove( startspob )
end

function land_escorts ()
   vn.clear()
   vn.scene()
   vn.transition()
   vn.na(_([[]]))
   vn.run()

   local ships = { "Mule", "Mule", "Mule" }
   escort.init( ships, {
      func_pilot_create = "escort_spawn",
      func_pilot_death = "escort_death",
   } )
   escort.setDest( handoffsys, "escort_success", "escort_failure" )

   misn.osdCreate( title, {
      fmt.f(_("Escort the smugglers to {sys}"),{sys=handoffsys}),
   } )
end

-- luacheck: globals escort_spawn
function escort_spawn( p )
   local fconvoy = faction.dynAdd( "Pirate", "taiomi_convoy", _("Smugglers"), {clear_enemies=true, clear_allies=true} )
   p:setFaction( fconvoy )
end

-- luacheck: globals escort_success
function escort_success ()
   -- Not actually done yet
   for e in ipairs(escort.pilots()) do
      e:control(true)
      local pos = handoffpos + vec2.newP( 200*rnd.rnd(), rnd.angle() )
      e:moveto( pos )
      escort_inpos()
   end
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