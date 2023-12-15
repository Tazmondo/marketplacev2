export type Nav = ScreenGui & {
	Category: TextButton & {
		UIListLayout: UIListLayout,
		ShopName: TextLabel,
	},
	Nav: Frame & {
		UIListLayout: UIListLayout,
		Me: Frame & {
			UIListLayout: UIListLayout,
			ImageButton: ImageButton & {
				UICorner: UICorner,
			},
		},
		Player: ImageButton & {
			UICorner: UICorner,
			UIListLayout: UIListLayout,
			ImageButton: ImageLabel & {
				UICorner: UICorner,
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
		UISizeConstraint: UISizeConstraint,
		UIPadding: UIPadding,
		UIListLayout: UIListLayout,
		UICorner: UICorner,
		Topbar: Frame & {
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
			Back: Frame & {
				UIListLayout: UIListLayout,
				ImageButton: ImageButton & {
					UICorner: UICorner,
				},
			},
		},
		Content: Frame & {
			ImageFrame: Frame & {
				UIListLayout: UIListLayout,
				UICorner: UICorner,
				UISizeConstraint: UISizeConstraint,
				ItemImage: ImageLabel,
			},
			Owners: Frame & {
				UIListLayout: UIListLayout,
				Frame: Frame & {
					UIListLayout: UIListLayout,
					TextLabel: TextLabel,
				},
				UIPadding: UIPadding,
				Row: Frame & {
					UICorner: UICorner,
					UIListLayout: UIListLayout,
					Right: Frame & {
						UIListLayout: UIListLayout,
						Price: TextLabel,
						Buy: TextButton & {
							UICorner: UICorner,
						},
					},
					Left: Frame & {
						UIListLayout: UIListLayout,
					},
					ImageLabel: ImageLabel & {
						UICorner: UICorner,
						UIStroke: UIStroke,
					},
				},
			},
			Details: Frame & {
				Available: Frame & {
					UIListLayout: UIListLayout,
					TextLabel: TextLabel,
					Amount: TextLabel,
				},
				UICorner: UICorner,
				UIListLayout: UIListLayout,
				UISizeConstraint: UISizeConstraint,
				Names: Frame & {
					UIListLayout: UIListLayout,
					ItemName: TextLabel,
					Creator: TextLabel,
				},
			},
			UIListLayout: UIListLayout,
			Actions: Frame & {
				["Try On"]: TextButton & {
					UICorner: UICorner,
				},
				UIPadding: UIPadding,
				UIListLayout: UIListLayout,
				UISizeConstraint: UISizeConstraint,
				Buy: TextButton & {
					UICorner: UICorner,
				},
			},
			Price: Frame & {
				Floor: Frame & {
					UIListLayout: UIListLayout,
					Frame: Frame & {
						UIListLayout: UIListLayout,
						ImageLabel: ImageLabel,
						Amount: TextLabel,
					},
					TextLabel: TextLabel,
				},
				UICorner: UICorner,
				UIListLayout: UIListLayout,
				UISizeConstraint: UISizeConstraint,
				Listed: Frame & {
					UIListLayout: UIListLayout,
					Frame: Frame & {
						UIListLayout: UIListLayout,
						ImageLabel: ImageLabel,
						Amount: TextLabel,
					},
					TextLabel: TextLabel,
				},
			},
		},
		UIGradient: UIGradient,
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
	ControllerEdit: Frame & {
		UICorner: UICorner,
		ColorPicker: Frame & {
			Gold: ImageButton & {
				UICorner: UICorner,
			},
			Purple: ImageButton & {
				UICorner: UICorner,
			},
			UIPadding: UIPadding,
			Green: ImageButton & {
				UICorner: UICorner,
			},
			UICorner: UICorner,
			Blue: ImageButton & {
				UICorner: UICorner,
			},
			UIListLayout: UIListLayout,
			Red: ImageButton & {
				UICorner: UICorner,
			},
		},
		Wrapper: Frame & {
			Exit: TextButton & {
				UIListLayout: UIListLayout,
				UIPadding: UIPadding,
				TextLabel: TextLabel,
				UICorner: UICorner,
			},
			UIPadding: UIPadding,
			UIListLayout: UIListLayout,
			CurrentColor: ImageButton & {
				UICorner: UICorner,
				Frame: Frame & {
					UICorner: UICorner,
					UIStroke: UIStroke,
				},
				UIPadding: UIPadding,
			},
			TextBox: TextBox & {
				UICorner: UICorner,
				UIPadding: UIPadding,
			},
		},
	},
	CreateShop: Frame & {
		UICorner: UICorner,
		Frame: Frame & {
			TextLabel: TextLabel,
			UIPadding: UIPadding,
			UIListLayout: UIListLayout,
			Content: Frame & {
				UIPadding: UIPadding,
				UIListLayout: UIListLayout,
			},
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
			ImageButton: ImageLabel,
		},
		UIPadding: UIPadding,
	},
	AddItemID: Frame & {
		UIPadding: UIPadding,
		UICorner: UICorner,
		Frame: Frame & {
			TextLabel: TextLabel,
			TextBox: TextBox & {
				UICorner: UICorner,
			},
			UIListLayout: UIListLayout,
			UIPadding: UIPadding,
			Actions: Frame & {
				UIListLayout: UIListLayout,
				UISizeConstraint: UISizeConstraint,
				Add: TextButton & {
					UICorner: UICorner,
					TextLabel: TextLabel,
					UIListLayout: UIListLayout,
				},
			},
			ImageButton: ImageLabel & {
				UICorner: UICorner,
			},
		},
		UISizeConstraint: UISizeConstraint,
		Title: Frame & {
			UIListLayout: UIListLayout,
			Close: Frame & {
				UIListLayout: UIListLayout,
				ImageButton: ImageButton & {
					UICorner: UICorner,
				},
			},
		},
	},
	ControllerNav: Frame & {
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
		UIListLayout: UIListLayout,
		Back: ImageButton & {
			UICorner: UICorner,
			UIPadding: UIPadding,
		},
	},
}

return {}
