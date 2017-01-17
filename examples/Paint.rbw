require 'windows_gui'

include WindowsGUI

WndExtra = Struct.new(
	:hfont
)

def OnCreate(hwnd,
	cs
)
	xtra = Util::Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	LOGFONT.new { |lf|
		lf[:lfHeight] = DPIAwareFontHeight(16)
		lf[:lfItalic] = 1
		lf[:lfFaceName].to_ptr.put_bytes(0, L('Verdana'))

		xtra[:hfont] = CreateFontIndirect(lf)
	}

	0
end

def OnDestroy(hwnd)
	xtra = Util::Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	DeleteObject(xtra[:hfont])

	PostQuitMessage(0); 0
end

def OnPaint(hwnd,
	ps
)
	xtra = Util::Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	SetBkColor(ps[:hdc], RGB(255, 0, 0))
	SetTextColor(ps[:hdc], RGB(255, 255, 255))

	UseObjects(ps[:hdc], xtra[:hfont]) {
		RECT.new { |rect|
			GetClientRect(hwnd, rect)

			DrawText(ps[:hdc],
				L('The quick brown fox jumps over the lazy dog. 1234567890'), -1,
				rect, DT_SINGLELINE | DT_CENTER | DT_VCENTER
			)
		}
	}

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

	when WM_PAINT
		DoPaint(hwnd) { |ps| result = OnPaint(hwnd, ps) }
	when WM_PRINTCLIENT
		DoPrintClient(hwnd, wParam) { |ps| result = OnPaint(hwnd, ps) }
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

def WinMain
	Util.Id2RefTrack(xtra = WndExtra.new)

	WNDCLASSEX.new { |wc|
		wc[:cbSize] = wc.size
		wc[:style] = CS_HREDRAW | CS_VREDRAW
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
		WS_EX_CLIENTEDGE, APPNAME, APPNAME, WS_OVERLAPPEDWINDOW | WS_CLIPCHILDREN,
		CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT, CW_USEDEFAULT,
		nil, nil, GetModuleHandle(nil), FFI::Pointer.new(xtra.object_id)
	)

	raise "CreateWindowEx failed (last error: #{GetLastError()})" if
		hwnd.null? && GetLastError() != 0

	exit(0) if hwnd.null?

	AnimateWindow(hwnd, 1000, AW_ACTIVATE | AW_BLEND)

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

WinMain()
