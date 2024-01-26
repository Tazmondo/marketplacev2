export type Nav = ScreenGui & {
	Nav: Frame & {
		Profile: Frame & {
			ImageButton: ImageButton & {
				UICorner: UICorner,
				UIStroke: UIStroke,
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
				UIStroke: UIStroke,
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
				UIStroke: UIStroke,
			},
		},
	},
	Feed: Frame & {
		Current: ImageButton & {
			UIPadding: UIPadding,
			Expand: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
				UIPadding: UIPadding,
			},
			UICorner: UICorner,
			UIStroke: UIStroke,
			Feed: TextLabel,
			UIListLayout: UIListLayout,
		},
		Search: ImageButton & {
			Creator: TextBox & {
				UICorner: UICorner,
				UIPadding: UIPadding,
			},
			UIListLayout: UIListLayout,
			UIStroke: UIStroke,
			UICorner: UICorner,
			Toggle: TextButton & {
				UICorner: UICorner,
				TextLabel: TextLabel,
				UIListLayout: UIListLayout,
			},
		},
		ActionButton: Frame & {
			UICorner: UICorner,
			UIStroke: UIStroke,
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
			UIPadding: UIPadding,
			UICorner: UICorner,
			UIStroke: UIStroke,
			Random: ImageButton & {
				UIListLayout: UIListLayout,
				UIPadding: UIPadding,
				Feed: TextLabel,
				UICorner: UICorner,
			},
			UIListLayout: UIListLayout,
		},
		UISizeConstraint: UISizeConstraint,
	},
	Discover: Frame & {
		UIListLayout: UIListLayout,
		Frame: Frame & {
			Discover: Frame & {
				Controls: Frame & {
					UIListLayout: UIListLayout,
					UICorner: UICorner,
					UISizeConstraint: UISizeConstraint,
					Close: TextButton & {
						Close: ImageLabel & {
							UICorner: UICorner,
						},
						UICorner: UICorner,
						UIStroke: UIStroke,
						UISizeConstraint: UISizeConstraint,
						UIListLayout: UIListLayout,
					},
				},
				Tabs: Frame & {
					UISizeConstraint: UISizeConstraint,
					UIPadding: UIPadding,
					UICorner: UICorner,
					UIListLayout: UIListLayout,
					UIStroke: UIStroke,
					Discover: TextButton & {
						UIListLayout: UIListLayout,
						TextLabel: TextLabel & {
							UITextSizeConstraint: UITextSizeConstraint,
						},
						UICorner: UICorner,
					},
					Accessories: TextButton & {
						UIListLayout: UIListLayout,
						TextLabel: TextLabel & {
							UITextSizeConstraint: UITextSizeConstraint,
						},
						UICorner: UICorner,
					},
				},
				Results: Frame & {
					UIPadding: UIPadding,
					List: ScrollingFrame & {
						UIListLayout: UIListLayout,
						Collection: Frame & {
							UIListLayout: UIListLayout,
							Title: Frame & {
								UIListLayout: UIListLayout,
								UISizeConstraint: UISizeConstraint,
								TextLabel: TextLabel & {
									UITextSizeConstraint: UITextSizeConstraint,
								},
							},
							ListWrapper: Frame & {
								FadeLeft: Frame & {
									Left: TextButton & {
										Image: ImageLabel & {
											UICorner: UICorner,
										},
										UICorner: UICorner,
										UIStroke: UIStroke,
										UISizeConstraint: UISizeConstraint,
										UIListLayout: UIListLayout,
									},
									UIListLayout: UIListLayout,
								},
								FadeRight: Frame & {
									UIListLayout: UIListLayout,
									Right: TextButton & {
										Image: ImageLabel & {
											UICorner: UICorner,
										},
										UICorner: UICorner,
										UIStroke: UIStroke,
										UISizeConstraint: UISizeConstraint,
										UIListLayout: UIListLayout,
									},
								},
								List: ScrollingFrame & {
									UIListLayout: UIListLayout,
									ShopInfo: ImageButton & {
										UICorner: UICorner,
										Frame: Frame & {
											UIListLayout: UIListLayout,
											Text: Frame & {
												UIListLayout: UIListLayout,
												ShopName: TextLabel,
												CreatorName: TextButton,
											},
											ProfileImage: ImageLabel & {
												UICorner: UICorner,
												UIStroke: UIStroke,
											},
										},
										UIPadding: UIPadding,
									},
								},
							},
						},
					},
				},
			},
		},
	},
}

export type Main = ScreenGui & {
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
	EditField: Frame & {
		Top: Frame & {
			UICorner: UICorner,
			ItemName: TextBox & {
				UIListLayout: UIListLayout,
				UIStroke: UIStroke,
				UIPadding: UIPadding,
				UICorner: UICorner,
			},
			UIListLayout: UIListLayout,
		},
		UIPadding: UIPadding,
		Title: TextLabel,
		UIListLayout: UIListLayout,
		Actions: Frame & {
			UIListLayout: UIListLayout,
		},
		UISizeConstraint: UISizeConstraint,
		UICorner: UICorner,
	},
	ControllerEdit: Frame & {
		StorefrontPicker: Frame & {
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
		UICorner: UICorner,
		Wrapper: Frame & {
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
			Profile: TextButton & {
				UIListLayout: UIListLayout,
				TextLabel: TextLabel,
				UICorner: UICorner,
			},
			CurrentLayout: ImageButton & {
				UICorner: UICorner,
				SelectedOutline: UIStroke,
				UIPadding: UIPadding,
			},
			Storefront: ImageButton & {
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
	Avatar: Frame & {
		UICorner: UICorner,
		Content: Frame & {
			Wearing: ScrollingFrame & {
				UIListLayout: UIListLayout,
				UIPadding: UIPadding,
				Row: Frame & {
					ImageFrame: Frame & {
						UICorner: UICorner,
						Frame: Frame & {
							IsLimited: Frame & {
								UIAspectRatioConstraint: UIAspectRatioConstraint,
								LimitedUGC: ImageButton,
							},
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
					UICorner: UICorner,
					UIListLayout: UIListLayout,
					UISizeConstraint: UISizeConstraint,
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
				UISizeConstraint: UISizeConstraint,
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
				UISizeConstraint: UISizeConstraint,
			},
			Outfits: ScrollingFrame & {
				ItemWrapper: ImageButton & {
					ImageFrame: Frame & {
						UICorner: UICorner,
						Frame: Frame & {
							UIListLayout: UIListLayout,
							Details: Frame & {
								UIListLayout: UIListLayout,
								UIPadding: UIPadding,
								Label: TextLabel,
							},
							ItemImage: ImageLabel & {
								UICorner: UICorner,
							},
						},
					},
					UIStroke: UIStroke,
					UICorner: UICorner,
					UIListLayout: UIListLayout,
				},
				UIGridLayout: UIGridLayout,
				UIPadding: UIPadding,
				New: ImageButton & {
					UIPadding: UIPadding,
					UICorner: UICorner,
					Body: TextLabel,
					UIListLayout: UIListLayout,
					ItemImage: ImageLabel,
				},
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
								Delete: TextButton & {
									UIListLayout: UIListLayout,
									UICorner: UICorner,
									ImageLabel: ImageLabel,
								},
								Title: TextButton & {
									UICorner: UICorner,
									UISizeConstraint: UISizeConstraint,
									TextLabel: TextLabel,
									UIListLayout: UIListLayout,
								},
								ImageFrame: Frame & {
									Frame: Frame & {
										UIListLayout: UIListLayout,
										OutfitImage: ViewportFrame & {
											WorldModel: WorldModel,
										},
									},
								},
								UIStroke: UIStroke,
								UICorner: UICorner,
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
					Partial: ImageButton & {
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
								OutfitImage: ViewportFrame & {
									WorldModel: WorldModel,
								},
							},
						},
					},
					UIGridLayout: UIGridLayout,
					Full: ImageButton & {
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
								OutfitImage: ViewportFrame & {
									WorldModel: WorldModel,
								},
							},
						},
					},
					Current: ImageButton & {
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
								OutfitImage: ViewportFrame & {
									WorldModel: WorldModel,
								},
							},
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
