require 'ffi-wingui-core'

include WinGUI

WndExtra = Struct.new(
	:haccel,
	:hmf
)

def onCreate(hwnd,
	cs
)
	xtra = Util::Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	hsys = GetSystemMenu(hwnd, 0)
		InsertMenu(hsys, SC_CLOSE, MF_STRING, SYSID[:ITEM1], L("Item&1\tAlt+S"))
		InsertMenu(hsys, SC_CLOSE, MF_SEPARATOR, 0, nil)

	hbar = CreateMenu()
		hmenu1 = CreatePopupMenu()
			AppendMenu(hmenu1, MF_STRING, ID[:ITEM1], L("Item&1\tAlt+I"))
		AppendMenu(hbar, MF_POPUP, hmenu1.to_i, L('Menu&1'))
	SetMenu(hwnd, hbar)

	accels = [
		[FVIRTKEY | FALT, 'S'.ord, SYSID[:ITEM1]],
		[FVIRTKEY | FALT, 'I'.ord, ID[:ITEM1]]
	]

	FFI::MemoryPointer.new(ACCEL, accels.count) { |paccels|
		accels.each_with_index { |data, i|
			accel = ACCEL.new(paccels + i * ACCEL.size)

			accel[:fVirt], accel[:key], accel[:cmd] = data
		}

		xtra[:haccel] = CreateAcceleratorTable(paccels, accels.count)
	}

	NONCLIENTMETRICS.new { |ncm|
		ncm[:cbSize] = ncm.size

		SystemParametersInfo(SPI_GETNONCLIENTMETRICS, ncm.size, ncm, 0);
		xtra[:hmf] = CreateFontIndirect(ncm[:lfMenuFont])
	}

	hbtn1 = CreateWindowEx(
		0, L('Button'), L('&Button1'), WS_CHILD | WS_CLIPSIBLINGS |
			WS_VISIBLE | WS_TABSTOP,
		*DPIAwareXY(10, 10, 100, 25),
		hwnd, FFI::Pointer.new(ID[:BUTTON1]), GetModuleHandle(nil), nil
	)

	SendMessage(hbtn1, WM_SETFONT, xtra[:hmf].to_i, 1)

	CreateWindowEx(
		0, L('Static'), L(''), WS_CHILD | WS_CLIPSIBLINGS,
		0, 0, 0, 0,
		hwnd, FFI::Pointer.new(ID[:FOCUS]), GetModuleHandle(nil), nil
	)

	0
end

def onDestroy(hwnd)
	xtra = Util::Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	DestroyAcceleratorTable(xtra[:haccel])
	DeleteObject(xtra[:hmf])

	PostQuitMessage(0); 0
end

def onActivate(hwnd,
	state, minimized,
	hother
)
	SetFocus(GetDlgItem(hwnd, ID[:FOCUS])) if state != WA_INACTIVE

	0
end

def onSysItem1(lParam,
	hwnd
)
	MessageBox(hwnd,
		L(__method__.to_s),
		APPNAME,
		MB_ICONINFORMATION
	)

	0
end

def onItem1(verb,
	hctl, hwnd
)
	MessageBox(hwnd,
		L(__method__.to_s),
		APPNAME,
		MB_ICONINFORMATION
	)

=begin
		verb:
			0 - menu
			1 - accelerator
=end

	raise 'WM_COMMAND hctl must be NULL for menu/accelerator' unless
		hctl.null?

	EnableWindow(GetDlgItem(hwnd, ID[:BUTTON1]), 1)
	EnableMenuItem(GetMenu(hwnd), ID[:ITEM1], MF_GRAYED)

	0
end

def onButton1(verb,
	hctl, hwnd
)
	MessageBox(hwnd,
		L(__method__.to_s),
		APPNAME,
		MB_ICONINFORMATION
	)

=begin
		verb:
			BN_xxx
=end

	raise 'WM_COMMAND hctl must NOT be NULL for control' if
		hctl.null?

	EnableMenuItem(GetMenu(hwnd), ID[:ITEM1], MF_ENABLED)
	EnableWindow(hctl, 0)

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

	when WM_ACTIVATE
		onActivate(hwnd,
			LOWORD(wParam), HIWORD(wParam) != 0,
			FFI::Pointer.new(lParam)
		)

	when WM_SYSCOMMAND
		id = wParam & 0xfff0

		case id
		when SYSID[:ITEM1]
			onSysItem1(lParam, hwnd)
		end
	when WM_COMMAND
		id, verb = LOWORD(wParam), HIWORD(wParam)
		hctl = FFI::Pointer.new(lParam)

		case id
		when ID[:ITEM1]
			onItem1(verb, hctl, hwnd)
		when ID[:BUTTON1]
			onButton1(verb, hctl, hwnd)
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
			if TranslateAccelerator(hwnd, xtra[:haccel], msg) == 0 &&
				IsDialogMessage(hwnd, msg) == 0

				TranslateMessage(msg)
				DispatchMessage(msg)
			end
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
