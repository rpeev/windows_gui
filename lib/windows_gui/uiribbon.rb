if __FILE__ == $0
	require_relative 'common'
	require_relative 'libc'
	require_relative 'kernel'
	require_relative 'gdi'
	require_relative 'user'
end

require 'windows_com'

module WindowsGUI
	module UIRibbon
		include WindowsCOM

		def LoadUIDll(name = File.basename($0, '.rbw'))
			path = File.dirname(File.expand_path($0))
			dll_path = "#{path}/#{name}.dll"

			# pull in generated UIRibbon constants
			require "#{path}/#{name}"

			# load UIRibbon dll
			hdll = DetonateLastError(FFI::Pointer::NULL, :LoadLibrary,
				L(dll_path.dup)
			)

			STDERR.puts "#{dll_path} loaded (hdll: #{hdll})" if $DEBUG

			at_exit {
				FreeLibrary(hdll)

				STDERR.puts "#{dll_path} unloaded" if $DEBUG
			}

			hdll
		end

		module_function \
			:LoadUIDll

		UI_PKEY_Enabled = PROPERTYKEY[VT_BOOL, 1]
		UI_PKEY_LabelDescription = PROPERTYKEY[VT_LPWSTR, 2]
		UI_PKEY_Keytip = PROPERTYKEY[VT_LPWSTR, 3]
		UI_PKEY_Label = PROPERTYKEY[VT_LPWSTR, 4]
		UI_PKEY_TooltipDescription = PROPERTYKEY[VT_LPWSTR, 5]
		UI_PKEY_TooltipTitle = PROPERTYKEY[VT_LPWSTR, 6]
		UI_PKEY_LargeImage = PROPERTYKEY[VT_UNKNOWN, 7]
		UI_PKEY_LargeHighContrastImage = PROPERTYKEY[VT_UNKNOWN, 8]
		UI_PKEY_SmallImage = PROPERTYKEY[VT_UNKNOWN, 9]
		UI_PKEY_SmallHighContrastImage = PROPERTYKEY[VT_UNKNOWN, 10]

		UI_PKEY_CommandId = PROPERTYKEY[VT_UI4, 100]
		UI_PKEY_ItemsSource = PROPERTYKEY[VT_UNKNOWN, 101]
		UI_PKEY_Categories = PROPERTYKEY[VT_UNKNOWN, 102]
		UI_PKEY_CategoryId = PROPERTYKEY[VT_UI4, 103]
		UI_PKEY_SelectedItem = PROPERTYKEY[VT_UI4, 104]
		UI_PKEY_CommandType = PROPERTYKEY[VT_UI4, 105]
		UI_PKEY_ItemImage = PROPERTYKEY[VT_UNKNOWN, 106]

		UI_PKEY_BooleanValue = PROPERTYKEY[VT_BOOL, 200]
		UI_PKEY_DecimalValue = PROPERTYKEY[VT_DECIMAL, 201]
		UI_PKEY_StringValue = PROPERTYKEY[VT_LPWSTR, 202]
		UI_PKEY_MaxValue = PROPERTYKEY[VT_DECIMAL, 203]
		UI_PKEY_MinValue = PROPERTYKEY[VT_DECIMAL, 204]
		UI_PKEY_Increment = PROPERTYKEY[VT_DECIMAL, 205]
		UI_PKEY_DecimalPlaces = PROPERTYKEY[VT_UI4, 206]
		UI_PKEY_FormatString = PROPERTYKEY[VT_LPWSTR, 207]
		UI_PKEY_RepresentativeString = PROPERTYKEY[VT_LPWSTR, 208]

		UI_PKEY_FontProperties = PROPERTYKEY[VT_UNKNOWN, 300]
		UI_PKEY_FontProperties_Family = PROPERTYKEY[VT_LPWSTR, 301]
		UI_PKEY_FontProperties_Size = PROPERTYKEY[VT_DECIMAL, 302]
		UI_PKEY_FontProperties_Bold = PROPERTYKEY[VT_UI4, 303]
		UI_PKEY_FontProperties_Italic = PROPERTYKEY[VT_UI4, 304]
		UI_PKEY_FontProperties_Underline = PROPERTYKEY[VT_UI4, 305]
		UI_PKEY_FontProperties_Strikethrough = PROPERTYKEY[VT_UI4, 306]
		UI_PKEY_FontProperties_VerticalPositioning = PROPERTYKEY[VT_UI4, 307]
		UI_PKEY_FontProperties_ForegroundColor = PROPERTYKEY[VT_UI4, 308]
		UI_PKEY_FontProperties_BackgroundColor = PROPERTYKEY[VT_UI4, 309]
		UI_PKEY_FontProperties_ForegroundColorType = PROPERTYKEY[VT_UI4, 310]
		UI_PKEY_FontProperties_BackgroundColorType = PROPERTYKEY[VT_UI4, 311]
		UI_PKEY_FontProperties_ChangedProperties = PROPERTYKEY[VT_UNKNOWN, 312]
		UI_PKEY_FontProperties_DeltaSize = PROPERTYKEY[VT_UI4, 313]

		UI_PKEY_RecentItems = PROPERTYKEY[VT_ARRAY | VT_UNKNOWN, 350]
		UI_PKEY_Pinned = PROPERTYKEY[VT_BOOL, 351]

		UI_PKEY_Color = PROPERTYKEY[VT_UI4, 400]
		UI_PKEY_ColorType = PROPERTYKEY[VT_UI4, 401]
		UI_PKEY_ColorMode = PROPERTYKEY[VT_UI4, 402]
		UI_PKEY_ThemeColorsCategoryLabel = PROPERTYKEY[VT_LPWSTR, 403]
		UI_PKEY_StandardColorsCategoryLabel = PROPERTYKEY[VT_LPWSTR, 404]
		UI_PKEY_RecentColorsCategoryLabel = PROPERTYKEY[VT_LPWSTR, 405]
		UI_PKEY_AutomaticColorLabel = PROPERTYKEY[VT_LPWSTR, 406]
		UI_PKEY_NoColorLabel = PROPERTYKEY[VT_LPWSTR, 407]
		UI_PKEY_MoreColorsLabel = PROPERTYKEY[VT_LPWSTR, 408]
		UI_PKEY_ThemeColors = PROPERTYKEY[VT_VECTOR | VT_UI4, 409]
		UI_PKEY_StandardColors = PROPERTYKEY[VT_VECTOR | VT_UI4, 410]
		UI_PKEY_ThemeColorsTooltips = PROPERTYKEY[VT_VECTOR | VT_LPWSTR, 411]
		UI_PKEY_StandardColorsTooltips = PROPERTYKEY[VT_VECTOR | VT_LPWSTR, 412]

		UI_PKEY_Viewable = PROPERTYKEY[VT_BOOL, 1000]
		UI_PKEY_Minimized = PROPERTYKEY[VT_BOOL, 1001]
		UI_PKEY_QuickAccessToolbarDock = PROPERTYKEY[VT_UI4, 1002]

		UI_PKEY_ContextAvailable = PROPERTYKEY[VT_UI4, 1100]

		UI_PKEY_GlobalBackgroundColor = PROPERTYKEY[VT_UI4, 2000]
		UI_PKEY_GlobalHighlightColor = PROPERTYKEY[VT_UI4, 2001]
		UI_PKEY_GlobalTextColor = PROPERTYKEY[VT_UI4, 2002]

		def UI_GetHValue(hsb)
			LOBYTE(hsb)
		end

		def UI_GetSValue(hsb)
			LOBYTE(hsb >> 8)
		end

		def UI_GetBValue(hsb)
			LOBYTE(hsb >> 16)
		end

		def UI_HSB(h, s, b)
			h | (s << 8) | (b << 16)
		end

		def UI_RGB2HSB(r, g, b)
			r, g, b = r.to_f / 255, g.to_f / 255, b.to_f / 255
			max, min = [r, g, b].max, [r, g, b].min
			l = (max + min) / 2

			s = if max == min
				0
			elsif l < 0.5
				(max - min) / (max + min)
			else
				(max - min) / (2 - (max + min))
			end

			h = if max == min
				0
			elsif r == max
				(g - b) / (max - min)
			elsif g == max
				2 + (b - r) / (max - min)
			else
				4 + (r - g) / (max - min)
			end * 60

			h += 360 if h < 0
			h = h / 360

			[
				(255 * h).round, # hue
				(255 * s).round, # saturation
				(l < 0.1793) ? # brightness
					0 :
					(l > 0.9821) ?
						255 :
						(257.7 + 149.9 * Math.log(l)).round
			]
		end

		module_function \
			:UI_GetHValue,
			:UI_GetSValue,
			:UI_GetBValue,
			:UI_HSB,
			:UI_RGB2HSB

		UI_CONTEXTAVAILABILITY_NOTAVAILABLE = 0
		UI_CONTEXTAVAILABILITY_AVAILABLE = 1
		UI_CONTEXTAVAILABILITY_ACTIVE = 2

		UI_FONTPROPERTIES_NOTAVAILABLE = 0
		UI_FONTPROPERTIES_NOTSET = 1
		UI_FONTPROPERTIES_SET = 2

		UI_FONTVERTICALPOSITION_NOTAVAILABLE = 0
		UI_FONTVERTICALPOSITION_NOTSET = 1
		UI_FONTVERTICALPOSITION_SUPERSCRIPT = 2
		UI_FONTVERTICALPOSITION_SUBSCRIPT = 3

		UI_FONTUNDERLINE_NOTAVAILABLE = 0
		UI_FONTUNDERLINE_NOTSET = 1
		UI_FONTUNDERLINE_SET = 2

		UI_FONTDELTASIZE_GROW = 0
		UI_FONTDELTASIZE_SHRINK = 1

		UI_CONTROLDOCK_TOP = 1
		UI_CONTROLDOCK_BOTTOM = 3

		UI_SWATCHCOLORTYPE_NOCOLOR = 0
		UI_SWATCHCOLORTYPE_AUTOMATIC = 1
		UI_SWATCHCOLORTYPE_RGB = 2

		UI_SWATCHCOLORMODE_NORMAL = 0
		UI_SWATCHCOLORMODE_MONOCHROME = 1

		IUISimplePropertySet = COMInterface[IUnknown,
			'c205bb48-5b1c-4219-a106-15bd0a5f24e2',

			GetValue: [[:pointer, :pointer], :long]
		]

		IUISimplePropertySetImpl = COMCallback[IUISimplePropertySet]

		IUIRibbon = COMInterface[IUnknown,
			'803982ab-370a-4f7e-a9e7-8784036a6e26',

			GetHeight: [[:pointer], :long],
			LoadSettingsFromStream: [[:pointer], :long],
			SaveSettingsToStream: [[:pointer], :long]
		]

		UI_INVALIDATIONS_STATE = 0x00000001
		UI_INVALIDATIONS_VALUE = 0x00000002
		UI_INVALIDATIONS_PROPERTY = 0x00000004
		UI_INVALIDATIONS_ALLPROPERTIES = 0x00000008

		UI_ALL_COMMANDS = 0

		IUIFramework = COMInterface[IUnknown,
			'F4F0385D-6872-43a8-AD09-4C339CB3F5C5',

			Initialize: [[:pointer, :pointer], :long],
			Destroy: [[], :long],
			LoadUI: [[:pointer, :buffer_in], :long],
			GetView: [[:uint, :pointer, :pointer], :long],
			GetUICommandProperty: [[:uint, :pointer, :pointer], :long],
			SetUICommandProperty: [[:uint, :pointer, :pointer], :long],
			InvalidateUICommand: [[:uint, :int, :pointer], :long],
			FlushPendingInvalidations: [[], :long],
			SetModes: [[:int], :long]
		]

		UIFramework = COMFactory[IUIFramework, '926749fa-2615-4987-8845-c33e65f2b957']

		IUIContextualUI = COMInterface[IUnknown,
			'EEA11F37-7C46-437c-8E55-B52122B29293',

			ShowAtLocation: [[:int, :int], :long]
		]

		IUICollection = COMInterface[IUnknown,
			'DF4F45BF-6F9D-4dd7-9D68-D8F9CD18C4DB',

			GetCount: [[:pointer], :long],
			GetItem: [[:uint, :pointer], :long],
			Add: [[:pointer], :long],
			Insert: [[:uint, :pointer], :long],
			RemoveAt: [[:uint], :long],
			Replace: [[:uint, :pointer], :long],
			Clear: [[], :long]
		]

		UI_COLLECTIONCHANGE_INSERT = 0
		UI_COLLECTIONCHANGE_REMOVE = 1
		UI_COLLECTIONCHANGE_REPLACE = 2
		UI_COLLECTIONCHANGE_RESET = 3

		UI_COLLECTION_INVALIDINDEX = 0xffffffff

		IUICollectionChangedEvent = COMInterface[IUnknown,
			'6502AE91-A14D-44b5-BBD0-62AACC581D52',

			OnChanged: [[:int, :uint, :pointer, :uint, :pointer], :long]
		]

		IUICollectionChangedEventImpl = COMCallback[IUICollectionChangedEvent]

		UI_EXECUTIONVERB_EXECUTE = 0
		UI_EXECUTIONVERB_PREVIEW = 1
		UI_EXECUTIONVERB_CANCELPREVIEW = 2

		IUICommandHandler = COMInterface[IUnknown,
			'75ae0a2d-dc03-4c9f-8883-069660d0beb6',

			Execute: [[:uint, :int, :pointer, :pointer, :pointer], :long],
			UpdateProperty: [[:uint, :pointer, :pointer, :pointer], :long]
		]

		IUICommandHandlerImpl = COMCallback[IUICommandHandler]

		UI_COMMANDTYPE_UNKNOWN = 0
		UI_COMMANDTYPE_GROUP = 1
		UI_COMMANDTYPE_ACTION = 2
		UI_COMMANDTYPE_ANCHOR = 3
		UI_COMMANDTYPE_CONTEXT = 4
		UI_COMMANDTYPE_COLLECTION = 5
		UI_COMMANDTYPE_COMMANDCOLLECTION = 6
		UI_COMMANDTYPE_DECIMAL = 7
		UI_COMMANDTYPE_BOOLEAN = 8
		UI_COMMANDTYPE_FONT = 9
		UI_COMMANDTYPE_RECENTITEMS = 10
		UI_COMMANDTYPE_COLORANCHOR = 11
		UI_COMMANDTYPE_COLORCOLLECTION = 12

		UI_VIEWTYPE_RIBBON = 1

		UI_VIEWVERB_CREATE = 0
		UI_VIEWVERB_DESTROY = 1
		UI_VIEWVERB_SIZE = 2
		UI_VIEWVERB_ERROR = 3

		IUIApplication = COMInterface[IUnknown,
			'D428903C-729A-491d-910D-682A08FF2522',

			OnViewChanged: [[:uint, :int, :pointer, :int, :int], :long],
			OnCreateUICommand: [[:uint, :int, :pointer], :long],
			OnDestroyUICommand: [[:uint, :int, :pointer], :long]
		]

		IUIApplicationImpl = COMCallback[IUIApplication]

		IUIImage = COMInterface[IUnknown,
			'23c8c838-4de6-436b-ab01-5554bb7c30dd',

			GetBitmap: [[:pointer], :long]
		]

		UI_OWNERSHIP_TRANSFER = 0
		UI_OWNERSHIP_COPY = 1

		IUIImageFromBitmap = COMInterface[IUnknown,
			'18aba7f3-4c1c-4ba2-bf6c-f5c3326fa816',

			CreateImage: [[:pointer, :int, :pointer], :long]
		]

		UIImageFromBitmap = COMFactory[IUIImageFromBitmap, '0f7434b6-59b6-4250-999e-d168d6ae4293']

		def UI_MAKEAPPMODE(x)
			1 << x
		end

		module_function \
			:UI_MAKEAPPMODE
	end
end