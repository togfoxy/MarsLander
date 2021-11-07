

local EnetHander = {}

local server
local client

local hostOutgoingQueue = {}

function EnetHander.CreateHost()
	server = sock.newServer("localhost", 22122)
	
    -- Called when receiving a message of type "connect"
    server:on("connect", function(data, client)
        -- Send a message of type "wecloe" back to the connected client
        local msg = "connected"
		-- sends a message to the client.  Which client?!?!
        client:send("welcome", msg)
		table.insert(garrLanders, Lander.create())
		
		msg = tostring(server:getClientCount())
		client:send("clientcount", msg)

	end)
	
end

function EnetHander.addItemToHostOutgoingQueue(message)
-- adds item to the array for later sending

	if message ~= nil then
		table.insert(hostOutgoingQueue, message)
	end
end

function EnetHander.CreateClient()
	client = sock.newClient("localhost", 22122)
	
    -- Send the message "connect"
    client:on("connect", function(data)
        print("Client trying to connect to the server.")
	end)
	
    -- When receiving a message of type 'welcome'
    client:on("welcome", function(msg)
        print(msg)
		if not enetIsConnected then
			fun.AddScreen("World")
			enetIsConnected = true
		end
	end)
	
	client:on("clientcount", function(data)
		print(data + 1)
	end)
	
	client:connect()
	
end

function EnetHander.update(dt)


	if gbolIsAHost then
		server:update()
	end
	
	if gbolIsAClient then
		client:update()
	end
	
	
end


return EnetHander






















