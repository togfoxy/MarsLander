

local EnetHandler = {}

local server
local client

local TIMER_HOST_SEND_INTERVAL = 0.05
local timerHostSendTimer = TIMER_HOST_SEND_INTERVAL

local timerClientSendInterval = 0.05
local timerClientSendTimer = timerClientSendInterval

function EnetHandler.createHost()
-- called by menu

	server = Sock.newServer(HOST_IP_ADDRESS, 22122)
	
    -- Called when receiving a message of type "connect"
    server:on("connect", function(data, client)
        -- Send a message of type "welcome" back to the connected client
		client:send("welcome", client:getConnectId())
		
		local newLander = Lander.create()
		newLander.connectionID = client:getConnectId()
		table.insert(LANDERS, newLander)
	end)
	
	server:on("clientdata", function(lander, clientInfo)
		-- match the incoming lander object
		for k,v in pairs(LANDERS) do
			if v.connectionID == lander.connectionID then
				v.x = lander.x
				v.y = lander.y
				v.angle = lander.angle
				v.name = lander.name
				break
			end
		end
	end)
end

function EnetHandler.createClient()
-- called by menu

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
		if LANDERS[1].connectionID == peerLander.connectionID then
			-- nothing to do
		else
			local isLanderFound = false
			local myindex
			for k,v in pairs(LANDERS) do
				myindex = k
				if v.connectionID == peerLander.connectionID then
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
