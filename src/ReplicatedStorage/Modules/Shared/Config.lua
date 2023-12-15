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
}

return Config
