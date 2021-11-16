

local EnetHandler = {}

local server
local client

local TIMER_HOST_SEND_INTERVAL = 0.04
local timerHostSendTimer = TIMER_HOST_SEND_INTERVAL

local timerClientSendInterval = 0.04
local timerClientSendTimer = timerClientSendInterval



function EnetHandler.disconnectHost()
	ENET_IS_CONNECTED = false
	IS_A_HOST = false
	server:sendToAll("hostshutdown")
	server:update()
	server:destroy()
end



function EnetHandler.disconnectClient(clientConnectionID)
-- client is disconnecting. Send msg to host
	ENET_IS_CONNECTED = false
	IS_A_CLIENT = false

	client:send("clientdisconnect", clientConnectionID)
	client:update()
end



function EnetHandler.createHost()
-- called by menu

	server = Sock.newServer("*", 22122)
	ENET_IS_CONNECTED = true
	
    -- Called when receiving a message of type "connect"
    server:on("connect", function(data, client)
        -- Send a message of type "welcome" back to the connected client
		client:send("welcome", client:getConnectId())
		
		local newLander = Lander.create()
		newLander.connectionID = client:getConnectId()
		table.insert(LANDERS, newLander)
		
		LovelyToasts.show("Client connected",3, "top")
	end)
	
	server:on("clientdata", function(lander, clientInfo)

		-- match the incoming lander object
		for _,v in pairs(LANDERS) do
			if v.connectionID == lander.connectionID then
				v.x = lander.x 
				v.y = lander.y
				v.connectionID = lander.connectionID	-- used by enet
				v.angle = lander.angle
				v.engineOn = lander.engineOn
				v.leftEngineOn = lander.leftEngineOn
				v.rightEngineOn = lander.rightEngineOn
				v.score = lander.score
				v.name = lander.name
				break
			end
		end
	end)
	
	server:on("clientdisconnect", function(clientConnectionID, clientInfo)
		local isLanderFound = false
		local myLanderIndex
		for k,lander in pairs(LANDERS) do
			myLanderIndex = k
			if lander.connectionID == clientConnectionID then
				isLanderFound = true
				break
			end
		end
		if isLanderFound then
			table.remove(LANDERS, myLanderIndex)
			print("client " .. myLanderIndex .. " is removed.")
		end
	end)
end

function EnetHandler.createClient()
-- called by menu

	LovelyToasts.show("Trying to connect on " .. GAME_SETTINGS.hostIP,3, "middle")

	client = Sock.newClient(GAME_SETTINGS.hostIP, 22122)
	
	-- these are all the types of messages the client could receive from the host
	
    client:on("connect", function(data)
        print("Client trying to connect to the server.")
	end)
	
    client:on("welcome", function(msg)
        print("My connection ID is " .. msg)
		assert(msg == client:getConnectId())
		
		LANDERS[1].connectionID = msg
		
		if not ENET_IS_CONNECTED then
			Fun.AddScreen("World")
			ENET_IS_CONNECTED = true
		end
	end)
	
	client:on("peerupdate", function(peerLander)
		-- have received information about other peers
		-- cycle through list of known peers
		-- if peer is new (unknown) then update list of known peers
		if LANDERS[1].connectionID ~= peerLander.connectionID then
			local isLanderFound = false
			local myindex
			for k,lander in pairs(LANDERS) do
				myindex = k
				if lander.connectionID == peerLander.connectionID then
					isLanderFound = true
					break
				end
			end
			if isLanderFound == false then
				table.insert(LANDERS, peerLander)
			else
				LANDERS[myindex] = peerLander
			end
		end
	end)
	
    -- Called when the client disconnects from the server
    client:on("disconnect", function(data)
        print("Client disconnected from the server.")
    end)
	
	client:on("hostshutdown", function()
		client:disconnect()
		ENET_IS_CONNECTED = false
		IS_A_CLIENT = false
		for i = 1, #LANDERS do
			if i > 1 then
				table.remove(LANDERS, i)
			end
		end
	end)
		
	client:connect()
end

function EnetHandler.update(dt)

	if IS_A_HOST then
		timerHostSendTimer = timerHostSendTimer - dt
		if timerHostSendTimer <= 0 then
			timerHostSendTimer = TIMER_HOST_SEND_INTERVAL
			for _, lander in pairs(LANDERS) do
				server:sendToAll("peerupdate",lander)
			end
		end
		
		server:update()
	end
	
	if IS_A_CLIENT then
		timerClientSendTimer = timerClientSendTimer - dt
		if timerClientSendTimer <= 0 then
			timerClientSendTimer = timerClientSendInterval
			client:send("clientdata", LANDERS[1])
		end
	
		client:update()
	end

end


return EnetHandler
