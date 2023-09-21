addEvent("FIREWALL:packetlossData", true)
addEventHandler("FIREWALL:packetlossData", getRootElement(),
    function(avg)
        if avg > 40 then
            kickPlayer(client, "[FIREWALL] Conexão instável, tente novamente mais tarde !")
        end
    end
, true, "low")

addEvent("FIREWALL:bytesSentData", true)
addEventHandler("FIREWALL:bytesSentData", getRootElement(),
    function(avg)
        if avg >= 15000 then
            kickPlayer(client, "[FIREWALL] Quantidade extra de pacotes detectada !")
        end
    end
, true, "low")