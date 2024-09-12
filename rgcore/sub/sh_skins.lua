if (SERVER) then
    PLUGIN.skinWaitList = PLUGIN.skinWaitList or {}

    function PLUGIN:OnCharacterCreated(client, character)
        local skin = self.skinWaitList[client]
        if (skin and skin != nil and skin > 0) then
            character:SetData("skin", skin)
            self.skinWaitList[client] = nil
        end
    end

    util.AddNetworkString("RGSetCharacterCreationSkin")
    net.Receive("RGSetCharacterCreationSkin", function(len, ply) 
        local rgcore = ix.plugin.Get("rgcore")
        if (rgcore.skinWaitList) then
            rgcore.skinWaitList[ply] = net.ReadInt(6)
        end
    end)
end