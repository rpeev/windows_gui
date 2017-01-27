require 'windows_gui'

include WindowsGUI

WndExtra = Struct.new(
	:hpen,
	:curpos,
	:scribbles
)

def OnCreate(hwnd,
	cs
)
	xtra = Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	UsingFFIStructs(LOGPEN.new) { |lp|
		lp[:lopnWidth][:x] = DPIAwareX(10)
		lp[:lopnColor] = RGB(255, 0, 0)

		xtra[:hpen] = CreatePenIndirect(lp)
	}

	xtra[:scribbles] = []

	0
end

def OnDestroy(hwnd)
	xtra = Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	DeleteObject(xtra[:hpen])

	PostQuitMessage(0); 0
end

def OnPaint(hwnd,
	ps
)
	xtra = Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	UsingGDIObjects(ps[:hdc], xtra[:hpen]) {
		xtra[:scribbles].each { |scribble|
			MoveToEx(ps[:hdc], *scribble[0], nil)

			scribble.each { |x, y|
				LineTo(ps[:hdc], x, y)
			}
		}
	}

	0
end

def OnLButtonDown(hwnd,
	x, y
)
	SetCapture(hwnd)

	xtra = Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	xtra[:curpos] = [x, y]
	xtra[:scribbles] << [[x, y]]

	UsingFFIStructs(RECT.new) { |rect|
		SetRect(rect, x, y, x, y)
		InflateRect(rect, *DPIAwareXY(5, 5))
		InvalidateRect(hwnd, rect, 1)
	}

	0
end

def OnLButtonUp(hwnd,
	x, y
)
	ReleaseCapture()

	0
end

def OnMouseMove(hwnd,
	x, y
)
	return 0 if GetCapture() != hwnd

	xtra = Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	xtra[:scribbles].last << [x, y]

	UsingDC(hwnd) { |hdc|
		UsingGDIObjects(hdc, xtra[:hpen]) {
			MoveToEx(hdc, *xtra[:curpos], nil)
			LineTo(hdc, x, y)

			xtra[:curpos] = [x, y]
		}
	}

	0
end

def OnRButtonDown(hwnd,
	x, y
)
	return 0 if GetCapture() == hwnd

	xtra = Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	xtra[:scribbles].clear

	InvalidateRect(hwnd, nil, 1)

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

	when WM_LBUTTONDOWN
		OnLButtonDown(hwnd, LOSHORT(lParam), HISHORT(lParam))
	when WM_LBUTTONUP
		OnLButtonUp(hwnd, LOSHORT(lParam), HISHORT(lParam))
	when WM_MOUSEMOVE
		OnMouseMove(hwnd, LOSHORT(lParam), HISHORT(lParam))

	when WM_RBUTTONDOWN
		OnRButtonDown(hwnd, LOSHORT(lParam), HISHORT(lParam))
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

	UsingFFIStructs(WNDCLASSEX.new) { |wc|
		wc[:cbSize] = wc.size
		wc[:lpfnWndProc] = WindowProc
		wc[:cbWndExtra] = FFI::Type::Builtin::POINTER.size
		wc[:hInstance] = GetModuleHandle(nil)
		wc[:hIcon] = LoadIcon(nil, IDI_APPLICATION)
		wc[:hCursor] = LoadCursor(nil, IDC_CROSS)
		wc[:hbrBackground] = FFI::Pointer.new(COLOR_WINDOW + 1)

		UsingFFIMemoryPointers(PWSTR(APPNAME)) { |className|
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

	ShowWindow(hwnd, SW_SHOWNORMAL)
	UpdateWindow(hwnd)

	UsingFFIStructs(MSG.new) { |msg|
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
