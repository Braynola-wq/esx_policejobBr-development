Config                            = {}

Config.DrawDistance               = 100.0
Config.MarkerType                 = 1
Config.MarkerSize                 = { x = 1.5, y = 1.5, z = 0.5 }
Config.MarkerColor                = { r = 50, g = 50, b = 204 }

Config.EnablePlayerManagement     = true
Config.EnableArmoryManagement     = true
Config.EnableESXIdentity          = true -- enable if you're using esx_identity
Config.EnableLicenses             = true -- enable if you're using esx_license

Config.EnableHandcuffTimer        = true -- enable handcuff timer? will unrestrain player after the time ends
Config.HandcuffTimer              = 10 * 60000 -- 10 mins

Config.Locale                     = 'en'

Config.CustomMarkers = true -- לבטל/להדליק את רוב הסימונים של הלוגו משטרת ישראל


-- Evidence
Config.IgnoreSilencer = true
Config.AmmoLabels = {
    ['ammo-9'] = '9mm',
    ['ammo-45'] = '.45 ACP',
    ['ammo-rifle'] = '5.56x45',
    ['AMMO_MG'] = '7.92x57mm mauser bullet',
    ['boxshot'] = '12-gauge bullet',
    ['AMMO_SNIPER'] = '7.62x39',
}

Config.MaxTimeInterval = 600000
Config.MaxEvidenceTime = 3600000

Config.UseBlood = true
Config.BloodChance = 60
-- End Evidence

-- Tow Truck Mission --
Config.TowSpot = {
	vector3(420.37, -1023.82, 29.01),
	vector3(-1066.92, -867.16, 4.88),
	vector3(-642.79, -111.64, 37.93),
	vector3(826.56, -1263.88, 26.27),
	vector3(408.93, -1645.43, 29.29),
	vector3(1865.32, 3661.69, 33.84),
	vector3(-469.86, 6021.14, 31.34),
}
Config.TowTrucks = {
	[`poltowtruck`] = true,
}
Config.TowPayments = {
	society = 450,
	personal = 250,
}
-- End Tow Truck Mission

-- Objects
Config.PoliceObjects = {
	{label = _U('cone'), model = 'prop_roadcone02a'},
	{label = _U('barrier'), model = 'prop_barrier_work05'},
	{label = _U('spikestrips'), model = 'p_ld_stinger_s'},
	{label = "פרוזקטור משטרתי", model = 'prop_worklight_03b'},
	{label = _U('box'), model = 'prop_boxpile_07d'},
	{label = _U('cash'), model = 'hei_prop_cash_crate_half_full'},
	{label = "באמפר", model = 'stt_prop_track_slowdown'},
	{label = "גזיבו", model = 'prop_gazebo_03', boss = true},
	{label = "כיסא", model = 'prop_cs_office_chair', boss = true},
}

Config.MaxObjects = 100

Config.SpawnedObjects = {}

-- End Objects

Config.PoliceStations = {

	LSPD = {

		Blip = {
			Coords  = vector3(-596.57, -97.58, 33.68),
			Sprite  = 60,
			Display = 4,
			Scale   = 1.2,
			Colour  = 0
		},

		Cloakrooms = {
			vector3(-564.62, -111.0, 33.68)
		},

		Armories = {
			vector3(-598.98, -96.43, 33.68)
		},

		Archive = {
			vector3(-555.1846, -95.44944, 32.81356)
		},

		Evidence = {
			vector3(-542.09, -122.81, 44.68)
		},

		Kitchen = {
			vector3(-574.03, -140.72, 47.92)
		},

		BossActions = {
			vector3(-602.27, -153.6, 42.86)
		},

		BossBills = {
			vector3(-558.88, -115.97, 44.68)
		},

	},
	LVPD = {

		Blip = {
			Coords  = vector3(1828.07, 3679.37, 34.19),
			Sprite  = 60,
			Display = 4,
			Scale   = 1.2,
			Colour  = 0
		},

		Cloakrooms = {
			vector3(1841.62, 3679.25, 34.19)
		},

		Armories = {
			vector3(1839.94, 3684.53, 34.19)
		},


		Evidence = {
			vector3(1822.36, 3668.15, 34.19)
		},

		Weaponry = {
			vector3(1836.43, 3687.01, 34.19)
		},

		Kitchen = {
			vector3(1829.22, 3682.84, 34.19)
		},

		BossActions = {
			vector3(1825.41, 3671.56, 38.86)
		},


		BossBills = {
			vector3(1825.36, 3674.37, 38.86)
		},

	},
	EILATPD = {
		-- Blip = {
		-- 	Coords  = vector3(-449.09, 6017.76, 31.72),
		-- 	Sprite  = 60,
		-- 	Display = 4,
		-- 	Scale   = 1.2,
		-- 	Colour  = 0
		-- },

		Armories = {
			vector3(-449.89, 6016.22, 31.72)
		},

		Cloakrooms = {
			vector3(-442.17, 6012.12, 31.72)
		},

		Weaponry = {
			vector3(-448.29, 6007.91, 31.72)
		},
		
	},
	MRPD = {
		Armories = {
			vector3(458.28, -979.29, 30.69),
		},

		Weaponry = {
			vector3(452.44, -980.17, 30.69),
		},

		Cloakrooms = {
			vector3(450.41, -992.78, 30.69),
		},

		BossActions = {
			vector3(448.18, -973.3, 30.69)
		},

		BossBills = {
			vector3(452.79, -973.44, 30.69),
		}

	}

}

Config.FingerScanners = {
    [1] = vector3(-547.21, -112.99, 45.23),
}

Config.NPCPositions = {
	{coords = vector3(453.69, -985.382, 30.29), model = "s_f_y_cop_01"},
	{coords = vector3(453.627, -982.126, 30.29), model = "s_m_y_cop_01"},
	{coords = vector3(453.178, -977.414, 30.295), model = "s_f_y_cop_01"},
	{coords = vector3(453.245, -990.098, 30.295), model = "s_m_y_cop_01"},
	{coords = vector3(440.616, -996.595, 34.56), model = "s_m_m_fiboffice_01"}
}

-- CHECK SKINCHANGER CLIENT MAIN.LUA for matching elements

Config.Uniforms = {
	recruit_wear = {
		male = {
			['tshirt_1'] = 1,  ['tshirt_2'] = 0,
			['torso_1'] = 5,   ['torso_2'] = 0,
			['decals_1'] = 8,   ['decals_2'] = 0,
			['arms'] = 0,
			['pants_1'] = 7,   ['pants_2'] = 0,
			['shoes_1'] = 65,   ['shoes_2'] = 0,
			['helmet_1'] = 1,  ['helmet_2'] = 0,
			['chain_1'] = 0,    ['chain_2'] = 0,
			--['bags_1'] = 56,    ['bags_2'] = 0,
			['decals_1'] = 0,    ['decals_2'] = 0,
			['mask_1'] = 0,    ['mask_2'] = 0,
			['ears_1'] = 2,     ['ears_2'] = 0
		},
		female = {
			['tshirt_1'] = 35,  ['tshirt_2'] = 0,
			['torso_1'] = 441,   ['torso_2'] = 0,
			['decals_1'] = 6,   ['decals_2'] = 0,
			['arms'] = 14,
			['pants_1'] = 120,   ['pants_2'] = 0,
			['shoes_1'] = 22,   ['shoes_2'] = 0,
			['helmet_1'] = -1,  ['helmet_2'] = 0,
			['chain_1'] = 0,    ['chain_2'] = 0,
			['ears_1'] = -1,     ['ears_2'] = 0,
			['decals_1'] = 0,    ['decals_2'] = 0,
			['mask_1'] = 0,    ['mask_2'] = 0,
			--['bags_1'] = 33,    ['bags_2'] = 0
		}
	},
	officer_wear = {
		male = {
			['tshirt_1'] = 1,  ['tshirt_2'] = 0,
			['torso_1'] = 6,   ['torso_2'] = 0,
			['decals_1'] = 0,   ['decals_2'] = 0,
			['arms'] = 34,
			['pants_1'] = 83,   ['pants_2'] = 0,
			['shoes_1'] = 65,   ['shoes_2'] = 0,
			['helmet_1'] = 1,  ['helmet_2'] = 0,
			['chain_1'] = 0,    ['chain_2'] = 0,
			--['bags_1'] = 56,    ['bags_2'] = 0,
			['mask_1'] = 0,    ['mask_2'] = 0,
			['ears_1'] = -1,     ['ears_2'] = 0
		},
		female = {
			['tshirt_1'] = 35,  ['tshirt_2'] = 0,
			['torso_1'] = 441,   ['torso_2'] = 0,
			-- ['decals_1'] = 6,   ['decals_2'] = 0,
			['arms'] = 34,
			['pants_1'] = 120,   ['pants_2'] = 0,
			['shoes_1'] = 22,   ['shoes_2'] = 0,
			['helmet_1'] = -1,  ['helmet_2'] = 0,
			['chain_1'] = 0,    ['chain_2'] = 0,
			['ears_1'] = -1,     ['ears_2'] = 0,
			['mask_1'] = 0,    ['mask_2'] = 0,
			--['bags_1'] = 33,    ['bags_2'] = 0
		}
	},
	seniorofficer_wear = {
		male = {
			['tshirt_1'] = 1,  ['tshirt_2'] = 0,
			['torso_1'] = 37,   ['torso_2'] = 1,
			['decals_1'] = 0,   ['decals_2'] = 0,
			['arms'] = 28,
			['pants_1'] = 100,   ['pants_2'] = 1,
			['shoes_1'] = 65,   ['shoes_2'] = 0,
			['helmet_1'] = 1,  ['helmet_2'] = 0,
			['chain_1'] = 0,    ['chain_2'] = 0,
			--['bags_1'] = 56,    ['bags_2'] = 0,
			['mask_1'] = 0,    ['mask_2'] = 0,
			['ears_1'] = 2,     ['ears_2'] = 0
		},
		female = {
			['tshirt_1'] = 35,  ['tshirt_2'] = 8,
			['torso_1'] = 441,   ['torso_2'] = 0,
			-- ['decals_1'] = 6,   ['decals_2'] = 0,
			['arms'] = 34,
			['pants_1'] = 120,   ['pants_2'] = 0,
			['shoes_1'] = 22,   ['shoes_2'] = 0,
			['helmet_1'] = -1,  ['helmet_2'] = 0,
			['chain_1'] = 0,    ['chain_2'] = 0,
			['ears_1'] = -1,     ['ears_2'] = 0,
			['mask_1'] = 0,    ['mask_2'] = 0,
			--['bags_1'] = 33,    ['bags_2'] = 0
		}
	},
	sergeant_wear = {
		male = {
			['tshirt_1'] = 1,  ['tshirt_2'] = 0,
			['torso_1'] = 59,   ['torso_2'] = 0,
			['decals_1'] = 0,   ['decals_2'] = 0,
			['arms'] = 25,
			['glasses_1'] = 5, ['glasses_2'] = 2,
			['pants_1'] = 79,   ['pants_2'] = 2,
			['shoes_1'] = 65,   ['shoes_2'] = 0,
			['helmet_1'] = 68,  ['helmet_2'] = 0,
			['chain_1'] = 0,    ['chain_2'] = 0,
			['bags_1'] = 14,    ['bags_2'] = 0,
			['ears_1'] = -1,     ['ears_2'] = 0
		},
		female = {
			['tshirt_1'] = 3,  ['tshirt_2'] = 0,
			['torso_1'] = 122,   ['torso_2'] = 0,
			['decals_1'] = 0,   ['decals_2'] = 0,
			['arms'] = 42,
			['glasses_1'] = 5, ['glasses_2'] = 2,
			['pants_1'] = 89,   ['pants_2'] = 0,
			['shoes_1'] = 51,   ['shoes_2'] = 0,
			['helmet_1'] = 60,  ['helmet_2'] = 0,
			['chain_1'] = 2,    ['chain_2'] = 0,
			['bags_1'] = 10,    ['bags_2'] = 0,
			['ears_1'] = 0,     ['ears_2'] = 0
		}
	},
	magav_wear = {
		male = {
			['tshirt_1'] = 1,  ['tshirt_2'] = 0,
			['torso_1'] = 36,   ['torso_2'] = 0,
			['decals_1'] = 0,   ['decals_2'] = 0,
			['arms'] = 25,
			['glasses_1'] = 5, ['glasses_2'] = 2,
			['pants_1'] = 79,   ['pants_2'] = 3,
			['shoes_1'] = 65,   ['shoes_2'] = 0,
			['helmet_1'] = 8,  ['helmet_2'] = 0,
			['mask_1'] = 0,    ['mask_2'] = 0,
			['chain_1'] = 0,    ['chain_2'] = 0,
			['bags_1'] = 14,    ['bags_2'] = 0,
			['ears_1'] = -1,     ['ears_2'] = 0
		},
		female = {
			['tshirt_1'] = 35,  ['tshirt_2'] = 0,
			['torso_1'] = 441,   ['torso_2'] = 0,
			['decals_1'] = 6,   ['decals_2'] = 0,
			['arms'] = 14,
			['pants_1'] = 120,   ['pants_2'] = 3,
			['shoes_1'] = 22,   ['shoes_2'] = 0,
			['helmet_1'] = -1,  ['helmet_2'] = 0,
			['mask_1'] = 0,    ['mask_2'] = 0,
			['chain_1'] = 0,    ['chain_2'] = 0,
			['ears_1'] = -1,     ['ears_2'] = 0,
			--['bags_1'] = 33,    ['bags_2'] = 0
		}
	},
	agent_wear = {
		male = {
			['tshirt_1'] = 93,  ['tshirt_2'] = 0,
			['torso_1'] = 9,   ['torso_2'] = 0,
			['decals_1'] = 0,   ['decals_2'] = 0,
			['arms'] = 0,
			['pants_1'] = 100,   ['pants_2'] = 2,
			['shoes_1'] = 65,   ['shoes_2'] = 0,
			['helmet_1'] = 1,  ['helmet_2'] = 0,
			['chain_1'] = 0,    ['chain_2'] = 0,
			['decals_1'] = 0,    ['decals_2'] = 0,
			--['bags_1'] = 56,    ['bags_2'] = 0,
			['ears_1'] = -1,     ['ears_2'] = 0
		},
		female = {
			['tshirt_1'] = 35,  ['tshirt_2'] = 0,
			['torso_1'] = 441,   ['torso_2'] = 0,
			['decals_1'] = 6,   ['decals_2'] = 0,
			['arms'] = 14,
			['pants_1'] = 120,   ['pants_2'] = 3,
			['shoes_1'] = 22,   ['shoes_2'] = 0,
			['helmet_1'] = -1,  ['helmet_2'] = 0,
			['chain_1'] = 0,    ['chain_2'] = 0,
			['ears_1'] = -1,     ['ears_2'] = 0,
			--['bags_1'] = 57,    ['bags_2'] = 0
		}
	},
	intendent_wear = {
		male = {
			['tshirt_1'] = 93,  ['tshirt_2'] = 0,
			['torso_1'] = 3,   ['torso_2'] = 0,
			['decals_1'] = 0,   ['decals_2'] = 0,
			['arms'] = 25,
			['pants_1'] = 107,   ['pants_2'] = 5,
			['decals_1'] = 0,    ['decals_2'] = 0,
			['shoes_1'] = 25,   ['shoes_2'] = 0,
			['helmet_1'] = 69,  ['helmet_2'] = 0,
			['chain_1'] = 0,    ['chain_2'] = 0,
			--['bags_1'] = 32,    ['bags_2'] = 0,
			['ears_1'] = -1,     ['ears_2'] = 0
		},
		female = {
			['tshirt_1'] = 263,  ['tshirt_2'] = 0,
			['torso_1'] = 158,   ['torso_2'] = 1,
			['arms'] = 24,
			--['bags_1'] = 57,    ['bags_2'] = 0,
			['pants_1'] = 120,   ['pants_2'] = 2,
			['shoes_1'] = 88,   ['shoes_2'] = 0,
			['helmet_1'] = -1,  ['helmet_2'] = 0,
			['chain_1'] = 0,    ['chain_2'] = 0,
			['ears_1'] = -1,     ['ears_2'] = 0
		}
	},
	lieutenant_wear = { -- currently the same as intendent_wear
		--[[
		male = {
			['tshirt_1'] = 185,  ['tshirt_2'] = 0,
			['torso_1'] = 161,   ['torso_2'] = 0,
			['arms'] = 25,
			['pants_1'] = 107,   ['pants_2'] = 1,
			['shoes_1'] = 65,   ['shoes_2'] = 0,
			['helmet_1'] = 133,  ['helmet_2'] = 1,
			['chain_1'] = 0,    ['chain_2'] = 0,
			['mask_1'] = 215,    ['mask_2'] = 0,
			['bags_1'] = 32,    ['bags_2'] = 0,
			['ears_1'] = 2,     ['ears_2'] = 0,
			['glasses_1'] = 0,  ['glasses_2'] = 0
		},
		--]]

		male = {
			['tshirt_1'] = 1,  ['tshirt_2'] = 0,
			['torso_1'] = 222,   ['torso_2'] = 0,
			['arms'] = 26,
			['decals_1'] = 0,    ['decals_2'] = 0,
			['pants_1'] = 79,   ['pants_2'] = 2,
			['shoes_1'] = 65,   ['shoes_2'] = 0,
			['helmet_1'] = 133,  ['helmet_2'] = 0,
			['chain_1'] = 159,    ['chain_2'] = 0,
			['mask_1'] = 134,    ['mask_2'] = 25,
			['bags_1'] = 0,    ['bags_2'] = 0,
			['ears_1'] = -1,     ['ears_2'] = 0,
			['glasses_1'] = 15,  ['glasses_2'] = 0
		},
		female = {
			['tshirt_1'] = 10,  ['tshirt_2'] = 0,
			['torso_1'] = 185,   ['torso_2'] = 1,
			['decals_1'] = 0,    ['decals_2'] = 0,
			['arms'] = 18,
			['pants_1'] = 18,   ['pants_2'] = 2,
			['shoes_1'] = 41,   ['shoes_2'] = 0,
			['helmet_1'] = -1,  ['helmet_2'] = 0,
			['chain_1'] = 0,    ['chain_2'] = 0,
			['bags_1'] = 15,    ['bags_2'] = 0,
			['ears_1'] = 2,     ['ears_2'] = 0,
			['mask_1'] = 139,    ['mask_2'] = 6,
			['bproof_1'] = 27,  ['bproof_2'] = 0
		}
	},
	boss_wear = { -- currently the same as chef_wear
		male = {
			['tshirt_1'] = 1,  ['tshirt_2'] = 0,
			['torso_1'] = 15,   ['torso_2'] = 0,
			['decals_1'] = 0,   ['decals_2'] = 0,
			['decals_1'] = 0,    ['decals_2'] = 0,
			['arms'] = 28,
			['pants_1'] = 83,   ['pants_2'] = 0,
			['shoes_1'] = 65,   ['shoes_2'] = 0,
			['helmet_1'] = 1,  ['helmet_2'] = 0,
			['chain_1'] = 0,    ['chain_2'] = 0,
			['bags_1'] = 56,    ['bags_2'] = 0,
			['ears_1'] = 2,     ['ears_2'] = 0
		},
		female = {
			['tshirt_1'] = 35,  ['tshirt_2'] = 0,
			['torso_1'] = 48,   ['torso_2'] = 0,
			['decals_1'] = 7,   ['decals_2'] = 3,
			['arms'] = 44,
			['pants_1'] = 34,   ['pants_2'] = 0,
			['shoes_1'] = 27,   ['shoes_2'] = 0,
			['helmet_1'] = -1,  ['helmet_2'] = 0,
			['chain_1'] = 0,    ['chain_2'] = 0,
			['ears_1'] = 2,     ['ears_2'] = 0
		}
	},
	bullet_wear = {
		male = {
			['bproof_1'] = 12 ,  ['bproof_2'] = 1
		},
		female = {
			['bproof_1'] = 28,  ['bproof_2'] = 0
		}
	},
	gilet_wear = {
		male = {
			['bproof_1'] = 5,  ['bproof_2'] = 0
		},
		female = {
			['bproof_1'] = 5,  ['bproof_2'] = 0
		}
	},
	yamam_wear = {
		male = {
			['bproof_1'] = 13,  ['bproof_2'] = 0
		},
		female = {
			['bproof_1'] = 28,  ['bproof_2'] = 0
		}
	},
	magav_vest = {
		male = {
			['bproof_1'] = 1,  ['bproof_2'] = 0
		},
		female = {
			['bproof_1'] = 16,  ['bproof_2'] = 0
		}
	},
	police_bag = {
		male = {
			['bags_1'] = 14,    ['bags_2'] = 0,
		},
		female = {
			['bags_1'] = 14,    ['bags_2'] = 0
		}
	}

}


Config.Flag = {
	MaxZ = 47.31304550170898,
	MinZ =  40.32,
	Default = vec3(-558.6231079101563,-139.22500610351563,47.31304550170898),
	Target = vec3(-558.535828, -139.022614, 39.031075)
}