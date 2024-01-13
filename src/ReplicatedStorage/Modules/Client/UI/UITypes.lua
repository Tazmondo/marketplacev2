export type Nav = ScreenGui & {
	Feed: Frame & {
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
		Search: ImageButton & {
			UICorner: UICorner,
			Toggle: TextButton & {
				UICorner: UICorner,
				TextLabel: TextLabel,
				UIListLayout: UIListLayout,
			},
			Creator: TextBox & {
				UICorner: UICorner,
				UIPadding: UIPadding,
			},
			UIListLayout: UIListLayout,
		},
		ActionButton: Frame & {
			UICorner: UICorner,
			UIListLayout: UIListLayout,
			ImageButton: ImageButton & {
				SearchIcon: ImageLabel & {
					UICorner: UICorner,
				},
				UIListLayout: UIListLayout,
				CloseIcon: ImageLabel & {
					UICorner: UICorner,
				},
				UICorner: UICorner,
			},
		},
		Frame: Frame & {
			Editor: ImageButton & {
				UIListLayout: UIListLayout,
				UIPadding: UIPadding,
				Feed: TextLabel,
				UICorner: UICorner,
			},
			Popular: ImageButton & {
				UIListLayout: UIListLayout,
				UIPadding: UIPadding,
				Feed: TextLabel,
				UICorner: UICorner,
			},
			UIListLayout: UIListLayout,
			UICorner: UICorner,
			Random: ImageButton & {
				UIListLayout: UIListLayout,
				UIPadding: UIPadding,
				Feed: TextLabel,
				UICorner: UICorner,
			},
			UIPadding: UIPadding,
		},
		UISizeConstraint: UISizeConstraint,
	},
	Nav: Frame & {
		Profile: Frame & {
			ImageButton: ImageButton & {
				UICorner: UICorner,
			},
			Frame: Frame & {
				Body: TextLabel,
				UICorner: UICorner,
				UIListLayout: UIListLayout,
				Shops: ImageLabel,
				ImageLabel: ImageLabel & {
					UICorner: UICorner,
				},
			},
		},
		Catalog: Frame & {
			Frame: Frame & {
				UIListLayout: UIListLayout,
				Body: TextLabel,
				ImageLabel: ImageLabel,
			},
			ImageButton: ImageButton & {
				UICorner: UICorner,
			},
		},
		UIListLayout: UIListLayout,
		UISizeConstraint: UISizeConstraint,
		Inventory: Frame & {
			Frame: Frame & {
				UIListLayout: UIListLayout,
				Body: TextLabel,
				ImageLabel: ImageLabel,
			},
			ImageButton: ImageButton & {
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
	Avatar: Frame & {
		UICorner: UICorner,
		Content: Frame & {
			Wearing: ScrollingFrame & {
				UIListLayout: UIListLayout,
				UIPadding: UIPadding,
				Row: Frame & {
					UIListLayout: UIListLayout,
					ImageFrame: Frame & {
						UICorner: UICorner,
						Frame: Frame & {
							UIListLayout: UIListLayout,
							ItemImage: ImageLabel & {
								UICorner: UICorner,
							},
						},
						UISizeConstraint: UISizeConstraint,
						Close: Frame & {
							UIListLayout: UIListLayout,
							ImageButton: ImageButton & {
								UICorner: UICorner,
								UIStroke: UIStroke,
							},
						},
					},
					Details: Frame & {
						UIListLayout: UIListLayout,
						Text: Frame & {
							UIListLayout: UIListLayout,
							ShopName: TextLabel,
							CreatorName: TextButton,
						},
						Buy: TextButton & {
							UICorner: UICorner,
							UIListLayout: UIListLayout,
							TextLabel: TextLabel,
							ImageLabel: ImageLabel,
						},
					},
					UICorner: UICorner,
				},
			},
			Title: Frame & {
				UIPadding: UIPadding,
				Close: Frame & {
					UIListLayout: UIListLayout,
					ImageButton: ImageButton & {
						UICorner: UICorner,
					},
				},
				UIListLayout: UIListLayout,
				Refresh: Frame & {
					UIListLayout: UIListLayout,
					ImageButton: ImageButton & {
						UICorner: UICorner,
					},
				},
				TextLabel: TextLabel,
			},
			UIListLayout: UIListLayout,
			Frame: Frame & {
				UIListLayout: UIListLayout,
				Frame: Frame & {
					Tab2: TextButton & {
						UICorner: UICorner,
						TextLabel: TextLabel,
						UIListLayout: UIListLayout,
					},
					UICorner: UICorner,
					UIListLayout: UIListLayout,
					Tab1: TextButton & {
						UICorner: UICorner,
						TextLabel: TextLabel,
						UIListLayout: UIListLayout,
					},
				},
				UIPadding: UIPadding,
			},
			Outfits: ScrollingFrame & {
				UIPadding: UIPadding,
				UIGridLayout: UIGridLayout,
			},
		},
		UISizeConstraint: UISizeConstraint,
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
				UISizeConstraint: UISizeConstraint,
				UIPadding: UIPadding,
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
		UICorner: UICorner,
		Frame: Frame & {
			UIListLayout: UIListLayout,
			UIPadding: UIPadding,
			List: ScrollingFrame & {
				UIListLayout: UIListLayout,
				CreateShop: TextButton & {
					UIListLayout: UIListLayout,
					TextLabel: TextLabel,
					UICorner: UICorner,
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
				Frame: Frame & {
					UIListLayout: UIListLayout,
					UIPadding: UIPadding,
					UICorner: UICorner,
				},
			},
		},
		UISizeConstraint: UISizeConstraint,
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
	Confirm: Frame & {
		Title: TextLabel,
		UIPadding: UIPadding,
		UICorner: UICorner,
		UIListLayout: UIListLayout,
		Actions: Frame & {
			UIListLayout: UIListLayout,
			SecondaryButton: TextButton & {
				UIListLayout: UIListLayout,
				TextLabel: TextLabel,
				UICorner: UICorner,
			},
			PrimaryButton: TextButton & {
				UIListLayout: UIListLayout,
				TextLabel: TextLabel,
				UICorner: UICorner,
			},
		},
		UISizeConstraint: UISizeConstraint,
		Body: TextLabel,
	},
	Outfits: Frame & {
		UICorner: UICorner,
		Content: Frame & {
			UIListLayout: UIListLayout,
			OutfitItems: ScrollingFrame & {
				UIListLayout: UIListLayout,
				Title: Frame & {
					UIListLayout: UIListLayout,
					ShopName: TextLabel,
					Close: Frame & {
						UIListLayout: UIListLayout,
						ImageButton: ImageButton & {
							UICorner: UICorner,
						},
					},
				},
				UIPadding: UIPadding,
			},
			Outfits: ScrollingFrame & {
				UIGridLayout: UIGridLayout,
				UIPadding: UIPadding,
			},
			Title: Frame & {
				UIListLayout: UIListLayout,
				TextLabel: TextLabel,
				UIPadding: UIPadding,
				Close: Frame & {
					UIListLayout: UIListLayout,
					ImageButton: ImageButton & {
						UICorner: UICorner,
					},
				},
			},
		},
		UISizeConstraint: UISizeConstraint,
	},
	ControllerNav: Frame & {
		UIListLayout: UIListLayout,
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
			UIListLayout: UIListLayout,
		},
		UIPadding: UIPadding,
		UICorner: UICorner,
		ScrollingFrame: ScrollingFrame & {
			UIGridLayout: UIGridLayout,
		},
		UIListLayout: UIListLayout,
	},
}

export type Catalog = ScreenGui & {
	Catalog: Frame & {
		UIListLayout: UIListLayout,
		RightPane: Frame & {
			Overlay: Frame & {
				Search: Frame & {
					Divider: Frame,
					UISizeConstraint: UISizeConstraint,
					Search: Frame & {
						UIListLayout: UIListLayout,
						UIPadding: UIPadding,
						Search: TextBox & {
							UIListLayout: UIListLayout,
							UIStroke: UIStroke,
							UIPadding: UIPadding,
						},
					},
				},
				Filter: Frame & {
					Divider: Frame,
					UISizeConstraint: UISizeConstraint,
					Search: Frame & {
						Top: Frame & {
							UICorner: UICorner,
							UIListLayout: UIListLayout,
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
							IsLimited: TextButton & {
								UICorner: UICorner,
								TextLabel: TextLabel,
								UIListLayout: UIListLayout,
							},
						},
						UIListLayout: UIListLayout,
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
					},
				},
				UIListLayout: UIListLayout,
				Actions: Frame & {
					UIListLayout: UIListLayout,
					Search: TextButton & {
						UIListLayout: UIListLayout,
						ItemImage: ImageLabel,
						UICorner: UICorner,
						Close: ImageLabel & {
							UICorner: UICorner,
						},
					},
					UISizeConstraint: UISizeConstraint,
					Filter: TextButton & {
						TextLabel: TextLabel & {
							UITextSizeConstraint: UITextSizeConstraint,
						},
						Close: ImageLabel & {
							UICorner: UICorner,
						},
						UICorner: UICorner,
						UIListLayout: UIListLayout,
						ItemImage: ImageLabel & {
							UICorner: UICorner,
						},
					},
				},
				Spacer: Frame,
			},
			Marketplace: Frame & {
				Categories: Frame & {
					Frame: Frame & {
						UICorner: UICorner,
						List: ScrollingFrame & {
							UIListLayout: UIListLayout,
							Template: TextButton & {
								UIListLayout: UIListLayout,
								TextLabel: TextLabel & {
									UITextSizeConstraint: UITextSizeConstraint,
								},
							},
							UIPadding: UIPadding,
						},
					},
					UISizeConstraint: UISizeConstraint,
				},
				Tabs: Frame & {
					Categories: Frame & {
						UICorner: UICorner,
						List: ScrollingFrame & {
							Wearing: TextButton & {
								TextLabel: TextLabel & {
									UITextSizeConstraint: UITextSizeConstraint,
								},
								UIListLayout: UIListLayout,
								UICorner: UICorner,
								ItemImage: ImageLabel & {
									UICorner: UICorner,
								},
							},
							Accessories: TextButton & {
								TextLabel: TextLabel & {
									UITextSizeConstraint: UITextSizeConstraint,
								},
								UIListLayout: UIListLayout,
								UICorner: UICorner,
								ItemImage: ImageLabel & {
									UICorner: UICorner,
								},
							},
							Clothing: TextButton & {
								TextLabel: TextLabel & {
									UITextSizeConstraint: UITextSizeConstraint,
								},
								UICorner: UICorner,
								UIListLayout: UIListLayout,
								ItemImage: ImageLabel & {
									UICorner: UICorner,
								},
							},
							UIListLayout: UIListLayout,
							UIPadding: UIPadding,
							Characters: TextButton & {
								TextLabel: TextLabel & {
									UITextSizeConstraint: UITextSizeConstraint,
								},
								UIListLayout: UIListLayout,
								UICorner: UICorner,
								ItemImage: ImageLabel & {
									UICorner: UICorner,
								},
							},
							Body: TextButton & {
								TextLabel: TextLabel & {
									UITextSizeConstraint: UITextSizeConstraint,
								},
								UIListLayout: UIListLayout,
								UICorner: UICorner,
								ItemImage: ImageLabel & {
									UICorner: UICorner,
								},
							},
						},
					},
					UISizeConstraint: UISizeConstraint,
					UIListLayout: UIListLayout,
				},
				UIListLayout: UIListLayout,
				UIPadding: UIPadding,
				Divider: Frame,
				Results: Frame & {
					UIListLayout: UIListLayout,
					ListWrapper: Frame & {
						UIPadding: UIPadding,
						List: ScrollingFrame & {
							OutfitWrapper: ImageButton & {
								UICorner: UICorner,
								UIStroke: UIStroke,
								Title: TextButton & {
									UICorner: UICorner,
									UISizeConstraint: UISizeConstraint,
									TextLabel: TextLabel,
									UIListLayout: UIListLayout,
								},
								ImageFrame: Frame & {
									Frame: Frame & {
										UIListLayout: UIListLayout,
										OutfitImage: ViewportFrame,
									},
								},
							},
							UIGridLayout: UIGridLayout,
							ItemWrapper: ImageButton & {
								Owned: TextLabel & {
									UICorner: UICorner,
									UISizeConstraint: UISizeConstraint,
									TextLabel: TextLabel,
									UIListLayout: UIListLayout,
								},
								Title: TextButton & {
									UICorner: UICorner,
									UISizeConstraint: UISizeConstraint,
									TextLabel: TextLabel,
									UIListLayout: UIListLayout,
								},
								IsLimited: TextLabel & {
									UIListLayout: UIListLayout,
									UICorner: UICorner,
									ImageLabel: ImageLabel,
								},
								ImageFrame: Frame & {
									Frame: Frame & {
										UIListLayout: UIListLayout,
										ItemImage: ImageLabel & {
											UICorner: UICorner,
										},
									},
								},
								UIStroke: UIStroke,
								UICorner: UICorner,
								Buy: TextButton & {
									TextLabel: TextLabel,
									UICorner: UICorner,
									UIListLayout: UIListLayout,
									UISizeConstraint: UISizeConstraint,
									ImageLabel: ImageLabel,
								},
							},
							NewOutfit: ImageButton & {
								ImageFrame: Frame & {
									Frame: Frame & {
										UIListLayout: UIListLayout,
										TextLabel: TextLabel & {
											UITextSizeConstraint: UITextSizeConstraint,
										},
										ItemImage: ImageLabel & {
											UICorner: UICorner,
										},
									},
								},
								UICorner: UICorner,
							},
						},
					},
				},
			},
			Divider: Frame,
			Controls: Frame & {
				Close: TextButton & {
					Close: ImageLabel & {
						UICorner: UICorner,
					},
					UICorner: UICorner,
					UIStroke: UIStroke,
					UISizeConstraint: UISizeConstraint,
					UIListLayout: UIListLayout,
				},
				UICorner: UICorner,
				UIListLayout: UIListLayout,
				UISizeConstraint: UISizeConstraint,
				Reset: TextButton & {
					Close: ImageLabel & {
						UICorner: UICorner,
					},
					UICorner: UICorner,
					UIStroke: UIStroke,
					UISizeConstraint: UISizeConstraint,
					UIListLayout: UIListLayout,
				},
			},
			Outfit: Frame & {
				Wearing: Frame & {
					UIListLayout: UIListLayout,
					ListWrapper: Frame & {
						UIPadding: UIPadding,
						List: ScrollingFrame & {
							ItemWrapper: ImageButton & {
								Owned: TextButton & {
									UICorner: UICorner,
									UISizeConstraint: UISizeConstraint,
									TextLabel: TextLabel,
									UIListLayout: UIListLayout,
								},
								IsLimited: TextButton & {
									UIListLayout: UIListLayout,
									UICorner: UICorner,
									ImageLabel: ImageLabel,
								},
								ImageFrame: Frame & {
									Frame: Frame & {
										UIListLayout: UIListLayout,
										ItemImage: ImageLabel & {
											UICorner: UICorner,
										},
									},
								},
								UIStroke: UIStroke,
								UICorner: UICorner,
								Buy: TextButton & {
									TextLabel: TextLabel,
									UICorner: UICorner,
									UIListLayout: UIListLayout,
									UISizeConstraint: UISizeConstraint,
									ImageLabel: ImageLabel,
								},
							},
							UIGridLayout: UIGridLayout,
						},
					},
				},
				UIListLayout: UIListLayout,
				UIPadding: UIPadding,
				Divider: Frame,
				Previews: Frame & {
					Items: ImageButton & {
						UICorner: UICorner,
						UIStroke: UIStroke,
						ImageFrame: Frame & {
							IsLimited: Frame & {
								UIAspectRatioConstraint: UIAspectRatioConstraint,
								LimitedUGC: ImageButton,
							},
							Frame: Frame & {
								UIListLayout: UIListLayout,
								ItemImage: ImageLabel & {
									UICorner: UICorner,
								},
							},
						},
						Label: TextButton & {
							UICorner: UICorner,
							UISizeConstraint: UISizeConstraint,
							TextLabel: TextLabel,
							UIListLayout: UIListLayout,
						},
					},
					UIGridLayout: UIGridLayout,
					ItemsBody: ImageButton & {
						UICorner: UICorner,
						UIStroke: UIStroke,
						ImageFrame: Frame & {
							IsLimited: Frame & {
								UIAspectRatioConstraint: UIAspectRatioConstraint,
								LimitedUGC: ImageButton,
							},
							Frame: Frame & {
								UIListLayout: UIListLayout,
								ItemImage: ImageLabel & {
									UICorner: UICorner,
								},
							},
						},
						Label: TextButton & {
							UICorner: UICorner,
							UISizeConstraint: UISizeConstraint,
							TextLabel: TextLabel,
							UIListLayout: UIListLayout,
						},
					},
					Current: ImageButton & {
						UICorner: UICorner,
						UIStroke: UIStroke,
						ImageFrame: Frame & {
							IsLimited: Frame & {
								UIAspectRatioConstraint: UIAspectRatioConstraint,
								LimitedUGC: ImageButton,
							},
							Frame: Frame & {
								UIListLayout: UIListLayout,
								ItemImage: ImageLabel & {
									UICorner: UICorner,
								},
							},
						},
						Label: TextButton & {
							UICorner: UICorner,
							UISizeConstraint: UISizeConstraint,
							TextLabel: TextLabel,
							UIListLayout: UIListLayout,
						},
					},
				},
			},
			Switcher: Frame & {
				Inventory: TextButton & {
					UICorner: UICorner,
					UIListLayout: UIListLayout,
					SelectedIcon: ImageLabel & {
						UICorner: UICorner,
					},
					DeselectedIcon: ImageLabel & {
						UICorner: UICorner,
					},
				},
				Marketplace: TextButton & {
					UICorner: UICorner,
					UIListLayout: UIListLayout,
					SelectedIcon: ImageLabel & {
						UICorner: UICorner,
					},
					DeselectedIcon: ImageLabel & {
						UICorner: UICorner,
					},
				},
				UIPadding: UIPadding,
				UICorner: UICorner,
				UIStroke: UIStroke,
				UISizeConstraint: UISizeConstraint,
				UIListLayout: UIListLayout,
			},
		},
	},
}

export type Confirm = ScreenGui & {
	Confirm: Frame & {
		Input: Frame & {
			UICorner: UICorner,
			TextInput: TextBox & {
				UIListLayout: UIListLayout,
				UIStroke: UIStroke,
				UIPadding: UIPadding,
				UICorner: UICorner,
			},
			UIListLayout: UIListLayout,
		},
		Title: TextLabel,
		UIPadding: UIPadding,
		UICorner: UICorner,
		UIListLayout: UIListLayout,
		Actions: Frame & {
			UIListLayout: UIListLayout,
			SecondaryButton: TextButton & {
				UIListLayout: UIListLayout,
				TextLabel: TextLabel,
				UICorner: UICorner,
			},
			PrimaryButton: TextButton & {
				UIListLayout: UIListLayout,
				TextLabel: TextLabel,
				UICorner: UICorner,
			},
		},
		UISizeConstraint: UISizeConstraint,
		Body: TextLabel,
	},
}

return {}
