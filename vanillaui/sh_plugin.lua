
PLUGIN.name = "Vanilla Networks UI"
PLUGIN.description = "Modifications to base Helix Derma."
PLUGIN.author = "sky"
--[[
function PLUGIN:InitializedPlugins()
	ix.bar.Add(function()
		return math.max(LocalPlayer():Health() / LocalPlayer():GetMaxHealth(), 0)
	end, Color(150, 50, 55), nil, "health")

	ix.bar.Add(function()
		return math.min(LocalPlayer():Armor() / 100, 1)
	end, Color(65, 75, 130), nil, "armor")
end
]]

ix.config.Add("communityText", "DISABLED",
	"THIS IS DISABLED", nil, {
	category = "appearance"
})
ix.config.Add("communityLogo", "https://i.gyazo.com/963f1c8ff7b7c9cd9e55adc13216d765.png", "The URL to navigate to when the community button is clicked.", nil, {
	category = "appearance"
})

function PLUGIN:DrawSimpleGradientBox(cornerSize, x, y, width, height, color, maxAlpha)
	local gradientAlpha = math.min(color.a, maxAlpha or 100);
	draw.RoundedBox(cornerSize, x, y, width, height, Color(color.r, color.g, color.b, color.a * 0.75));
		
	if (x + cornerSize < x + width and y + cornerSize < y + height) then
		surface.SetDrawColor(gradientAlpha, gradientAlpha, gradientAlpha, gradientAlpha)
		surface.SetTexture(surface.GetTextureID("gui/gradient_down"))
		surface.DrawTexturedRect(x + cornerSize, y + cornerSize, width - (cornerSize * 2), height - (cornerSize * 2))
	end
end

ix.util.Include("cl_skin.lua")
ix.util.Include("sv_hooks.lua")
ix.util.Include("cl_hooks.lua")
