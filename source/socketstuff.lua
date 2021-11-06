--[[
Socketstuff module by togfox October 2021. MIT license applies

Usage:
create three global variables in main.lua that will persistent and used for the life of the session:

gintServerPort = love.math.random(6000,6999)		-- this is the port each client needs to connect to
gbolIsAClient = false            					-- defaults to NOT a client until the player chooses to connect to a host
gbolIsAHost = false                					-- defaults to NOT a host until the player chooses to be a host

Put the following code into love.update so that the host can do host things:

	if gbolIsAHost then
		ss.hostListenPort()
		
		-- get just one item from the queue and process it
		local incoming = ss.getItemInHostQueue()		-- could be nil
		if incoming ~= nil then
			print(inspect(incoming))
		end
	
		msg = whatever		-- string, number or table.
		ss.addItemToHostOutgoingQueue(msg)
		ss.sendToClients()
		msg = {}
	end

Put the following code into love.update so that clients can do client things:

	if gbolIsAClient then
		ss.clientListenPort()
		
		-- get just one item from the queue and process it
		local incoming = ss.getItemInClientQueue()		-- could be nil
		if incoming ~= nil then
			print(inspect(msg))
		end

		msg = whatever 		-- string, number or table.
		ss.addItemToClientOutgoingQueue(msg)	-- 
		ss.sendToHost()
		msg = {}
	end
	
]]



local socketstuff = {}

local hostIncomingQueue = {}
local clientIncomingQueue = {}
local hostOutgoingQueue = {}
local clientOutgoingQueue = {}
local cilentNodes = {}

local udpClient = nil
local udpHost = nil

function socketstuff.hostListenPort()
-- listens for a message and adds it to the queue
    local data, ip, port = udpHost:receivefrom()
	local unpackeddata
    if data then
		unpackeddata = bitser.loads(data)
        table.insert(hostIncomingQueue,unpackeddata)
    end
    -- socket.sleep(0.01)    -- this doesn't seem to do much so I removed it
	
	local node = {}
    node.ip = ip
    node.port = port
	
	if port == nil or unpackeddata == nil then
		-- no message, do nothing
	else
		local bolAddClient = true
		for k,v in pairs(cilentNodes) do
			if node.ip == v.ip and node.port == v.port then
				-- this node is already captured
				bolAddClient = false
				break
			end
		end
		if bolAddClient then
			table.insert(cilentNodes,node)
		end
	end

end


function socketstuff.clientListenPort()
    local data, msg = udpClient:receive()

	if data then
		local unpackeddata = bitser.loads(data)
        table.insert(clientIncomingQueue,unpackeddata)
    end
end


function socketstuff.getItemInHostQueue()
-- returns the first/oldest item in the message queue

	local retval
	if #hostIncomingQueue > 0 then
		retvalue = hostIncomingQueue[1]
		table.remove(hostIncomingQueue,1)
	else
		return nil
	end
	return retvalue
end


function socketstuff.getItemInClientQueue()
-- returns the first/oldest item in the message queue and deletes that item from the queue

	local retval
	if #clientIncomingQueue > 0 then
		retvalue = clientIncomingQueue[1]
		table.remove(clientIncomingQueue,1)
	else
		return nil
	end
	return retvalue
end


function socketstuff.addItemToClientOutgoingQueue(message)
-- adds item to the array for later sending

	if message ~= nil then
		table.insert(clientOutgoingQueue, message)
	end
end


function socketstuff.addItemToHostOutgoingQueue(message)
-- adds item to the array for later sending

	if message ~= nil then
		table.insert(hostOutgoingQueue, message)
	end
end


function socketstuff.sendToHost()
-- send the whole outgoing queue to the host

	while #clientOutgoingQueue > 0 do
		if clientOutgoingQueue[1] ~= nil then
			local serialdata = bitser.dumps(clientOutgoingQueue[1])
			udpClient:send(serialdata)
		end
		table.remove(clientOutgoingQueue,1)
	end
end


function socketstuff.sendToClients()
-- sends the whole outgoing queue to all of the clients
	while #hostOutgoingQueue > 0 do
		if hostOutgoingQueue[1] ~= nil then
		
			local serialdata = bitser.dumps(hostOutgoingQueue[1])
			for k,v in pairs(cilentNodes) do
				udpHost:sendto(serialdata, v.ip, v.port)
			end
		end
		table.remove(hostOutgoingQueue,1)
	end
end


function socketstuff.connectToHost(IPAddress, IPPort)
-- Client has decided to connect to host
-- TODO: implement IPAddress

    -- set up a client connect
    local address, port = "localhost", IPPort

    udpClient = socket.udp()
    udpClient:settimeout(0)
    udpClient:setpeername(address, port)
    gbolIsAClient = true
    gbolIsAHost = false
end


function socketstuff.startHosting(myServerPort)
    -- set up a server to listen
    udpHost = socket.udp()
    udpHost:settimeout(0)
    udpHost:setsockname('*', myServerPort)
    print("Server started on port " .. myServerPort)

end


return socketstuff
