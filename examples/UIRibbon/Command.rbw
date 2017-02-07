#WINDOWS_COM_TRACE_CALLBACK_REFCOUNT = true
#WINDOWS_COM_TRACE_CALL_ARGS = true

require 'windows_gui'
require 'windows_gui/uiribbon'

include WindowsGUI
include UIRibbon

class UIF < UIFramework
	def initialize(hwnd)
		@hwnd = hwnd

		super() # wire COM stuff
	end

	attr_reader :hwnd
end

class UICH < IUICommandHandlerImpl
	def initialize(uif)
		@uif = uif

		super() # wire COM stuff
	end

	attr_reader :uif

	def OnAOT(*args)
		aot = PROPVARIANT[VT_BOOL, :boolVal, 0]

		uif.GetUICommandProperty(CmdAOT, UI_PKEY_BooleanValue, aot)
		SetWindowPos(uif.hwnd,
			(aot[:boolVal] == -1) ? HWND_TOPMOST : HWND_NOTOPMOST,
			0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE
		)
	end

	def OnItem1(*args)
		MessageBox(uif.hwnd,
			L("#{self}.#{__method__}"),
			APPNAME,
			MB_OK
		)

		uif.SetUICommandProperty(CmdButton1, UI_PKEY_Enabled, PROPVARIANT[VT_BOOL, :boolVal, -1])
		uif.SetUICommandProperty(CmdItem1, UI_PKEY_Enabled, PROPVARIANT[VT_BOOL, :boolVal, 0])
	end

	def OnButton1(*args)
		MessageBox(uif.hwnd,
			L("#{self}.#{__method__}"),
			APPNAME,
			MB_OK
		)

		uif.SetUICommandProperty(CmdItem1, UI_PKEY_Enabled, PROPVARIANT[VT_BOOL, :boolVal, -1])
		uif.SetUICommandProperty(CmdButton1, UI_PKEY_Enabled, PROPVARIANT[VT_BOOL, :boolVal, 0])
	end

	# COM interface method implementations

	def Execute(*args)
		case args[0]
		when CmdAOT
			OnAOT(*args)
		when CmdItem1
			OnItem1(*args)
		when CmdButton1
			OnButton1(*args)
		end

		S_OK
	end
end

class UIA < IUIApplicationImpl
	def initialize(uich)
		@uich = uich

		super() # wire COM stuff
	end

	attr_reader :uich

	# COM interface method implementations

	def OnCreateUICommand(*args)
		uich.QueryInterface(uich.class::IID, args[-1])

		S_OK
	end
end

WndExtra = Struct.new(
	:uif,
	:uich,
	:uia
)

def OnCreate(hwnd,
	cs
)
	xtra = Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	# attempt to build UIRibbon resources if the resource dll is missing
	# or UIRibbon description xml file exists and is newer than the resource dll
	# (requires installed developement environment (Visual Studio Express will do))
	UIResources.Build(clean: true) if UIResources.BuildNeeded?()

	xtra[:uif] = UIF.new(hwnd)
	xtra[:uich] = UICH.new(xtra[:uif])
	xtra[:uia] = UIA.new(xtra[:uich])

	xtra[:uif].Initialize(hwnd, xtra[:uia])
	xtra[:uif].LoadUI(UIResources.Load(), L('APPLICATION_RIBBON'))

	xtra[:uif].SetUICommandProperty(CmdAOT, UI_PKEY_BooleanValue, PROPVARIANT[VT_BOOL, :boolVal, -1])

	0
end

def OnDestroy(hwnd)
	xtra = Id2Ref[GetWindowLong(hwnd, GWL_USERDATA)]

	xtra[:uif].Destroy()
	xtra[:uif].Release()
	xtra[:uich].Release()
	xtra[:uia].Release()

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

		SetWindowLong(hwnd,
			GWL_USERDATA,
			CREATESTRUCT.new(FFI::Pointer.new(lParam))[:lpCreateParams].to_i
		)

		1
	when WM_CREATE
		OnCreate(hwnd, CREATESTRUCT.new(FFI::Pointer.new(lParam)))
	when WM_DESTROY
		OnDestroy(hwnd)
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
		wc[:hCursor] = LoadCursor(nil, IDC_ARROW)
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
	SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE)
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
