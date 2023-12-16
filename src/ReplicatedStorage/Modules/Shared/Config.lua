local PrimaryColors: { [string]: boolean } = {
	[Color3.fromRGB(215, 197, 154):ToHex()] = true,
}

local AccentColors: { [string]: boolean } = {
	[Color3.fromRGB(124, 92, 70):ToHex()] = true,
}

local Config = {
	StandTag = "DisplayStandSpot",
	NoBobTag = "NoBob",
	NoSpinTag = "NoSpin",
	ScaleTag = "Scale",

	PrimaryColorTag = "PrimaryColor",
	AccentColorTag = "AccentColor",
	TextureTag = "Texture",

	StandRotationSpeed = math.rad(75),
	StandBobSpeed = 0.2,
	DefaultScale = 2.5,

	-- Won't allow you to create new places if you exceed this number
	MaxPlaces = 20,

	-- Place names can't be longer than this
	MaxPlaceNameLength = 20,

	PrimaryColors = PrimaryColors,
	AccentColors = AccentColors,
	DefaultPrimaryColor = Color3.fromRGB(215, 197, 154),
	DefaultAccentColor = Color3.fromRGB(124, 92, 70),
}

assert(PrimaryColors[Config.DefaultPrimaryColor:ToHex()], "Default primary color was not a valid color")
assert(AccentColors[Config.DefaultAccentColor:ToHex()], "Default accent color was not a valid color")

return Config
