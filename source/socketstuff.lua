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
local clientNodes = {}

local udpClient = nil
local udpHost = nil

function socketstuff.hostListenPort()
-- listens for a message and adds it to the queue
    local data, ip, port = udpHost:receivefrom()
	local unpackedData
    if data then
		unpackedData = bitser.loads(data)
		
        table.insert(hostIncomingQueue,unpackedData)
    end
    -- socket.sleep(0.01)    -- this doesn't seem to do much so I removed it
	
	local node = {}
    node.ip = ip
    node.port = port
	
	if port == nil or unpackedData == nil then
		-- no message, do nothing
	else
		-- need to cycle through the list of known clients and see if this one is already captured
		local isNewClient = true
		for k,v in pairs(clientNodes) do
			if node.ip == v.ip and node.port == v.port then
				-- this node is already captured
				isNewClient = false
				break	-- abort the loop early
			end
		end
		-- it is determined this is a new client so record it in clientNodes table
		if isNewClient then
			table.insert(clientNodes,node)
		end
	end
end


function socketstuff.clientListenPort()
    local data, msg = udpClient:receive()

	if data then
		local unpackedData = bitser.loads(data)
        table.insert(clientIncomingQueue,unpackedData)
    end
end


function socketstuff.getItemInHostQueue()
-- returns the first/oldest item in the message queue

	local oldestMessage
	if #hostIncomingQueue > 0 then
		oldestMessage = hostIncomingQueue[1]
		table.remove(hostIncomingQueue,1)
	end
	return oldestMessage
end


function socketstuff.getItemInClientQueue()
-- returns the first/oldest item in the message queue and deletes that item from the queue

	local oldestMessage
	if #clientIncomingQueue > 0 then
		oldestMessage = clientIncomingQueue[1]
		table.remove(clientIncomingQueue,1)
	end
	return oldestMessage	-- might be nil
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
			local serialData = bitser.dumps(clientOutgoingQueue[1])
			local myerr, mymsg = udpClient:send(serialData)
			
print(inspect(clientOutgoingQueue[1]), myerr,mymsg)
print("~~")

		end
		table.remove(clientOutgoingQueue,1)
	end
end


function socketstuff.sendToClients()
-- sends the whole outgoing queue to all of the clients
	while #hostOutgoingQueue > 0 do
		if hostOutgoingQueue[1] ~= nil then
			local serialData = bitser.dumps(hostOutgoingQueue[1])
			for _,v in pairs(clientNodes) do
				udpHost:sendto(serialData, v.ip, v.port)
			end
		end
		table.remove(hostOutgoingQueue,1)
	end
end


function socketstuff.connectToHost(IPAddress, port)
-- Client has decided to connect to host
-- TODO: implement IPAddress

    -- set up a client connection
	
    udpClient = socket.udp()
    udpClient:settimeout(0)
	
    myerr, mymsg = udpClient:setpeername(IPAddress, port)
	
    gbolIsAClient = true
    gbolIsAHost = false
end


function socketstuff.startHosting(myServerPort)
    -- set up a server to listen
    udpHost = socket.udp()
    udpHost:settimeout(0)
    udpHost:setsockname('*', myServerPort)
	local sockname = udpHost:getsockname()
    print("Server started on port " .. sockname, myServerPort)

end


return socketstuff
