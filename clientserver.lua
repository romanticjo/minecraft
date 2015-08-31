print( 'Client/Server - Sample' )
print( 'We are computer: ' .. os.getComputerID())

local args = { ... }
local role = args[1]
local protocol = args[2]
local modemLocation = args[3]
assert(role == 'client' or role == 'server', 'Specify "client" or "server"')
assert(protocol, 'Specify a server')
assert(modemLocation == 'left' or modemLocation == 'right' 
	or modemLocation == 'top' or modemLocation == 'bottom'
	or modemLocation == 'front' or modemLocation == 'back', 'Specify side for the rednet conenction.');

rednet.open(modemLocation)

local name
if role == 'server' then
	local hosts = {rednet.lookup(protocol, 'server')}
	local thisAsHost = hosts[1] == os.computerID()
	assert(thisAsHost or 0 == #hosts, 'Another server exists.')
	name = 'server'
else
	name = 'client-'..os.computerID()
end
rednet.host(protocol, name)
print('Registered '..name..' on protocol '..protocol)

function parse (str) 
	local f, args = nil, {}
	for token in string.gmatch(str, '[^|]+') do
		if not f then f = token else
			table.insert(args, token)
		end
	end
	return f, args
end

function server_up (sid)
end

local clients = {}
function client_up (sid, name)
	-- a new client comes to the network.
	rednet.send(sid, 'server_id|'..os.computerID(), protocol)
end

function connect(sid, name)
	table.insert(clients, sid)
	print('Registered client:' .. sid .. ' name:' .. name)
	print('Total clients: ' .. #clients)
	rednet.send(sid, 'connect_done', protocol)
end

local server
-- server authoritative answer
function server_up (sid)
	print('Server announcing, connecting to: ' .. sid)
	rednet.send(sid, 'connect|' .. name, protocol)
end
-- new client, inform of our server id
function peer_up (sid)
	if server then
		print('Peer:'..sid..' is announcing.  Replying with server id:'..server)
		rednet.send(sid, 'server_id|' .. server, protocol)
	end
end
-- non-authoritatve answer, connect explicitely.
function server_id (sid, serverId)
	if not server then
		print( 'Peer:' .. sid .. ' points to Server:' .. serverId);
		if tonumber(serverId) ~= os.getComputerID() then 
			local server = tonumber(serverId)
			print( 'Connecting to: ' .. server)		
			rednet.send(tonumber(server), 'connect|'..name, protocol)
		end
	end
end

-- server connect confirmation
function connect_done (sid)
	if sid ~= server then 
		server = sid
		print('Connected to server: ' .. sid)
	end 
end

clientCommands = {
	server_up = server_up,
	client_up = peer_up,
	server_id = server_id,
	connect_done = connect_done
}

serverCommands = {
	client_up = client_up,
	connect = connect
}

function run (commandTable)
	assert(commandTable)
	while true do
		local sid, msg, p = rednet.receive(protocol)
		assert(p == protocol)
		print('network: ' .. msg)
		cmd, args = parse(msg)
		local func = commandTable[cmd]
		if func then
			func(sid, unpack(args))
		end
	end
end

if role == 'server' then
	-- collect existing clients
	print('Annoucing server on ' .. protocol)
	rednet.broadcast('server_up', protocol)
	print('Running...')
	run(serverCommands)
else
	print('Announcing client on ' .. protocol)
	rednet.broadcast('client_up|'..name, protocol)
	print('Running...')
	run(clientCommands)
end
