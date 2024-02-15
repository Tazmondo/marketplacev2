return {
	Name = "addbux",
	Description = "Add shopbux",
	Group = "Admin",
	Args = {
		{
			Type = "number",
			Name = "Amount",
			Description = "Amount of shopbux to give/remove",
		},
		{
			Type = "players",
			Name = "Targets",
			Description = "The players to add shopbux to",
		},
	},
}
