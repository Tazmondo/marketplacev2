export type Nav = ScreenGui & {
	Feed: Frame & {
		Frame: Frame & {
			Editor: ImageButton & {
				UIPadding: UIPadding,
				UICorner: UICorner,
				UIStroke: UIStroke,
				Feed: TextLabel,
				UIListLayout: UIListLayout,
			},
			Popular: ImageButton & {
				UIPadding: UIPadding,
				UICorner: UICorner,
				UIStroke: UIStroke,
				Feed: TextLabel,
				UIListLayout: UIListLayout,
			},
			UIListLayout: UIListLayout,
			UICorner: UICorner,
			Random: ImageButton & {
				UIPadding: UIPadding,
				UICorner: UICorner,
				UIStroke: UIStroke,
				Feed: TextLabel,
				UIListLayout: UIListLayout,
			},
			UIPadding: UIPadding,
		},
		Current: ImageButton & {
			UIPadding: UIPadding,
			UICorner: UICorner,
			Expand: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
				UIPadding: UIPadding,
			},
			Feed: TextLabel,
			UIListLayout: UIListLayout,
		},
	},
	Nav: Frame & {
		UIListLayout: UIListLayout,
		Me: Frame & {
			UIListLayout: UIListLayout,
			ImageButton: ImageButton & {
				UICorner: UICorner,
				UIStroke: UIStroke,
			},
		},
		UISizeConstraint: UISizeConstraint,
		Invite: ImageButton & {
			UICorner: UICorner,
			UIStroke: UIStroke,
			UIListLayout: UIListLayout,
			ImageButton: ImageLabel & {
				UICorner: UICorner,
			},
		},
	},
}

export type Main = ScreenGui & {
	Welcome: Frame & {
		UICorner: UICorner,
		Frame: Frame & {
			TextLabel: TextLabel,
			UIListLayout: UIListLayout,
			UIPadding: UIPadding,
			Content: Frame & {
				UIPadding: UIPadding,
				UIListLayout: UIListLayout,
			},
			Actions: Frame & {
				UIListLayout: UIListLayout,
				UISizeConstraint: UISizeConstraint,
				PrimaryButton: TextButton & {
					UIListLayout: UIListLayout,
					TextLabel: TextLabel,
					UICorner: UICorner,
				},
			},
		},
		UIPadding: UIPadding,
		UISizeConstraint: UISizeConstraint,
	},
	Showcase: Frame & {
		UIPadding: UIPadding,
		List: ScrollingFrame & {
			UIListLayout: UIListLayout,
			Row: Frame & {
				UIListLayout: UIListLayout,
				UIPadding: UIPadding,
				Thumb: ImageLabel & {
					UICorner: UICorner,
					UIStroke: UIStroke,
					Added: ImageLabel & {
						UICorner: UICorner,
						UIStroke: UIStroke,
					},
				},
				Details: Frame & {
					NameLabel: TextLabel,
					Serial: TextLabel,
					UIListLayout: UIListLayout,
				},
				UICorner: UICorner,
				UISizeConstraint: UISizeConstraint,
				Price: Frame & {
					Price: Frame & {
						UIListLayout: UIListLayout,
						Price: TextLabel,
						ImageLabel: ImageLabel,
					},
					Select: TextButton & {
						UICorner: UICorner,
					},
					UIListLayout: UIListLayout,
				},
			},
		},
		UICorner: UICorner,
		Title: Frame & {
			UIPadding: UIPadding,
			Close: Frame & {
				UIListLayout: UIListLayout,
				ImageButton: ImageButton & {
					UICorner: UICorner,
				},
			},
			UIListLayout: UIListLayout,
			UISizeConstraint: UISizeConstraint,
			Title: Frame & {
				UIListLayout: UIListLayout,
				TextLabel: TextLabel,
			},
		},
		UISizeConstraint: UISizeConstraint,
		UIListLayout: UIListLayout,
	},
	CreateShop: Frame & {
		UICorner: UICorner,
		Frame: Frame & {
			TextLabel: TextLabel,
			Actions: Frame & {
				UIListLayout: UIListLayout,
				TertiaryButton: TextButton & {
					UIListLayout: UIListLayout,
					TextLabel: TextLabel,
					UICorner: UICorner,
				},
				UISizeConstraint: UISizeConstraint,
				PrimaryButton: TextButton & {
					UIListLayout: UIListLayout,
					TextLabel: TextLabel,
					UICorner: UICorner,
				},
			},
			UIListLayout: UIListLayout,
			UIPadding: UIPadding,
			Content: Frame & {
				UIListLayout: UIListLayout,
				UIPadding: UIPadding,
			},
			ImageButton: ImageLabel,
		},
		UIPadding: UIPadding,
		UISizeConstraint: UISizeConstraint,
	},
	AddItemID: Frame & {
		Title: Frame & {
			Search: Frame & {
				UIListLayout: UIListLayout,
				ImageButton: ImageButton & {
					UICorner: UICorner,
				},
			},
			Close: Frame & {
				UIListLayout: UIListLayout,
				ImageButton: ImageButton & {
					UICorner: UICorner,
				},
			},
			UIListLayout: UIListLayout,
			TextLabel: TextLabel,
			UIPadding: UIPadding,
		},
		UICorner: UICorner,
		SearchWrapper: Frame & {
			UICorner: UICorner,
			Search: Frame & {
				UICorner: UICorner,
				Search: Frame & {
					Top: Frame & {
						UICorner: UICorner,
						ItemName: TextBox & {
							UIPadding: UIPadding,
							Toggle: TextButton & {
								UICorner: UICorner,
								TextLabel: TextLabel,
								UIListLayout: UIListLayout,
							},
							UIStroke: UIStroke,
							UIListLayout: UIListLayout,
							UICorner: UICorner,
						},
						Creator: TextBox & {
							UIPadding: UIPadding,
							Toggle: TextButton & {
								UICorner: UICorner,
								TextLabel: TextLabel,
								UIListLayout: UIListLayout,
							},
							UIStroke: UIStroke,
							UIListLayout: UIListLayout,
							UICorner: UICorner,
						},
						UIListLayout: UIListLayout,
					},
					UIPadding: UIPadding,
					Bottom: Frame & {
						OffSale: TextButton & {
							UICorner: UICorner,
							TextLabel: TextLabel,
							UIListLayout: UIListLayout,
						},
						Filter: TextButton & {
							UICorner: UICorner,
							TextLabel: TextLabel,
							UIListLayout: UIListLayout,
						},
						UIListLayout: UIListLayout,
						Max: TextBox & {
							UICorner: UICorner,
							UIStroke: UIStroke,
							UIPadding: UIPadding,
						},
						Min: TextBox & {
							UICorner: UICorner,
							UIStroke: UIStroke,
							UIPadding: UIPadding,
						},
						UICorner: UICorner,
					},
					UIListLayout: UIListLayout,
					Actions: Frame & {
						Search: TextButton & {
							UICorner: UICorner,
							TextLabel: TextLabel,
							UIListLayout: UIListLayout,
						},
						UIListLayout: UIListLayout,
					},
				},
				UISizeConstraint: UISizeConstraint,
				UIPadding: UIPadding,
			},
		},
		UISizeConstraint: UISizeConstraint,
		SearchResults: Frame & {
			UIListLayout: UIListLayout,
			UIPadding: UIPadding,
			Grid: ScrollingFrame & {
				Row: ImageButton & {
					UIPadding: UIPadding,
					Thumb: ImageLabel & {
						UICorner: UICorner,
						UIStroke: UIStroke,
					},
					Details: Frame & {
						NameLabel: TextLabel,
						Frame: Frame & {
							UIListLayout: UIListLayout,
							Price: TextLabel,
							ImageLabel: ImageLabel,
						},
						UIListLayout: UIListLayout,
					},
					UIListLayout: UIListLayout,
					UICorner: UICorner,
				},
				UIGridLayout: UIGridLayout,
			},
		},
	},
	ShopSettings: Frame & {
		UIPadding: UIPadding,
		UICorner: UICorner,
		Frame: Frame & {
			Thumbnail: Frame & {
				UICorner: UICorner,
				TextBox: TextBox & {
					UICorner: UICorner,
					UIPadding: UIPadding,
				},
				TextLabel: TextLabel,
				UIListLayout: UIListLayout,
			},
			UIPadding: UIPadding,
			ShopThumbnail: ImageLabel & {
				UICorner: UICorner,
				UIStroke: UIStroke,
			},
			UIListLayout: UIListLayout,
			Logo: Frame & {
				UICorner: UICorner,
				TextBox: TextBox & {
					UICorner: UICorner,
					UIPadding: UIPadding,
				},
				TextLabel: TextLabel,
				UIListLayout: UIListLayout,
			},
			Actions: Frame & {
				UIListLayout: UIListLayout,
				Save: TextButton & {
					UICorner: UICorner,
					TextLabel: TextLabel,
					UIListLayout: UIListLayout,
				},
			},
			ShopName: Frame & {
				UICorner: UICorner,
				["Shop Name"]: TextLabel,
				TextBox: TextBox & {
					UICorner: UICorner,
					UIPadding: UIPadding,
				},
				UIListLayout: UIListLayout,
			},
		},
		UISizeConstraint: UISizeConstraint,
		Title: Frame & {
			UIListLayout: UIListLayout,
			Close: ImageButton & {
				UICorner: UICorner,
				UIPadding: UIPadding,
			},
		},
	},
	Profile: Frame & {
		Total: Frame & {
			UIPadding: UIPadding,
			Close: Frame & {
				UIListLayout: UIListLayout,
				List: ImageButton & {
					UICorner: UICorner,
				},
				Grid: ImageButton & {
					UICorner: UICorner,
				},
			},
			UIListLayout: UIListLayout,
			Frame: Frame & {
				UIListLayout: UIListLayout,
				Frame: Frame & {
					UIListLayout: UIListLayout,
					ImageLabel: ImageLabel,
					Amount: TextLabel,
				},
				TextLabel: TextLabel & {
					UITextSizeConstraint: UITextSizeConstraint,
				},
			},
			UISizeConstraint: UISizeConstraint,
		},
		UIPadding: UIPadding,
		UIListLayout: UIListLayout,
		Grid: ScrollingFrame & {
			Row: ImageButton & {
				UIPadding: UIPadding,
				Thumb: ImageLabel & {
					UICorner: UICorner,
					UIStroke: UIStroke,
				},
				Details: Frame & {
					NameLabel: TextLabel,
					Frame: Frame & {
						UIListLayout: UIListLayout,
						Price: TextLabel,
						ImageLabel: ImageLabel,
					},
					UIListLayout: UIListLayout,
				},
				UIListLayout: UIListLayout,
				UICorner: UICorner,
			},
			UIGridLayout: UIGridLayout,
		},
		Title: Frame & {
			Title: Frame & {
				UIListLayout: UIListLayout,
				TextLabel: TextLabel,
			},
			Avatar: Frame & {
				UIListLayout: UIListLayout,
				ImageButton: ImageButton & {
					UICorner: UICorner,
				},
			},
			UIListLayout: UIListLayout,
			Close: Frame & {
				UIListLayout: UIListLayout,
				ImageButton: ImageButton & {
					UICorner: UICorner,
				},
			},
			UISizeConstraint: UISizeConstraint,
			UIPadding: UIPadding,
		},
		List: ScrollingFrame & {
			UIListLayout: UIListLayout,
			Row: ImageButton & {
				Price: Frame & {
					UIListLayout: UIListLayout,
					Frame: Frame & {
						UIListLayout: UIListLayout,
						Price: TextLabel,
						ImageLabel: ImageLabel,
					},
				},
				UIPadding: UIPadding,
				Thumb: ImageLabel & {
					UICorner: UICorner,
					UIStroke: UIStroke,
				},
				UICorner: UICorner,
				Details: Frame & {
					NameLabel: TextLabel & {
						UITextSizeConstraint: UITextSizeConstraint,
					},
					Serial: TextLabel & {
						UITextSizeConstraint: UITextSizeConstraint,
					},
					UIListLayout: UIListLayout,
				},
				UISizeConstraint: UISizeConstraint,
				UIListLayout: UIListLayout,
			},
		},
		Frame: Frame & {
			UIListLayout: UIListLayout,
			UIPadding: UIPadding,
			List: ScrollingFrame & {
				UIListLayout: UIListLayout,
				CreateShop: TextButton & {
					TextLabel: TextLabel,
					UICorner: UICorner,
					UIPadding: UIPadding,
					UIListLayout: UIListLayout,
					ImageLabel: ImageLabel,
				},
				Row: ImageButton & {
					Price: Frame & {
						UIListLayout: UIListLayout,
						Select: TextButton & {
							UICorner: UICorner,
						},
					},
					UIPadding: UIPadding,
					Thumb: ImageLabel & {
						UICorner: UICorner,
						UIStroke: UIStroke,
					},
					UICorner: UICorner,
					Details: Frame & {
						NameLabel: TextLabel,
						Frame: Frame & {
							UIListLayout: UIListLayout,
							Price: TextLabel,
							ImageLabel: ImageLabel,
						},
						UIListLayout: UIListLayout,
					},
					UISizeConstraint: UISizeConstraint,
					UIListLayout: UIListLayout,
				},
			},
		},
		UISizeConstraint: UISizeConstraint,
		UICorner: UICorner,
	},
	Item: Frame & {
		UICorner: UICorner,
		UISizeConstraint: UISizeConstraint,
		Content: Frame & {
			UIPadding: UIPadding,
			Details: Frame & {
				UIPadding: UIPadding,
				Available: Frame & {
					UIListLayout: UIListLayout,
					TextLabel: TextLabel,
					Amount: TextLabel,
				},
				UICorner: UICorner,
				UIListLayout: UIListLayout,
				Names: Frame & {
					UIListLayout: UIListLayout,
					ItemName: TextLabel,
					Creator: TextLabel,
				},
			},
			UIListLayout: UIListLayout,
			Actions: Frame & {
				UIListLayout: UIListLayout,
				Try: TextButton & {
					UICorner: UICorner,
					TextLabel: TextLabel,
					UIListLayout: UIListLayout,
				},
				Buy: TextButton & {
					UICorner: UICorner,
					UIListLayout: UIListLayout,
					TextLabel: TextLabel,
					ImageLabel: ImageLabel,
				},
			},
			ImageFrame: Frame & {
				UIListLayout: UIListLayout,
				UICorner: UICorner,
				UISizeConstraint: UISizeConstraint,
				ItemImage: ImageLabel,
			},
		},
		Title: Frame & {
			UIListLayout: UIListLayout,
			UIPadding: UIPadding,
			Close: Frame & {
				UIListLayout: UIListLayout,
				ImageButton: ImageButton & {
					UICorner: UICorner,
				},
			},
		},
	},
	ControllerEdit: Frame & {
		TexturePicker: Frame & {
			WoodColourless: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Pattern: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Tile: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			UICorner: UICorner,
			Plastic: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			UIGridLayout: UIGridLayout,
			Concrete: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Tile2: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			UIPadding: UIPadding,
		},
		ShareLink: Frame & {
			UIPadding: UIPadding,
			Thumb: ImageLabel,
			UICorner: UICorner,
			Details: Frame & {
				UIListLayout: UIListLayout,
				Title: TextLabel,
				Body: TextLabel,
			},
			UIListLayout: UIListLayout,
			TextBox: TextBox & {
				UICorner: UICorner,
				UIStroke: UIStroke,
				UIPadding: UIPadding,
			},
		},
		Wrapper: Frame & {
			Exit: TextButton & {
				UIListLayout: UIListLayout,
				UIPadding: UIPadding,
				TextLabel: TextLabel,
				UICorner: UICorner,
			},
			CurrentAccentColor: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
				UIPadding: UIPadding,
			},
			CurrentPrimaryColor: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
				UIPadding: UIPadding,
			},
			UIListLayout: UIListLayout,
			CurrentTexture: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
				UIPadding: UIPadding,
			},
			ShopSettings: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
				UIPadding: UIPadding,
			},
			CurrentLayout: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
				UIPadding: UIPadding,
			},
			ShareLink: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
				UIPadding: UIPadding,
			},
			UIPadding: UIPadding,
		},
		PrimaryColorPicker: Frame & {
			Rose: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			BabyYellow: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			UIPadding: UIPadding,
			Mint: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Purple: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			DarkRed: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Beige: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Brown: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Orange: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Blue: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			UICorner: UICorner,
			LightGray: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Pink: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Midnight: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			UIGridLayout: UIGridLayout,
			Black: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Green: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Cloud: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Yellow: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			LightBlue: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			White: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
		},
		UICorner: UICorner,
		LayoutPicker: Frame & {
			UICorner: UICorner,
			ScrollingFrame: ScrollingFrame & {
				UIListLayout: UIListLayout,
				Layout: ImageButton & {
					UICorner: UICorner,
					SelectedOutline: UIStroke,
				},
				UIPadding: UIPadding,
			},
		},
		UISizeConstraint: UISizeConstraint,
		AccentColorPicker: Frame & {
			Rose: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			BabyYellow: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			UIPadding: UIPadding,
			Mint: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Purple: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			DarkRed: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Beige: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Brown: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Orange: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Blue: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			UICorner: UICorner,
			LightGray: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Pink: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			LightBlue: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			UIGridLayout: UIGridLayout,
			Black: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Green: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Cloud: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Yellow: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			Midnight: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
			White: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
			},
		},
	},
	ControllerNav: Frame & {
		UIListLayout: UIListLayout,
		UIStroke: UIStroke,
		UIPadding: UIPadding,
		ShopInfo: Frame & {
			ProfileImage: ImageLabel & {
				UICorner: UICorner,
				UIStroke: UIStroke,
			},
			UIPadding: UIPadding,
			UICorner: UICorner,
			UIListLayout: UIListLayout,
			Text: Frame & {
				UIListLayout: UIListLayout,
				ShopName: TextLabel,
				CreatorName: TextButton,
			},
			ButtonLike: ImageButton & {
				UICorner: UICorner,
			},
			ButtonUnlike: ImageButton & {
				UICorner: UICorner,
			},
		},
		UICorner: UICorner,
		Forward: ImageButton & {
			UICorner: UICorner,
			UIPadding: UIPadding,
		},
		UISizeConstraint: UISizeConstraint,
		Back: ImageButton & {
			UICorner: UICorner,
			UIPadding: UIPadding,
		},
	},
	Explore: Frame & {
		UICorner: UICorner,
		ScrollingFrame: ScrollingFrame & {
			Row: ImageButton & {
				Thumb: ImageLabel & {
					UICorner: UICorner,
				},
				UICorner: UICorner,
				UIStroke: UIStroke,
				Details: Frame & {
					NameLabel: TextLabel,
					Price: TextLabel,
					UIListLayout: UIListLayout,
				},
				UIListLayout: UIListLayout,
			},
			UIGridLayout: UIGridLayout,
		},
		UIPadding: UIPadding,
		UISizeConstraint: UISizeConstraint,
	},
}

return {}
