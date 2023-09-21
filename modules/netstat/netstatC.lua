local packetlossHistory = {}
local packetlossAvg = 0		-- (Output) Average packet loss over last 60 seconds
local packetlossPeak = 0		-- (Output) Peak packet loss over last 60 seconds

function samplePacketLoss()
	table.insert( packetlossHistory, getNetworkStats().packetlossLastSecond )
	while( #packetlossHistory > 60 ) do
		table.remove( packetlossHistory, 1 )
	end
	packetlossAvg = 0
	packetlossPeak = 0
	for _,value in ipairs(packetlossHistory) do
		packetlossAvg = packetlossAvg + value
		packetlossPeak = math.max( packetlossPeak, value )
	end
	packetlossAvg = packetlossAvg / #packetlossHistory
end

local old = 0
local bytesavg = 0

function bytesSentMonitor()
    local current = getNetworkStats().bytesSent
    if old > 0 then
        bytesavg = current - old
    end
    old = current
end

setTimer(
    function()
        samplePacketLoss()
        triggerServerEvent("FIREWALL:packetlossData", root, packetlossAvg)
        bytesSentMonitor()
        triggerServerEvent("FIREWALL:bytesSentData", root, bytesavg)
    end
    ,5000,0)