require 'ffi-wingui-core'

include WinGUI

def onNCCreate(hwnd,
	cs
)
	answer = MessageBox(nil,
		L('NCCreate?'),
		cs[:lpszName],
		MB_YESNO | MB_ICONQUESTION
	)

	return 0 if answer == IDNO

	1
end

def onCreate(hwnd,
	cs
)
	answer = MessageBox(nil,
		L('Create?'),
		cs[:lpszName],
		MB_YESNO | MB_ICONQUESTION
	)

	return -1 if answer == IDNO

	0
end

def onClose(hwnd)
	answer = MessageBox(hwnd,
		L('Close?'),
		APPNAME,
		MB_YESNO | MB_ICONQUESTION |
		MB_DEFBUTTON2
	)

	DestroyWindow(hwnd) if answer == IDYES

	0
end

def onDestroy(hwnd)
	MessageBox(nil,
		L(__method__.to_s),
		APPNAME,
		MB_ICONINFORMATION
	)

	0
end

def onNCDestroy(hwnd)
	MessageBox(nil,
		L(__method__.to_s),
		APPNAME,
		MB_ICONINFORMATION
	)

	PostQuitMessage(0); 0
end

WindowProc = FFI::Function.new(:long,
	[:pointer, :uint, :uint, :long],
	convention: :stdcall
) { |hwnd, uMsg, wParam, lParam|
begin
	result = case uMsg
	when WM_NCCREATE
		DefWindowProc(hwnd, uMsg, wParam, lParam)

		onNCCreate(hwnd, CREATESTRUCT.new(FFI::Pointer.new(lParam)))
	when WM_CREATE
		onCreate(hwnd, CREATESTRUCT.new(FFI::Pointer.new(lParam)))
	when WM_CLOSE
		onClose(hwnd)
	when WM_DESTROY
		onDestroy(hwnd)
	when WM_NCDESTROY
		onNCDestroy(hwnd)
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
	WNDCLASSEX.new { |wc|
		wc[:cbSize] = wc.size
		wc[:lpfnWndProc] = WindowProc
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
		nil, nil, GetModuleHandle(nil), nil
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
