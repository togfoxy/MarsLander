

local EnetHander = {}

local server
local client

local timerHostSendInterval = 0.2
local timerHostSendTimer = timerHostSendInterval

local timerClientSendInterval = 0.2
local timerClientSendTimer = timerClientSendInterval

function EnetHander.CreateHost()
-- called by menu
	server = sock.newServer("localhost", 22122)
	
    -- Called when receiving a message of type "connect"
    server:on("connect", function(data, client)
        -- Send a message of type "welcome" back to the connected client
		client:send("welcome", client:getConnectId())
		
		newLander = Lander.create()
		newLander.connectionID = client:getConnectId()
		table.insert(garrLanders, newLander)
	end)
	
	server:on("clientdata", function(landerObject, clientInfo)
		-- match the incoming lander object
		for k,v in pairs(garrLanders) do
-- print(v.connectionID, landerObject.connectionID)
			if v.connectionID == landerObject.connectionID then
				v.x = landerObject.x
				v.y = landerObject.y
				v.angle = landerObject.angle
				v.name = landerObject.name
				break
			end
		end
	end)
end

function EnetHander.CreateClient()
-- called by menu

	client = sock.newClient("localhost", 22122)
	
	-- these are all the types of messages the client could receive from the host
	
    client:on("connect", function(data)
        print("Client trying to connect to the server.")
	end)
	
    client:on("welcome", function(msg)
        print("My connection ID is " .. msg)
		assert(msg == client:getConnectId())
		
		garrLanders[1].connectionID = msg
		
		if not enetIsConnected then
			fun.AddScreen("World")
			enetIsConnected = true
		end
	end)
	
	client:on("clientcount", function(neededNumOfLanders)

	end)
	
	client:on("peerupdate", function(peerLander)
		if garrLanders[1].connectionID == peerLander.connectionID then
			-- nothing to do
		else
			local bolIsLanderFound = false
			local myindex
			for k,v in pairs(garrLanders) do
				myindex = k
				if v.connectionID == peerLander.connectionID then
					bolIsLanderFound = true
					break
				end
			end
			if bolIsLanderFound == false then
				table.insert(garrLanders, peerLander)
			else
				garrLanders[myindex] = peerLander
			end
		end
	end)
	
	client:connect()
end

function EnetHander.update(dt)


	if gbolIsAHost then
		timerHostSendTimer = timerHostSendTimer - dt
		if timerHostSendTimer <= 0 then
			timerHostSendTimer = timerHostSendInterval
			for _, lander in pairs(garrLanders) do
				server:sendToAll("peerupdate",lander)
			end
		end
		
		server:update()
	end
	
	if gbolIsAClient then
		timerClientSendTimer = timerClientSendTimer - dt
		if timerClientSendTimer <= 0 then
			timerClientSendTimer = timerClientSendInterval
			client:send("clientdata", garrLanders[1])
		end
	
		client:update()
	end

end


return EnetHander






















