local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local Types = require(script.Parent.Types)
local UITypes = require(ReplicatedStorage.Modules.Client.UI.UITypes)
local LayoutData = require(ReplicatedStorage.Modules.Shared.Layouts.LayoutData)

local colorPickers = (StarterGui:FindFirstChild("Main") :: UITypes.Main).ControllerEdit

type Color = {
	color: string, -- hex
	vipOnly: boolean,
}

local function GetColors(colorList: { Instance })
	local colors: { [string]: Color } = {}
	for i, v in colorList do
		if v:IsA("ImageButton") then
			local vipLabel = v:FindFirstChild("VIP") :: ImageLabel?
			local color = v.BackgroundColor3:ToHex()
			colors[v.BackgroundColor3:ToHex()] = {
				color = color,
				vipOnly = vipLabel ~= nil and vipLabel.Visible == true,
			}
		end
	end

	return colors
end

local PrimaryColors = GetColors(colorPickers.PrimaryColorPicker:GetChildren())
local AccentColors = GetColors(colorPickers.AccentColorPicker:GetChildren())

local Config = {
	StandTag = "DisplayStandSpot",
	OutfitStandTag = "OutfitDisplayStandSpot",

	NoBobTag = "NoBob",
	NoSpinTag = "NoSpin",
	ScaleTag = "Scale",

	PrimaryColorTag = "PrimaryColor",
	AccentColorTag = "AccentColor",
	TextureTag = "Texture",

	RenderedAccessoryTag = "RenderedAccessory",
	RenderedOutfitTag = "RenderedOutfit",
	RenderedClassicClothingTag = "RenderedClassicClothing",

	ShopNameTag = "ShopNameSign",

	StandRotationSpeed = math.rad(30),
	StandBobSpeed = 0.2,
	DefaultScale = 2.5,

	StandProximityOffset = Vector2.new(50, 0),

	-- Won't allow you to create new places if you exceed this number
	MaxPlaces = 30,

	-- Place names can't be longer than this
	MaxPlaceNameLength = 20,

	PrimaryColors = PrimaryColors,
	AccentColors = AccentColors,

	DefaultPrimaryColor = Color3.fromRGB(215, 197, 154),
	DefaultAccentColor = Color3.fromRGB(119, 122, 243),
	DefaultLayout = "Shop 1" :: LayoutData.LayoutId,
	DefaultShopThumbnail = 15664989981,

	DefaultFeed = "Random" :: Types.FeedType,

	-- Number of stands for a shop to show up on feeds
	-- MinimumStandsForRandom = 12,

	-- Proportion of stands used to show up on the random feed
	RequiredProportionForRandom = 0.6,

	-- Mutliplied by price in robux, to get the final bux amount
	BuxMultiplier = 2,

	MallSpeed = 33,
	ShopSpeed = 22,

	RandomShopTimeout = 20,

	CatalogCameraFov = 40,
}

assert(PrimaryColors[Config.DefaultPrimaryColor:ToHex()], "Default primary color was not a valid color")
assert(AccentColors[Config.DefaultAccentColor:ToHex()], "Default accent color was not a valid color")

return Config
