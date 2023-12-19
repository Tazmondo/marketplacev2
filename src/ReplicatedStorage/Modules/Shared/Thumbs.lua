local Thumbs = {}

type AvatarResolution = "48" | "60" | "100" | "150" | "180" | "352" | "420" | "720"
type BustResolution = "50" | "60" | "75" | "100" | "150" | "180" | "352" | "420"
type HeadShotResolution = "48" | "60" | "100" | "150" | "180" | "352" | "420"
type AssetResolution = "150" | "420"

function Thumbs.GetAsset(assetId: number, resolution: AssetResolution?)
	return `rbxthumb://type=Asset&id={assetId}&w={resolution or "420"}&h={resolution or "420"}`
end

function Thumbs.GetHeadShot(userId: number, resolution: HeadShotResolution?)
	return `rbxthumb://type=AvatarHeadShot&id={userId}&w={resolution or "420"}&h={resolution or "420"}`
end

return Thumbs
