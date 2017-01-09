require 'ffi-wingui-core'

include WinGUI

TARGETVER(WINVISTA,
	L("This example requires Windows Vista or later\n\nRun anyway?")
)

WndExtra = Struct.new(
	:hbmp
)

def onCreate(hwnd,
	cs
)
	xtra = Util::Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	xtra[:hbmp] = DetonateLastError(FFI::Pointer::NULL, :LoadImage,
		nil,
		L("#{File.dirname(File.expand_path(__FILE__))}/res/face-devilish.bmp"),
		IMAGE_BITMAP, 0, 0,
		LR_LOADFROMFILE | LR_CREATEDIBSECTION
	)

	info = MENUITEMINFO.new

	info[:cbSize] = info.size
	info[:fMask] = MIIM_BITMAP
	info[:hbmpItem] = xtra[:hbmp]

	hbar = CreateMenu()
		hmenu1 = CreatePopupMenu()
			AppendMenu(hmenu1, MF_STRING, ID[:ITEM1], L('Item&1'))
			SetMenuDefaultItem(hmenu1, ID[:ITEM1], 0)
			SetMenuItemInfo(hmenu1, ID[:ITEM1], 0, info)

			AppendMenu(hmenu1, MF_STRING | MF_GRAYED, ID[:ITEM2], L('Item&2'))
			SetMenuItemInfo(hmenu1, ID[:ITEM2], 0, info)

			AppendMenu(hmenu1, MF_STRING | MF_CHECKED, ID[:ITEM3], L('Item&3'))
			SetMenuItemInfo(hmenu1, ID[:ITEM3], 0, info)

			AppendMenu(hmenu1, MF_SEPARATOR, 0, nil)

			AppendMenu(hmenu1, MF_STRING | MF_CHECKED | MFT_RADIOCHECK,
				ID[:ITEM4], L('Item&4'))
			SetMenuItemInfo(hmenu1, ID[:ITEM4], 0, info)

			AppendMenu(hmenu1, MF_STRING, ID[:ITEM5], L('Item&5'))
			SetMenuItemInfo(hmenu1, ID[:ITEM5], 0, info)

			AppendMenu(hmenu1, MF_SEPARATOR, 0, nil)

			hmenu2 = CreatePopupMenu()
				AppendMenu(hmenu2, MF_STRING | MF_CHECKED | MFT_RADIOCHECK,
					ID[:ITEM6], L('Item&6'))
				SetMenuItemInfo(hmenu2, ID[:ITEM6], 0, info)

				AppendMenu(hmenu2, MF_STRING, ID[:ITEM7], L('Item&7'))
				SetMenuItemInfo(hmenu2, ID[:ITEM7], 0, info)
			AppendMenu(hmenu1, MF_POPUP, hmenu2.to_i, L('Menu&2'))
			SetMenuItemInfo(hmenu1, 7, MF_BYPOSITION, info)
		AppendMenu(hbar, MF_POPUP, hmenu1.to_i, L('Menu&1'))
		SetMenuItemInfo(hbar, 0, MF_BYPOSITION, info)

		AppendMenu(hbar, MF_STRING, ID[:ITEM8], L('Item&8!'))
		SetMenuItemInfo(hbar, ID[:ITEM8], 0, info)

		hmenu3 = CreatePopupMenu()
			AppendMenu(hmenu3, MF_BITMAP, ID[:ITEM9], xtra[:hbmp])
		AppendMenu(hbar, MF_POPUP | MF_BITMAP | MF_RIGHTJUSTIFY, hmenu3.to_i, xtra[:hbmp])
	SetMenu(hwnd, hbar)

	0
ensure
	info.pointer.free if info
end

def onDestroy(hwnd)
	xtra = Util::Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	DeleteObject(xtra[:hbmp])

	PostQuitMessage(0); 0
end

def onItem1(verb,
	hctl, hwnd
)
	hbar = GetMenu(hwnd)
	i2grayed = (GetMenuState(hbar, ID[:ITEM2], 0) & MF_GRAYED) == MF_GRAYED

	EnableMenuItem(hbar, ID[:ITEM2], (i2grayed) ? MF_ENABLED : MF_GRAYED)

	0
end

def onItem2(verb,
	hctl, hwnd
)
	MessageBox(hwnd,
		L(__method__.to_s),
		APPNAME,
		MB_ICONINFORMATION
	)

	0
end

def onItem3(verb,
	hctl, hwnd
)
	hbar = GetMenu(hwnd)
	i3checked = (GetMenuState(hbar, ID[:ITEM3], 0) & MF_CHECKED) == MF_CHECKED

	CheckMenuItem(hbar, ID[:ITEM3], (i3checked) ? MF_UNCHECKED : MF_CHECKED)

	0
end

def onItem4(verb,
	hctl, hwnd
)
	CheckMenuRadioItem(GetMenu(hwnd), ID[:ITEM4], ID[:ITEM5], ID[:ITEM4], 0)

	0
end

def onItem5(verb,
	hctl, hwnd
)
	CheckMenuRadioItem(GetMenu(hwnd), ID[:ITEM4], ID[:ITEM5], ID[:ITEM5], 0)

	0
end

def onItem6(verb,
	hctl, hwnd
)
	CheckMenuRadioItem(GetMenu(hwnd), ID[:ITEM6], ID[:ITEM7], ID[:ITEM6], 0)

	0
end

def onItem7(verb,
	hctl, hwnd
)
	CheckMenuRadioItem(GetMenu(hwnd), ID[:ITEM6], ID[:ITEM7], ID[:ITEM7], 0)

	0
end

def onItem8(verb,
	hctl, hwnd
)
	MessageBox(hwnd,
		L(__method__.to_s),
		APPNAME,
		MB_ICONINFORMATION
	)

	0
end

def onItem9(verb,
	hctl, hwnd
)
	hbar = GetMenu(hwnd)
	i2grayed = (GetMenuState(hbar, ID[:ITEM2], 0) & MF_GRAYED) == MF_GRAYED
	i3checked = (GetMenuState(hbar, ID[:ITEM3], 0) & MF_CHECKED) == MF_CHECKED
	i4checked = (GetMenuState(hbar, ID[:ITEM4], 0) & MF_CHECKED) == MF_CHECKED
	i5checked = (GetMenuState(hbar, ID[:ITEM5], 0) & MF_CHECKED) == MF_CHECKED
	i6checked = (GetMenuState(hbar, ID[:ITEM6], 0) & MF_CHECKED) == MF_CHECKED
	i7checked = (GetMenuState(hbar, ID[:ITEM7], 0) & MF_CHECKED) == MF_CHECKED

	MessageBox(hwnd,
		L("
Item2 - #{(i2grayed) ? 'grayed' : 'enabled'}
Item3 - #{(i3checked) ? 'checked' : 'unchecked'}
Item4 - #{(i4checked) ? 'checked' : 'unchecked'}
Item5 - #{(i5checked) ? 'checked' : 'unchecked'}
Item6 - #{(i6checked) ? 'checked' : 'unchecked'}
Item7 - #{(i7checked) ? 'checked' : 'unchecked'}
		"),
		APPNAME,
		MB_ICONINFORMATION
	)

	0
end

WindowProc = FFI::Function.new(:long,
	[:pointer, :uint, :uint, :long],
	convention: :stdcall
) { |hwnd, uMsg, wParam, lParam|
begin
	result = case uMsg
	when WM_NCCREATE
		DefWindowProc(hwnd, uMsg, wParam, lParam)

		SetWindowLong(hwnd,
			GWL_USERDATA,
			CREATESTRUCT.new(FFI::Pointer.new(lParam))[:lpCreateParams].to_i
		)

		1
	when WM_CREATE
		onCreate(hwnd, CREATESTRUCT.new(FFI::Pointer.new(lParam)))
	when WM_DESTROY
		onDestroy(hwnd)

	when WM_COMMAND
		id, verb = LOWORD(wParam), HIWORD(wParam)
		hctl = FFI::Pointer.new(lParam)

		case id
		when ID[:ITEM1]
			onItem1(verb, hctl, hwnd)
		when ID[:ITEM2]
			onItem2(verb, hctl, hwnd)
		when ID[:ITEM3]
			onItem3(verb, hctl, hwnd)
		when ID[:ITEM4]
			onItem4(verb, hctl, hwnd)
		when ID[:ITEM5]
			onItem5(verb, hctl, hwnd)
		when ID[:ITEM6]
			onItem6(verb, hctl, hwnd)
		when ID[:ITEM7]
			onItem7(verb, hctl, hwnd)
		when ID[:ITEM8]
			onItem8(verb, hctl, hwnd)
		when ID[:ITEM9]
			onItem9(verb, hctl, hwnd)
		end
	end

	result || DefWindowProc(hwnd, uMsg, wParam, lParam)
rescue SystemExit => ex
	PostQuitMessage(ex.status)
rescue
	case MessageBox(hwnd,
		L(Util.FormatException($!)),
		APPNAME,
		MB_ABORTRETRYIGNORE | MB_ICONERROR
	)
	when IDABORT
		PostQuitMessage(2)
	when IDRETRY
		retry
	end
end
}

def main
	Util.Id2RefTrack(xtra = WndExtra.new)

	WNDCLASSEX.new { |wc|
		wc[:cbSize] = wc.size
		wc[:lpfnWndProc] = WindowProc
		wc[:cbWndExtra] = FFI::Type::Builtin::POINTER.size
		wc[:hInstance] = GetModuleHandle(nil)
		wc[:hIcon] = LoadIcon(nil, IDI_APPLICATION)
		wc[:hCursor] = LoadCursor(nil, IDC_ARROW)
		wc[:hbrBackground] = FFI::Pointer.new(
			((WINVER == WINXP) ? COLOR_MENUBAR : COLOR_MENU) + 1
		)

		PWSTR(APPNAME) { |className|
			wc[:lpszClassName] = className

			DetonateLastError(0, :RegisterClassEx,
				wc
			)
		}
	}

	hwnd = CreateWindowEx(
		0, APPNAME, APPNAME, WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,
		CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
		nil, nil, GetModuleHandle(nil), FFI::Pointer.new(xtra.object_id)
	)

	raise "CreateWindowEx failed (last error: #{GetLastError()})" if
		hwnd.null? && GetLastError() != 0

	exit(0) if hwnd.null?

	ShowWindow(hwnd, SW_SHOWNORMAL)
	UpdateWindow(hwnd)

	MSG.new { |msg|
		until DetonateLastError(-1, :GetMessage,
			msg, nil, 0, 0
		) == 0
			TranslateMessage(msg)
			DispatchMessage(msg)
		end

		exit(msg[:wParam])
	}
rescue
	MessageBox(hwnd,
		L(Util.FormatException($!)),
		APPNAME,
		MB_ICONERROR
	); exit(1)
end

main
