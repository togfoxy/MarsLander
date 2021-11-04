--[[
Socketstuff module by togfox October 2021. MIT license applies

Usage:
create three global variables in main.lua that will persistent and used for the life of the session:

gintServerPort = love.math.random(6000,6999)		-- this is the port each client needs to connect to
gbolIsAClient = false            					-- defaults to NOT a client until the player chooses to connect to a host
gbolIsAHost = false                					-- defaults to NOT a host until the player chooses to be a host

Put the following code into love.update so that the host can do host things:

	if gbolIsAHost then
		ss.HostListenPort()
		
		-- get just one item from the queue and process it
		local incoming = ss.GetItemInHostQueue()		-- could be nil
		if incoming ~= nil then
			print(inspect(incoming))
		end
	
		msg = whatever		-- string, number or table.
		ss.AddItemToHostOutgoingQueue(msg)
		ss.SendToClients()
		msg = {}
	end

Put the following code into love.update so that clients can do client things:

	if gbolIsAClient then
		ss.ClientListenPort()
		
		-- get just one item from the queue and process it
		local incoming = ss.GetItemInClientQueue()		-- could be nil
		if incoming ~= nil then
			print(inspect(msg))
		end

		msg = whatever 		-- string, number or table.
		ss.AddItemToClientOutgoingQueue(msg)	-- 
		ss.SendToHost()
		msg = {}
	end
	
]]



local socketstuff = {}

local arrHostIncomingQueue = {}
local arrClientIncomingQueue = {}
local arrHostOutgoingQueue = {}
local arrClientOutgoingQueue = {}
local arrClientNodes = {}

udpclient = nil
udphost = nil

function socketstuff.HostListenPort()
-- listens for a message and adds it to the queue
    local data, ip, port = udphost:receivefrom()
	local unpackeddata
    if data then
		unpackeddata = bitser.loads(data)
        table.insert(arrHostIncomingQueue,unpackeddata)
    end
    socket.sleep(0.01)    --! will this interfere with the client?
	
	local node = {}
    node.ip = ip
    node.port = port
	
	if port == nil or unpackeddata == nil then
		-- no message, do nothing
	else
		if cf.bolTableHasValue (arrClientNodes, node) then
		else
			table.insert(arrClientNodes,node)
		end
	end

print("~~~")	
print(#arrHostIncomingQueue)
end

function socketstuff.ClientListenPort()
    local data, msg = udpclient:receive()

	if data then
		local unpackeddata = bitser.loads(data)
        table.insert(arrClientIncomingQueue,unpackeddata)
    end

end

function socketstuff.GetItemInHostQueue()
-- returns the first/oldest item in the message queue

	local retval
	if #arrHostIncomingQueue > 0 then
		retvalue = arrHostIncomingQueue[1]
		table.remove(arrHostIncomingQueue,1)
	else
		return nil
	end
	return retvalue
end

function socketstuff.GetItemInClientQueue()
-- returns the first/oldest item in the message queue

	local retval
	if #arrClientIncomingQueue > 0 then
		retvalue = arrClientIncomingQueue[1]
		table.remove(arrClientIncomingQueue,1)
	else
		return nil
	end
	return retvalue
end

function socketstuff.AddItemToClientOutgoingQueue(message)
-- adds item to the array for later sending

	if message ~= nil then
		table.insert(arrClientOutgoingQueue, message)
	end
end

function socketstuff.AddItemToHostOutgoingQueue(message)
-- adds item to the array for later sending

	if message ~= nil then
		table.insert(arrHostOutgoingQueue, message)
	end
end

function socketstuff.SendToHost()
-- send the whole outgoing queue to the host

	while #arrClientOutgoingQueue > 0 do
		if arrClientOutgoingQueue[1] ~= nil then
			local serialdata = bitser.dumps(arrClientOutgoingQueue[1])
			udpclient:send(serialdata)
		end
		table.remove(arrClientOutgoingQueue,1)
	end
end

function socketstuff.SendToClients()
-- sends the whole outgoing queue to all of the clients
	while #arrHostOutgoingQueue > 0 do
	
		if arrHostOutgoingQueue[1] ~= nil then
			local serialdata = bitser.dumps(arrHostOutgoingQueue[1])
			for k,v in pairs(arrClientNodes) do
				udphost:sendto(serialdata, v.ip, v.port)		--! see if "send" will work and will be faster
			end
		end
		table.remove(arrHostOutgoingQueue,1)
	end
end

function socketstuff.ConnectToHost(IPAddress, IPPort)
-- Client has decided to connect to host
--! IPAddress is not used and probably should be

    -- set up a client connect
    local address, port = "localhost", IPPort

    udpclient = socket.udp()
    udpclient:settimeout(0)
    udpclient:setpeername(address, port)
    gbolIsAClient = true
    gbolIsAHost = false
end

function socketstuff.StartHosting(myServerPort)
    -- set up a server to listen
    udphost = socket.udp()
    udphost:settimeout(0)
    udphost:setsockname('*', myServerPort)
    print("Server started on port " .. myServerPort)

end

return socketstuff
