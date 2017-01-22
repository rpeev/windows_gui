require 'windows_gui'

include WindowsGUI

WndExtra = Struct.new(
	:hcm
)

def OnCreate(hwnd,
	cs
)
	xtra = Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	xtra[:hcm] = CreatePopupMenu()
		AppendMenu(xtra[:hcm], MF_STRING, CMD[:ITEM1], L('Item&1'))

	0
end

def OnDestroy(hwnd)
	xtra = Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	DestroyMenu(xtra[:hcm])

	PostQuitMessage(0); 0
end

def OnContextMenu(hwnd,
	x, y
)
	xtra = Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	POINT.new { |point|
		GetCursorPos(point)

		x, y = point.values
	} if x == -1

	TrackPopupMenu(xtra[:hcm], TPM_RIGHTBUTTON, x, y, 0, hwnd, nil)

	0
end

def OnItem1(verb,
	hctl, hwnd
)
	MessageBox(hwnd,
		L(__method__.to_s),
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

	when WM_CONTEXTMENU
		OnContextMenu(hwnd, LOSHORT(lParam), HISHORT(lParam))
	when WM_COMMAND
		id, verb = LOWORD(wParam), HIWORD(wParam)
		hctl = FFI::Pointer.new(lParam)

		case id
		when CMD[:ITEM1]
			OnItem1(verb, hctl, hwnd)
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
