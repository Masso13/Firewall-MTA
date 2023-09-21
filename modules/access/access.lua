local playersLimit = getMaxPlayers()
local totalpriority = 0

function logWrite(data)
    local time = getRealTime()
    local hours = time.hour
	local minutes = time.minute
	local seconds = time.second

    local monthday = time.monthday
	local month = time.month + 1
	local year = time.year + 1900
    if month < 10 then
        month = "0"..month
    end
    if monthday < 10 then
        monthday = "0"..monthday
    end
    if hours < 10 then
        hours = "0"..hours
    end
    if minutes < 10 then
        minutes = "0"..minutes
    end
    if seconds < 10 then
        seconds = "0"..seconds
    end

    local datatime = "["..year.."-"..month.."-"..monthday.." "..hours..":"..minutes..":"..seconds.."]"

    local logFile = fileOpen("data/log.log")
    if logFile then
        local data = datatime.." | "..data
        fileSetPos(logFile, fileGetSize(logFile))
        fileWrite(logFile, data)
        fileFlush(logFile)
        fileClose(logFile)
    else
        outputConsole("O arquivo de log não existe")
    end
end

function verifyBanSerial(serial, ip)
    local result = false
    for banID, ban in ipairs(getBans()) do
        if ban then
            if getBanSerial(ban) == serial and getBanIP(ban) == ip then
                result = true
                break
            elseif getBanIP(ban) == ip then
                result = true
                break
            end
        end
    end
    return result
end

function verifySerial(serial)
    local whitelistDB = dbConnect("sqlite", "data/whitelist.db")
    local check = dbQuery(whitelistDB, "SELECT * FROM serial_list")
    local results = dbPoll(check, -1)

    local access = false

    for rid, rows in ipairs(results) do
        for coluna, valor in pairs(rows) do
            if coluna == "serial" and valor == serial then
                access=true
                break
            end
        end
    end
    return access
end

local avpn = {}
avpn.avoided = {
    "127.0.0.1",
}

addEvent("FIREWALL:accessSerial", false)
addEventHandler("FIREWALL:accessSerial", getRootElement(), 
    function(serial, discord, player)
        --outputChatBox(root)
        if not verifySerial(serial) then
            local whitelistDB = dbConnect("sqlite", "data/whitelist.db")
            if dbExec(whitelistDB, "INSERT INTO serial_list VALUES (?,?)", serial, discord) then
                outputChatBox("[FIREWALL] Acesso liberado para "..serial, player)
                logWrite("O operador "..getPlayerName(player)..":"..getPlayerSerial(player).." liberou o acesso do Serial: "..serial.." Discord: "..discord)
            end
        else
            outputChatBox("[FIREWALL] Este computador já está registrado em nossa base de dados !", player)
        end
    end
, true, "low")

function getTotalPriority()
    local whitelistDB = dbConnect("sqlite", "data/whitelist.db")
    local check = dbQuery(whitelistDB, "SELECT * FROM serial_priority")
    local results = dbPoll(check, -1)

    totalpriority = table.getn(results)

    return totalpriority
end

function verifySerialPriority(serial)
    local whitelistDB = dbConnect("sqlite", "data/whitelist.db")
    local check = dbQuery(whitelistDB, "SELECT * FROM serial_priority")
    local results = dbPoll(check, -1)

    local access = false

    for rid, rows in ipairs(results) do
        for coluna, valor in pairs(rows) do
            if coluna == "serial" and valor == serial then
                access=true
                break
            end
        end
    end
    return access
end

addEvent("FIREWALL:setSerialPriority", false)
addEventHandler("FIREWALL:setSerialPriority", getRootElement(), 
    function(serial, player)
        if not verifySerialPriority(serial) then
            local whitelistDB = dbConnect("sqlite", "data/whitelist.db")
            if dbExec(whitelistDB, "INSERT INTO serial_priority VALUES (?)", serial) then
                outputChatBox("[FIREWALL] Acesso com prioridade liberado para "..serial, player)
                logWrite("O operador "..getPlayerName(player)..":"..getPlayerSerial(player).." liberou o acesso com prioridade do Serial: "..serial)
            end
        else
            outputChatBox("[FIREWALL] Este computador já está com prioridade !", player)
        end
    end
, true, "low")

function avpn.check(playerIP)
    for _, ip in ipairs(avpn.avoided) do
		if ip == playerIP then outputDebugString("IP avoided.", 2) return false end
	end

    fetchRemote("http://proxy.mind-media.com/block/proxycheck.php?ip="..playerIP, 
        function(rdata, err)
            if err == 0 then
                local result = false
                if rdata == "Y" then
                    result = true
                elseif rdata == "X" then
                    result = "X"
                end
                return result
            end
        end
    )
end

addEventHandler("onPlayerConnect", getRootElement(), function(playerNick, playerIP, playerUsername, playerSerial, playerVersionNumber, playerVersionString)
    local in_vpn = avpn.check(playerIP)
    if not in_vpn then -- Não está usando VPN
        if verifySerial(playerSerial) then --Está registrado
            if not verifyBanSerial(playerSerial, playerIP) then --Não está banido
                local playerTotal = getPlayerCount()
                if playerTotal < playersLimit - getTotalPriority() then --Servidor não está lotado
                    logWrite("Nick: "..playerNick.." IP: "..playerIP.." Serial: "..playerSerial.."\n")
                else
                    if not verifySerialPriority(playerSerial) then
                        cancelEvent(true, "[FIREWALL] O servidor está lotado, tente novamente mais tarde")
                    else
                        logWrite("Prioridade -> Nick: "..playerNick.." IP: "..playerIP.." Serial: "..playerSerial.."\n")
                    end
                end
            else
                logWrite("Player: "..playerSerial.." tentou se conectar !".."\n")
                cancelEvent(true, "[FIREWALL] Este computador está banido do servidor !")
            end
        else
            logWrite("Serial: "..playerSerial.. " negado".."\n")
            cancelEvent( true, "[FIREWALL] Você não está na Whitelist do Servidor!\nRegistre-se em https://discord.gg/yDsW6Pz" ) 
        end
    elseif in_vpn then
        logWrite("VPN detectada no IP: "..playerIP.." Serial: "..playerSerial.."\n")
        cancelEvent(true, "[FIREWALL] VPN detectada")
    elseif in_vpn == "X" then
        logWrite("Erro com o IP: "..playerIP.." Serial: "..playerSerial.."\n")
        cancelEvent(true, "[FIREWALL] Algum problema com o seu IP\nComunique um ADM")
    end
end, true, "high+5")