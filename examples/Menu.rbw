require 'windows_gui'

include WindowsGUI

WndExtra = Struct.new(
	:dummy
)

def OnCreate(hwnd,
	cs
)
	xtra = Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	hbar = CreateMenu()
		hmenu1 = CreatePopupMenu()
			AppendMenu(hmenu1, MF_STRING, CMD[:ITEM1], L('Item&1'))
			SetMenuDefaultItem(hmenu1, CMD[:ITEM1], 0)

			AppendMenu(hmenu1, MF_STRING | MF_GRAYED, CMD[:ITEM2], L('Item&2'))
			AppendMenu(hmenu1, MF_STRING | MF_CHECKED, CMD[:ITEM3], L('Item&3'))

			AppendMenu(hmenu1, MF_SEPARATOR, 0, nil)

			AppendMenu(hmenu1, MF_STRING | MF_CHECKED | MFT_RADIOCHECK,
				CMD[:ITEM4], L('Item&4'))
			AppendMenu(hmenu1, MF_STRING, CMD[:ITEM5], L('Item&5'))

			AppendMenu(hmenu1, MF_SEPARATOR, 0, nil)

			hmenu2 = CreatePopupMenu()
				AppendMenu(hmenu2, MF_STRING | MF_CHECKED | MFT_RADIOCHECK,
					CMD[:ITEM6], L('Item&6'))
				AppendMenu(hmenu2, MF_STRING, CMD[:ITEM7], L('Item&7'))
			AppendMenu(hmenu1, MF_POPUP, hmenu2.to_i, L('Menu&2'))
		AppendMenu(hbar, MF_POPUP, hmenu1.to_i, L('Menu&1'))

		AppendMenu(hbar, MF_STRING, CMD[:ITEM8], L('Item&8!'))

		hmenu3 = CreatePopupMenu()
			AppendMenu(hmenu3, MF_STRING, CMD[:ITEM9], L('Item&9'))
		AppendMenu(hbar, MF_POPUP | MF_RIGHTJUSTIFY, hmenu3.to_i, L('Menu&3'))
	SetMenu(hwnd, hbar)

	0
end

def OnDestroy(hwnd)
	xtra = Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	PostQuitMessage(0); 0
end

def OnItem1(verb,
	hctl, hwnd
)
	hbar = GetMenu(hwnd)
	i2grayed = (GetMenuState(hbar, CMD[:ITEM2], 0) & MF_GRAYED) == MF_GRAYED

	EnableMenuItem(hbar, CMD[:ITEM2], (i2grayed) ? MF_ENABLED : MF_GRAYED)

	0
end

def OnItem2(verb,
	hctl, hwnd
)
	MessageBox(hwnd,
		L(__method__.to_s),
		APPNAME,
		MB_ICONINFORMATION
	)

	0
end

def OnItem3(verb,
	hctl, hwnd
)
	hbar = GetMenu(hwnd)
	i3checked = (GetMenuState(hbar, CMD[:ITEM3], 0) & MF_CHECKED) == MF_CHECKED

	CheckMenuItem(hbar, CMD[:ITEM3], (i3checked) ? MF_UNCHECKED : MF_CHECKED)

	0
end

def OnItem4(verb,
	hctl, hwnd
)
	CheckMenuRadioItem(GetMenu(hwnd), CMD[:ITEM4], CMD[:ITEM5], CMD[:ITEM4], 0)

	0
end

def OnItem5(verb,
	hctl, hwnd
)
	CheckMenuRadioItem(GetMenu(hwnd), CMD[:ITEM4], CMD[:ITEM5], CMD[:ITEM5], 0)

	0
end

def OnItem6(verb,
	hctl, hwnd
)
	CheckMenuRadioItem(GetMenu(hwnd), CMD[:ITEM6], CMD[:ITEM7], CMD[:ITEM6], 0)

	0
end

def OnItem7(verb,
	hctl, hwnd
)
	CheckMenuRadioItem(GetMenu(hwnd), CMD[:ITEM6], CMD[:ITEM7], CMD[:ITEM7], 0)

	0
end

def OnItem8(verb,
	hctl, hwnd
)
	MessageBox(hwnd,
		L(__method__.to_s),
		APPNAME,
		MB_ICONINFORMATION
	)

	0
end

def OnItem9(verb,
	hctl, hwnd
)
	hbar = GetMenu(hwnd)
	i2grayed = (GetMenuState(hbar, CMD[:ITEM2], 0) & MF_GRAYED) == MF_GRAYED
	i3checked = (GetMenuState(hbar, CMD[:ITEM3], 0) & MF_CHECKED) == MF_CHECKED
	i4checked = (GetMenuState(hbar, CMD[:ITEM4], 0) & MF_CHECKED) == MF_CHECKED
	i5checked = (GetMenuState(hbar, CMD[:ITEM5], 0) & MF_CHECKED) == MF_CHECKED
	i6checked = (GetMenuState(hbar, CMD[:ITEM6], 0) & MF_CHECKED) == MF_CHECKED
	i7checked = (GetMenuState(hbar, CMD[:ITEM7], 0) & MF_CHECKED) == MF_CHECKED

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
		OnCreate(hwnd, CREATESTRUCT.new(FFI::Pointer.new(lParam)))
	when WM_DESTROY
		OnDestroy(hwnd)

	when WM_COMMAND
		id, verb = LOWORD(wParam), HIWORD(wParam)
		hctl = FFI::Pointer.new(lParam)

		case id
		when CMD[:ITEM1]
			OnItem1(verb, hctl, hwnd)
		when CMD[:ITEM2]
			OnItem2(verb, hctl, hwnd)
		when CMD[:ITEM3]
			OnItem3(verb, hctl, hwnd)
		when CMD[:ITEM4]
			OnItem4(verb, hctl, hwnd)
		when CMD[:ITEM5]
			OnItem5(verb, hctl, hwnd)
		when CMD[:ITEM6]
			OnItem6(verb, hctl, hwnd)
		when CMD[:ITEM7]
			OnItem7(verb, hctl, hwnd)
		when CMD[:ITEM8]
			OnItem8(verb, hctl, hwnd)
		when CMD[:ITEM9]
			OnItem9(verb, hctl, hwnd)
		end
	end

	result || DefWindowProc(hwnd, uMsg, wParam, lParam)
rescue SystemExit => ex
	PostQuitMessage(ex.status)
rescue
	case MessageBox(hwnd,
		L(FormatException($!)),
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

def WinMain
	Id2RefTrack(xtra = WndExtra.new)

	WNDCLASSEX.new { |wc|
		wc[:cbSize] = wc.size
		wc[:lpfnWndProc] = WindowProc
		wc[:cbWndExtra] = FFI::Type::Builtin::POINTER.size
		wc[:hInstance] = GetModuleHandle(nil)
		wc[:hIcon] = LoadIcon(nil, IDI_APPLICATION)
		wc[:hCursor] = LoadCursor(nil, IDC_ARROW)
		wc[:hbrBackground] = FFI::Pointer.new(COLOR_WINDOW + 1)

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
		L(FormatException($!)),
		APPNAME,
		MB_ICONERROR
	); exit(1)
end

WinMain()
