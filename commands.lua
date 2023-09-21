function accessSerial(params, player)
    local serial, discord = unpack(params)
    triggerEvent("FIREWALL:accessSerial", root, serial, discord, player)
end

function setSerialPriority(params, player)
    local serial = unpack(params)
    triggerEvent("FIREWALL:setSerialPriority", root, serial, player)
end

commands = {
    ["accessSerial"] = {
        funcao = accessSerial,
        totalparams = 2
    },
    ["setSerialPriority"] = {
        funcao = setSerialPriority,
        totalparams = 1
    }
}


addCommandHandler("firewall",
    function(theClient, commandName, metodo, ...)
        if hasObjectPermissionTo(theClient, "command.firewall") then
            if not commands[metodo] then
                outputChatBox("[FIREWALL] Este método não existe: /firewall "..metodo, theClient)
            elseif not metodo or not ... then
                outputChatBox("[FIREWALL] Sintaxe errada: /firewall [metodo] [parametro]", theClient)
            else
                local params = {...}
                local total = #params
                if total < commands[metodo].totalparams or total > commands[metodo].totalparams then
                    outputChatBox("[FIREWALL] Sintaxe errada: /firewall "..metodo.." [parametro]", theClient)
                else
                    local temp = {}
                    for i, p in ipairs(params) do
                        table.insert(temp, p)
                    end
                    commands[metodo].funcao(temp, theClient)
                end
            end
        end
    end
)