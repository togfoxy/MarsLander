local socketstuff = {}

local arrHostIncomingQueue = {}
local arrClientIncomingQueue = {}
local arrHostOutgoingQueue = {}
local arrClientOutgoingQueue = {}
local arrClientNodes = {}

local function DedupClientList(listofclients)
-- dedupes the listofclients so that IP's and ports are recorded just once

	local seen = {}
	
	for k,v in pairs(listofclients) do
		if seen[v.ip] == v.port then
			-- this is seen
			table.remove(listofclients,k)
		else
			seen[v.ip] = v.port
		end
	end
end

function socketstuff.HostListenPort()
    local data, ip, port = udphost:receivefrom()
    if data then
		local unpackeddata = bitser.loads(data)
        table.insert(arrHostIncomingQueue,unpackeddata)
    end
    socket.sleep(0.01)    --! will this interfere with the client?
	
	local node = {}
    node.ip = ip
    node.port = port
    table.insert(arrClientNodes,node)
	DedupClientList(arrClientNodes)
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
	
-- print("Client sending value: ", arrClientOutgoingQueue[1])
		local serialdata = bitser.dumps(arrClientOutgoingQueue[1])
		udpclient:send(serialdata)
		table.remove(arrClientOutgoingQueue,1)
	end
end

function socketstuff.SendToClients()
-- sends the whole outgoing queue to all of the clients
	while #arrHostOutgoingQueue > 0 do
		local serialdata = bitser.dumps(arrHostOutgoingQueue[1])
		for k,v in pairs(arrClientNodes) do
			udphost:sendto(serialdata, v.ip, v.port)		--! see if "send" will work and will be faster
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














