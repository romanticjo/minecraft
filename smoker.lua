print('Launching Furnace Monitoring')

os.loadAPI('clienterserver.lua')
local server=(getfenv())["clienterserver.lua"]
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

furnaces = getConnectedFurnaces()
server.run('client', 'jo-factory', 'back', updateSmoker, 2)
