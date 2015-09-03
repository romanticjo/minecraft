print('Launching Furnace Monitoring')

os.loadAPI('clientserver.lua')
local server=(getfenv())["clientserver.lua"]
local furnaces

function getConnectedFurnaces () 
	local p = peripheral.getNames()
	local furnaces = {}
	for i = 1, #p do
		s, e = string.find(p[i], 'container_furnace' );
		if s ~= nil and s == 1 then
			furnaces[ p[i] ] = peripheral.wrap( p[i] )
		end
	end
	return furnaces
end

function setSmoker (burning)
	redstone.setOutput('right', not burning)
end

function updateSmoker ()
	-- set smoker state
	local isBurning = false
	for n, p in pairs(furnaces) do
		isBurning = p.isBurning() or isBurning
		--print( 'Found: ' .. n .. ', burning: ' ..  (p.isBurning() and 'true' or 'false')  )
	end
	setSmoker( isBurning )
	server.send('smoking|' .. tostring(isBurning))
end

local args = { ... }
local type = args[1]
local protocol = args[2]

local clients = {}

function onSmoking (sid, isSmoking)
	clients[sid] = { time = os.time(), isSmoking = isSmoking == 'true' }
	updateSmokeStack();
end

function updateSmokeStack ()
	local turnOn = false
	local time = os.time()

	local toRemove = {}
	for k,v in pairs(clients) do
		if math.abs( v.time - time ) > 0.1 then
			table.insert(toRemove, k)
			--clients[k] = nil
		else
			turnOn = turnOn or v.isSmoking
		end
	end
	for i=1,#toRemove do
		clients[toRemove[i]] = nill
	end
	redstone.setOutput('top', not turnOn)
end

if type == 'client' then
  furnaces = getConnectedFurnaces()
  server.run('client', protocol or 'jo-factory', updateSmoker, 2)
elseif type == 'server' then
  local commandTable = {
  	smoking = onSmoking
  }
  server.addCommandTable('server', commandTable)
  server.run('server', protocol or 'jo-factory', updateSmokeStack, 10);
end

