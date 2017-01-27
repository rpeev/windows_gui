if __FILE__ == $0
	require_relative 'common'
	require_relative 'libc'
	require_relative 'kernel'
	require_relative 'gdi'
end

module WindowsGUI
	ffi_lib 'user32'
	ffi_convention :stdcall

	attach_function :SetRect, [
		RECT.by_ref(:out),
		:int,
		:int,
		:int,
		:int
	], :int

	attach_function :CopyRect, [
		RECT.by_ref(:out),
		RECT.by_ref(:in)
	], :int

	attach_function :OffsetRect, [
		RECT.by_ref,
		:int,
		:int
	], :int

	attach_function :InflateRect, [
		RECT.by_ref,
		:int,
		:int
	], :int

	attach_function :SubtractRect, [
		RECT.by_ref(:out),
		RECT.by_ref(:in),
		RECT.by_ref(:in)
	], :int

	attach_function :IntersectRect, [
		RECT.by_ref(:out),
		RECT.by_ref(:in),
		RECT.by_ref(:in)
	], :int

	attach_function :UnionRect, [
		RECT.by_ref(:out),
		RECT.by_ref(:in),
		RECT.by_ref(:in)
	], :int

	attach_function :IsRectEmpty, [
		RECT.by_ref(:in)
	], :int

	attach_function :PtInRect, [
		RECT.by_ref(:in),
		POINT.by_value
	], :int

	attach_function :EqualRect, [
		RECT.by_ref(:in),
		RECT.by_ref(:in)
	], :int

	def NormalizeRect(rect)
		rect[:left], rect[:right] = rect[:right], rect[:left] if
			rect[:left] > rect[:right]
		rect[:top], rect[:bottom] = rect[:bottom], rect[:top] if
			rect[:top] > rect[:bottom]
	end

	module_function \
		:NormalizeRect

	attach_function :DrawFocusRect, [
		:pointer,
		RECT.by_ref(:in)
	], :int

	attach_function :FrameRect, [
		:pointer,
		RECT.by_ref(:in),
		:pointer
	], :int

	attach_function :FillRect, [
		:pointer,
		RECT.by_ref(:in),
		:pointer
	], :int

	DT_PREFIXONLY = 0x0020_0000
	DT_HIDEPREFIX = 0x0010_0000
	DT_NOPREFIX = 0x0000_0800
	DT_MODIFYSTRING = 0x0001_0000
	DT_END_ELLIPSIS = 0x0000_8000
	DT_PATH_ELLIPSIS = 0x0000_4000
	DT_WORD_ELLIPSIS = 0x0004_0000
	DT_INTERNAL = 0x0000_1000
	DT_EDITCONTROL = 0x0000_2000

	DT_SINGLELINE = 0x0000_0020
	DT_WORDBREAK = 0x0000_0010

	DT_LEFT = 0x0000_0000
	DT_CENTER = 0x0000_0001
	DT_RIGHT = 0x0000_0002

	DT_TOP = 0x0000_0000
	DT_VCENTER = 0x0000_0004
	DT_BOTTOM = 0x0000_0008

	DT_EXPANDTABS = 0x0000_0040
	DT_TABSTOP = 0x0000_0080

	DT_CALCRECT = 0x0000_0400
	DT_EXTERNALLEADING = 0x0000_0200
	DT_NOCLIP = 0x0000_0100

	attach_function :DrawText, :DrawTextW, [
		:pointer,
		:buffer_inout,
		:int,
		RECT.by_ref,
		:uint
	], :int

	if WINVER >= WINVISTA
		attach_function :SetProcessDPIAware, [

		], :int
	end

	def DeclareDPIAware
		return unless WINVER >= WINVISTA

		Detonate(0, :SetProcessDPIAware)

		STDERR.puts "DPI aware init" if $DEBUG
	end

	module_function \
		:DeclareDPIAware

	DeclareDPIAware() if WINDOWS_GUI_DPI_AWARE

	attach_function :GetWindowDC, [
		:pointer
	], :pointer

	attach_function :GetDC, [
		:pointer
	], :pointer

	attach_function :ReleaseDC, [
		:pointer,
		:pointer
	], :int

	def UsingWindowDC(hwnd)
		hdc = DetonateLastError(FFI::Pointer::NULL, :GetWindowDC,
			hwnd
		)

		begin
			yield hdc
		ensure
			ReleaseDC(hwnd, hdc)
		end
	end

	def UsingDC(hwnd)
		hdc = DetonateLastError(FFI::Pointer::NULL, :GetDC,
			hwnd
		)

		begin
			yield hdc
		ensure
			ReleaseDC(hwnd, hdc)
		end
	end

	module_function \
		:UsingWindowDC,
		:UsingDC

	UsingDC(nil) { |hdc|
		DPIX = GetDeviceCaps(hdc, LOGPIXELSX)
		DPIY = GetDeviceCaps(hdc, LOGPIXELSY)
	}

	def DPIAwareX(x)
		MulDiv(x, DPIX, 96)
	end

	def DPIAwareY(y)
		MulDiv(y, DPIY, 96)
	end

	def DPIAwareXY(*args)
		raise ArgumentError, 'Expected two or more, even count arguments' if
			args.length < 2 || args.length.odd?

		args.each_with_index { |arg, i|
			args[i] = (i.even?) ? DPIAwareX(arg) : DPIAwareY(arg)
		}
	end

	module_function \
		:DPIAwareX,
		:DPIAwareY,
		:DPIAwareXY

	SM_CXSCREEN = 0
	SM_CYSCREEN = 1

	attach_function :GetSystemMetrics, [
		:int
	], :int

	class NONCLIENTMETRICS < FFI::Struct
		layout(*[
			:cbSize, :uint,
			:iBorderWidth, :int,
			:iScrollWidth, :int,
			:iScrollHeight, :int,
			:iCaptionWidth, :int,
			:iCaptionHeight, :int,
			:lfCaptionFont, LOGFONT,
			:iSmCaptionWidth, :int,
			:iSmCaptionHeight, :int,
			:lfSmCaptionFont, LOGFONT,
			:iMenuWidth, :int,
			:iMenuHeight, :int,
			:lfMenuFont, LOGFONT,
			:lfStatusFont, LOGFONT,
			:lfMessageFont, LOGFONT,
			(WINVER >= WINVISTA) ? [:iPaddedBorderWidth, :int] : nil
		].tap { |layout|
			layout.flatten!
			layout.compact!
		})
	end

	SPI_SETNONCLIENTMETRICS = 0x002a
	SPI_GETNONCLIENTMETRICS = 0x0029

	attach_function :SystemParametersInfo, :SystemParametersInfoW, [
		:uint,
		:uint,
		:pointer,
		:uint
	], :int

	MB_OK = 0x0000_0000
	MB_OKCANCEL = 0x0000_0001
	MB_YESNO = 0x0000_0004
	MB_YESNOCANCEL = 0x0000_0003
	MB_RETRYCANCEL = 0x0000_0005
	MB_ABORTRETRYIGNORE = 0x0000_0002
	MB_CANCELTRYCONTINUE = 0x0000_0006
	MB_HELP = 0x0000_4000

	MB_ICONINFORMATION = 0x0000_0040
	MB_ICONWARNING = 0x0000_0030
	MB_ICONERROR = 0x0000_0010
	MB_ICONQUESTION = 0x0000_0020

	MB_DEFBUTTON1 = 0x0000_0000
	MB_DEFBUTTON2 = 0x0000_0100
	MB_DEFBUTTON3 = 0x0000_0200
	MB_DEFBUTTON4 = 0x0000_0300

	MB_APPLMODAL = 0x0000_0000
	MB_TASKMODAL = 0x0000_2000
	MB_SYSTEMMODAL = 0x0000_1000

	IDOK = 1
	IDCANCEL = 2
	IDYES = 6
	IDNO = 7
	IDABORT = 3
	IDRETRY = 4
	IDIGNORE = 5
	IDTRYAGAIN = 10
	IDCONTINUE = 11
	if WINVER >= WINXP
		IDTIMEOUT = 32000
	end

	attach_function :MessageBox, :MessageBoxW, [
		:pointer,
		:buffer_in,
		:buffer_in,
		:uint
	], :int

	if WINVER >= WINXP
		begin
			attach_function :MessageBoxTimeout, :MessageBoxTimeoutW, [
				:pointer,
				:buffer_in,
				:buffer_in,
				:uint,
				:ushort,
				:ulong
			], :int
		rescue FFI::NotFoundError # MessageBoxTimeout is undocumented

		end
	end

	WC_DIALOG = FFI::Pointer.new(0x8002)

	CS_DBLCLKS = 0x0008
	CS_HREDRAW = 0x0002
	CS_VREDRAW = 0x0001
	CS_PARENTDC = 0x0080
	CS_CLASSDC = 0x0040
	CS_OWNDC = 0x0020
	CS_SAVEBITS = 0x0800
	CS_NOCLOSE = 0x0200
	if WINVER >= WINXP
		CS_DROPSHADOW = 0x0002_0000
	end

	callback :WNDPROC, [
		:pointer,
		:uint,
		:uint,
		:long
	], :long

	attach_function :DefWindowProc, :DefWindowProcW, [
		:pointer,
		:uint,
		:uint,
		:long
	], :long

	attach_function :DefDlgProc, :DefDlgProcW, [
		:pointer,
		:uint,
		:uint,
		:long
	], :long

	attach_function :CallWindowProc, :CallWindowProcW, [
		:WNDPROC,
		:pointer,
		:uint,
		:uint,
		:long
	], :long

	callback :DLGPROC, [
		:pointer,
		:uint,
		:uint,
		:long
	], :int

	DLGWINDOWEXTRA = 30

	IMAGE_BITMAP = 0
	IMAGE_ICON = 1
	IMAGE_CURSOR = 2

	LR_SHARED = 0x0000_8000
	LR_LOADFROMFILE = 0x0000_0010
	LR_CREATEDIBSECTION = 0x0000_2000
	LR_LOADTRANSPARENT = 0x0000_0020
	LR_LOADMAP3DCOLORS = 0x0000_1000
	LR_DEFAULTSIZE = 0x0000_0040

	attach_function :LoadImage, :LoadImageW, [
		:pointer,
		:buffer_in,
		:uint,
		:int,
		:int,
		:uint
	], :pointer

	IDI_WINLOGO = FFI::Pointer.new(32517)
	IDI_APPLICATION = FFI::Pointer.new(32512)
	if WINVER >= WINVISTA
		IDI_SHIELD = FFI::Pointer.new(32518)
	end

	IDI_INFORMATION = FFI::Pointer.new(32516)
	IDI_WARNING = FFI::Pointer.new(32515)
	IDI_ERROR = FFI::Pointer.new(32513)
	IDI_QUESTION = FFI::Pointer.new(32514)

	attach_function :LoadIcon, :LoadIconW, [
		:pointer,
		:buffer_in
	], :pointer

	attach_function :DestroyIcon, [
		:pointer
	], :int

	begin
		attach_function :PrivateExtractIcons, :PrivateExtractIconsW, [
			:buffer_in,
			:int,
			:int,
			:int,
			:pointer,
			:pointer,
			:uint,
			:uint
		], :uint
	rescue FFI::NotFoundError # PrivateExtractIcons is not intended for general use

	end

	IDC_WAIT = FFI::Pointer.new(32514)
	IDC_APPSTARTING = FFI::Pointer.new(32650)

	IDC_ARROW = FFI::Pointer.new(32512)
	IDC_HAND = FFI::Pointer.new(32649)
	IDC_IBEAM = FFI::Pointer.new(32513)
	IDC_CROSS = FFI::Pointer.new(32515)
	IDC_HELP = FFI::Pointer.new(32651)
	IDC_NO = FFI::Pointer.new(32648)

	IDC_SIZEALL = FFI::Pointer.new(32646)
	IDC_SIZENS = FFI::Pointer.new(32645)
	IDC_SIZEWE = FFI::Pointer.new(32644)
	IDC_SIZENWSE = FFI::Pointer.new(32642)
	IDC_SIZENESW = FFI::Pointer.new(32643)

	attach_function :LoadCursor, :LoadCursorW, [
		:pointer,
		:buffer_in
	], :pointer

	attach_function :DestroyCursor, [
		:pointer
	], :int

	attach_function :SetCursor, [
		:pointer
	], :pointer

	attach_function :GetCursor, [

	], :pointer

	attach_function :SetCursorPos, [
		:int,
		:int
	], :int

	attach_function :GetCursorPos, [
		POINT.by_ref(:out)
	], :int

	attach_function :ShowCursor, [
		:int
	], :int

	COLOR_DESKTOP = 1
	COLOR_APPWORKSPACE = 12
	COLOR_WINDOW = 5
	if WINVER >= WINXP
		COLOR_MENUBAR = 30
	end
	COLOR_MENU = 4

	class WNDCLASSEX < FFI::Struct
		layout \
			:cbSize, :uint,
			:style, :uint,
			:lpfnWndProc, :WNDPROC,
			:cbClsExtra, :int,
			:cbWndExtra, :int,
			:hInstance, :pointer,
			:hIcon, :pointer,
			:hCursor, :pointer,
			:hbrBackground, :pointer,
			:lpszMenuName, :pointer,
			:lpszClassName, :pointer,
			:hIconSm, :pointer
	end

	attach_function :RegisterClassEx, :RegisterClassExW, [
		WNDCLASSEX.by_ref(:in)
	], :ushort

	attach_function :UnregisterClass, :UnregisterClassW, [
		:buffer_in,
		:pointer
	], :int

	attach_function :GetClassInfoEx, :GetClassInfoExW, [
		:pointer,
		:buffer_in,
		WNDCLASSEX.by_ref(:out)
	], :int

	attach_function :FindWindow, :FindWindowW, [
		:buffer_in,
		:buffer_in
	], :pointer

	callback :WNDENUMPROC, [
		:pointer,
		:long
	], :int

	attach_function :EnumChildWindows, [
		:pointer,
		:WNDENUMPROC,
		:long
	], :int

	attach_function :GetDesktopWindow, [

	], :pointer

	GW_HWNDFIRST = 0
	GW_HWNDLAST = 1
	GW_HWNDNEXT = 2
	GW_HWNDPREV = 3
	GW_OWNER = 4
	GW_ENABLEDPOPUP = 6
	GW_CHILD = 5

	attach_function :GetWindow, [
		:pointer,
		:uint
	], :pointer

	GA_PARENT = 1
	GA_ROOT = 2
	GA_ROOTOWNER = 3

	attach_function :GetAncestor, [
		:pointer,
		:uint
	], :pointer

	attach_function :SetParent, [
		:pointer,
		:pointer
	], :pointer

	attach_function :GetParent, [
		:pointer
	], :pointer

	WS_EX_WINDOWEDGE = 0x0000_0100
	WS_EX_CLIENTEDGE = 0x0000_0200
	WS_EX_STATICEDGE = 0x0002_0000
	WS_EX_DLGMODALFRAME = 0x0000_0001
	WS_EX_CONTEXTHELP = 0x0000_0400
	WS_EX_ACCEPTFILES = 0x0000_0010

	WS_EX_TOPMOST = 0x0000_0008
	WS_EX_LAYERED = 0x0008_0000
	if WINVER >= WINXP
		WS_EX_COMPOSITED = 0x0200_0000
	end
	WS_EX_TRANSPARENT = 0x0000_0020

	WS_EX_NOPARENTNOTIFY = 0x0000_0004

	WS_EX_APPWINDOW = 0x0004_0000
	WS_EX_OVERLAPPEDWINDOW = \
		WS_EX_WINDOWEDGE | WS_EX_CLIENTEDGE
	WS_EX_TOOLWINDOW = 0x0000_0080
	WS_EX_PALETTEWINDOW = WS_EX_TOOLWINDOW |
		WS_EX_WINDOWEDGE | WS_EX_TOPMOST
	WS_EX_CONTROLPARENT = 0x0001_0000

	WS_BORDER = 0x0080_0000
	WS_DLGFRAME = 0x0040_0000
	WS_CAPTION = 0x00c0_0000
	WS_SYSMENU = 0x0008_0000
	WS_THICKFRAME = 0x0004_0000
	WS_MINIMIZEBOX = 0x0002_0000
	WS_MAXIMIZEBOX = 0x0001_0000
	WS_HSCROLL = 0x0010_0000
	WS_VSCROLL = 0x0020_0000

	WS_DISABLED = 0x0800_0000
	WS_VISIBLE = 0x1000_0000
	WS_MINIMIZE = 0x2000_0000
	WS_MAXIMIZE = 0x0100_0000
	WS_CLIPCHILDREN = 0x0200_0000

	WS_GROUP = 0x0002_0000
	WS_TABSTOP = 0x0001_0000
	WS_CLIPSIBLINGS = 0x0400_0000

	WS_OVERLAPPED = 0x0000_0000
	WS_OVERLAPPEDWINDOW = WS_OVERLAPPED |
		WS_CAPTION | WS_SYSMENU |
		WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX
	WS_POPUP = 0x8000_0000
	WS_POPUPWINDOW = WS_POPUP |
		WS_BORDER | WS_SYSMENU
	WS_CHILD = 0x4000_0000
	WS_CHILDWINDOW = WS_CHILD

	DS_MODALFRAME = 0x80
	DS_ABSALIGN = 0x01
	DS_CENTER = 0x0800
	DS_CENTERMOUSE = 0x1000
	DS_CONTROL = 0x0400

	CW_USEDEFAULT = 0x8000_0000 - 0x1_0000_0000

	HWND_DESKTOP = FFI::Pointer.new(0)
	HWND_MESSAGE = FFI::Pointer.new(-3)

	attach_function :CreateWindowEx, :CreateWindowExW, [
		:ulong,
		:buffer_in,
		:buffer_in,
		:ulong,
		:int,
		:int,
		:int,
		:int,
		:pointer,
		:pointer,
		:pointer,
		:pointer
	], :pointer

	class DLGTEMPLATE < FFI::Struct
		layout \
			:style, :ulong,
			:dwExtendedStyle, :ulong,
			:cdit, :ushort,
			:x, :short,
			:y, :short,
			:cx, :short,
			:cy, :short,
			:menu, :ushort,
			:windowClass, :ushort,
			:title, :ushort
	end

	attach_function :CreateDialogIndirectParam, :CreateDialogIndirectParamW, [
		:pointer,
		DLGTEMPLATE.by_ref(:in),
		:pointer,
		:DLGPROC,
		:long
	], :pointer

	attach_function :DestroyWindow, [
		:pointer
	], :int

	attach_function :DialogBoxIndirectParam, :DialogBoxIndirectParamW, [
		:pointer,
		DLGTEMPLATE.by_ref(:in),
		:pointer,
		:DLGPROC,
		:long
	], :int

	attach_function :EndDialog, [
		:pointer,
		:int
	], :int

	GCL_STYLE = -26
	GCL_WNDPROC = -24
	GCL_CBCLSEXTRA = -20
	GCL_CBWNDEXTRA = -18
	GCL_HMODULE = -16
	GCL_HICON = -14
	GCL_HCURSOR = -12
	GCL_HBRBACKGROUND = -10
	GCL_MENUNAME = -8
	GCL_HICONSM = -34
	GCW_ATOM = -32

	attach_function :SetClassLong, :SetClassLongW, [
		:pointer,
		:int,
		:long
	], :ulong

	attach_function :GetClassLong, :GetClassLongW, [
		:pointer,
		:int
	], :ulong

	attach_function :GetClassName, :GetClassNameW, [
		:pointer,
		:buffer_out,
		:int
	], :int

	GWL_WNDPROC = -4
	GWL_EXSTYLE = -20
	GWL_STYLE = -16
	GWL_HWNDPARENT = -8
	GWL_ID = -12
	GWL_HINSTANCE = -6
	GWL_USERDATA = -21

	DWL_DLGPROC = 4
	DWL_MSGRESULT = 0
	DWL_USER = 8

	attach_function :SetWindowLong, :SetWindowLongW, [
		:pointer,
		:int,
		:long
	], :long

	attach_function :GetWindowLong, :GetWindowLongW, [
		:pointer,
		:int
	], :long

	attach_function :SetProp, :SetPropW, [
		:pointer,
		:buffer_in,
		:long # HANDLE (void *) in the original prototype
	], :int

	attach_function :RemoveProp, :RemovePropW, [
		:pointer,
		:buffer_in
	], :long # HANDLE (void *) in the original prototype

	attach_function :GetProp, :GetPropW, [
		:pointer,
		:buffer_in
	], :long # HANDLE (void *) in the original prototype

	callback :PROPENUMPROCEX, [
		:pointer,
		:pointer,
		:long, # HANDLE (void *) in the original prototype
		:ulong
	], :int

	attach_function :EnumPropsEx, :EnumPropsExW, [
		:pointer,
		:PROPENUMPROCEX,
		:long
	], :int

	LWA_COLORKEY = 0x0000_0001
	LWA_ALPHA = 0x0000_0002

	attach_function :SetLayeredWindowAttributes, [
		:pointer,
		:ulong,
		:uchar,
		:ulong
	], :int

	if WINVER >= WINXP
		attach_function :GetLayeredWindowAttributes, [
			:pointer,
			:pointer,
			:pointer,
			:pointer
		], :int
	end

	attach_function :SetWindowRgn, [
		:pointer,
		:pointer,
		:int
	], :int

	attach_function :GetWindowRgn, [
		:pointer,
		:pointer
	], :int

	attach_function :IsWindowEnabled, [
		:pointer
	], :int

	attach_function :EnableWindow, [
		:pointer,
		:int
	], :int

	attach_function :SetActiveWindow, [
		:pointer
	], :pointer

	attach_function :GetActiveWindow, [

	], :pointer

	attach_function :SetForegroundWindow, [
		:pointer
	], :int

	attach_function :GetForegroundWindow, [

	], :pointer

	attach_function :SetFocus, [
		:pointer
	], :pointer

	attach_function :GetFocus, [

	], :pointer

	attach_function :IsWindowVisible, [
		:pointer
	], :int

	attach_function :IsIconic, [
		:pointer
	], :int

	attach_function :IsZoomed, [
		:pointer
	], :int

	SW_SHOWDEFAULT = 10
	SW_HIDE = 0
	SW_SHOW = 5
	SW_SHOWNA = 8
	SW_SHOWNORMAL = 1
	SW_SHOWNOACTIVATE = 4
	SW_SHOWMINIMIZED = 2
	SW_SHOWMINNOACTIVE = 7
	SW_MINIMIZE = 6
	SW_FORCEMINIMIZE = 11
	SW_SHOWMAXIMIZED = 3
	SW_MAXIMIZE = 3
	SW_RESTORE = 9

	attach_function :ShowWindow, [
		:pointer,
		:int
	], :int

	attach_function :ShowWindowAsync, [
		:pointer,
		:int
	], :int

	AW_HIDE = 0x0001_0000
	AW_ACTIVATE = 0x0002_0000
	AW_CENTER = 0x0000_0010
	AW_SLIDE = 0x0004_0000
	AW_HOR_POSITIVE = 0x0000_0001
	AW_HOR_NEGATIVE = 0x0000_0002
	AW_VER_POSITIVE = 0x0000_0004
	AW_VER_NEGATIVE = 0x0000_0008
	AW_BLEND = 0x0008_0000

	attach_function :AnimateWindow, [
		:pointer,
		:ulong,
		:ulong
	], :int

	HWND_TOP = FFI::Pointer.new(0)
	HWND_BOTTOM = FFI::Pointer.new(1)
	HWND_TOPMOST = FFI::Pointer.new(-1)
	HWND_NOTOPMOST = FFI::Pointer.new(-2)

	SWP_FRAMECHANGED = 0x0020
	SWP_NOACTIVATE = 0x0010
	SWP_NOOWNERZORDER = 0x0200
	SWP_NOZORDER = 0x0004
	SWP_NOMOVE = 0x0002
	SWP_NOSIZE = 0x0001
	SWP_ASYNCWINDOWPOS = 0x4000

	attach_function :SetWindowPos, [
		:pointer,
		:pointer,
		:int,
		:int,
		:int,
		:int,
		:uint
	], :int

	attach_function :BeginDeferWindowPos, [
		:int
	], :pointer

	attach_function :DeferWindowPos, [
		:pointer,
		:pointer,
		:pointer,
		:int,
		:int,
		:int,
		:int,
		:uint
	], :pointer

	attach_function :EndDeferWindowPos, [
		:pointer
	], :int

	attach_function :MapDialogRect, [
		:pointer,
		RECT.by_ref
	], :int

	SB_HORZ = 0
	SB_VERT = 1
	SB_BOTH = 3
	SB_CTL = 2

	SIF_RANGE = 0x0001
	SIF_PAGE = 0x0002
	SIF_POS = 0x0004
	SIF_TRACKPOS = 0x0010
	SIF_ALL = SIF_RANGE | SIF_PAGE | SIF_POS | SIF_TRACKPOS
	SIF_DISABLENOSCROLL = 0x0008

	class SCROLLINFO < FFI::Struct
		layout \
			:cbSize, :uint,
			:fMask, :uint,
			:nMin, :int,
			:nMax, :int,
			:nPage, :uint,
			:nPos, :int,
			:nTrackPos, :int
	end

	attach_function :SetScrollInfo, [
		:pointer,
		:int,
		SCROLLINFO.by_ref(:in),
		:int
	], :int

	attach_function :GetScrollInfo, [
		:pointer,
		:int,
		SCROLLINFO.by_ref
	], :int

	ESB_DISABLE_LEFT = 0x0001
	ESB_DISABLE_RIGHT = 0x0002
	ESB_DISABLE_UP = 0x0001
	ESB_DISABLE_DOWN = 0x0002

	ESB_ENABLE_BOTH = 0x0000
	ESB_DISABLE_BOTH = 0x0003

	attach_function :EnableScrollBar, [
		:pointer,
		:uint,
		:uint
	], :int

	attach_function :ShowScrollBar, [
		:pointer,
		:int,
		:int
	], :int

	attach_function :ScrollDC, [
		:pointer,
		:int,
		:int,
		RECT.by_ref(:in),
		RECT.by_ref(:in),
		:pointer,
		RECT.by_ref(:out)
	], :int

	SW_INVALIDATE = 0x0002
	SW_ERASE = 0x0004
	SW_SCROLLCHILDREN = 0x0001
	SW_SMOOTHSCROLL = 0x0010

	attach_function :ScrollWindowEx, [
		:pointer,
		:int,
		:int,
		RECT.by_ref(:in),
		RECT.by_ref(:in),
		:pointer,
		RECT.by_ref(:out),
		:uint
	], :int

	attach_function :GetWindowRect, [
		:pointer,
		RECT.by_ref(:out)
	], :int

	attach_function :GetClientRect, [
		:pointer,
		RECT.by_ref(:out)
	], :int

	attach_function :ScreenToClient, [
		:pointer,
		POINT.by_ref
	], :int

	attach_function :ClientToScreen, [
		:pointer,
		POINT.by_ref
	], :int

	attach_function :InvalidateRect, [
		:pointer,
		RECT.by_ref(:in),
		:int
	], :int

	attach_function :GetUpdateRect, [
		:pointer,
		RECT.by_ref(:out),
		:int
	], :int

	attach_function :UpdateWindow, [
		:pointer
	], :int

	class PAINTSTRUCT < FFI::Struct
		layout \
			:hdc, :pointer,
			:fErase, :int,
			:rcPaint, RECT,
			:fRestore, :int,
			:fIncUpdate, :int,
			:rgbReserved, [:uchar, 32]
	end

	attach_function :BeginPaint, [
		:pointer,
		PAINTSTRUCT.by_ref(:out)
	], :pointer

	attach_function :EndPaint, [
		:pointer,
		PAINTSTRUCT.by_ref(:in)
	], :int

	def DoPaint(hwnd)
		return unless GetUpdateRect(hwnd, nil, 0) != 0

		UsingFFIStructs(PAINTSTRUCT.new) { |ps|
			DetonateLastError(FFI::Pointer::NULL, :BeginPaint,
				hwnd, ps
			)

			begin
				yield ps
			ensure
				EndPaint(hwnd, ps)
			end
		}
	end

	def DoPrintClient(hwnd, wParam)
		UsingFFIStructs(PAINTSTRUCT.new) { |ps|
			ps[:hdc] = FFI::Pointer.new(wParam)
			ps[:fErase] = 1
			GetClientRect(hwnd, ps[:rcPaint])

			yield ps
		}
	end

	module_function \
		:DoPaint,
		:DoPrintClient

	attach_function :SetCapture, [
		:pointer
	], :pointer

	attach_function :ReleaseCapture, [

	], :int

	attach_function :GetCapture, [

	], :pointer

	attach_function :SetKeyboardState, [
		:pointer
	], :int

	attach_function :GetKeyboardState, [
		:pointer
	], :int

	attach_function :GetKeyState, [
		:int
	], :short

	attach_function :GetAsyncKeyState, [
		:int
	], :short

	INPUT_MOUSE = 0
	INPUT_KEYBOARD = 1
	INPUT_HARDWARE = 2

	MOUSEEVENTF_LEFTDOWN = 0x0002
	MOUSEEVENTF_LEFTUP = 0x0004

	MOUSEEVENTF_RIGHTDOWN = 0x0008
	MOUSEEVENTF_RIGHTUP = 0x0010

	MOUSEEVENTF_MIDDLEDOWN = 0x0020
	MOUSEEVENTF_MIDDLEUP = 0x0040

	MOUSEEVENTF_XDOWN = 0x0080
	MOUSEEVENTF_XUP = 0x0100

	MOUSEEVENTF_WHEEL = 0x0800
	if WINVER >= WINVISTA
		MOUSEEVENTF_HWHEEL = 0x1000
	end

	MOUSEEVENTF_MOVE = 0x0001
	if WINVER >= WINVISTA
		MOUSEEVENTF_MOVE_NOCOALESCE = 0x2000
	end

	MOUSEEVENTF_ABSOLUTE = 0x8000
	MOUSEEVENTF_VIRTUALDESK = 0x4000

	class MOUSEINPUT < FFI::Struct
		layout \
			:dx, :long,
			:dy, :long,
			:mouseData, :ulong,
			:dwFlags, :ulong,
			:time, :ulong,
			:dwExtraInfo, :ulong
	end

	KEYEVENTF_SCANCODE = 0x0008
	KEYEVENTF_EXTENDEDKEY = 0x0001
	KEYEVENTF_KEYUP = 0x0002
	KEYEVENTF_UNICODE = 0x0004

	class KEYBDINPUT < FFI::Struct
		layout \
			:wVk, :ushort,
			:wScan, :ushort,
			:dwFlags, :ulong,
			:time, :ulong,
			:dwExtraInfo, :ulong
	end

	class HARDWAREINPUT < FFI::Struct
		layout \
			:uMsg, :ulong,
			:wParamL, :ushort,
			:wParamH, :ushort
	end

	class INPUT < FFI::Struct
		layout \
			:type, :ulong,

			:_, Class.new(FFI::Union) {
				layout \
					:mi, MOUSEINPUT,
					:ki, KEYBDINPUT,
					:hi, HARDWAREINPUT
			}
	end

	attach_function :SendInput, [
		:uint,
		:pointer,
		:int
	], :uint

	attach_function :GetSystemMenu, [
		:pointer,
		:int
	], :pointer

	attach_function :SetMenu, [
		:pointer,
		:pointer
	], :int

	attach_function :GetMenu, [
		:pointer
	], :pointer

	attach_function :DrawMenuBar, [
		:pointer
	], :int

	attach_function :GetDlgItem, [
		:pointer,
		:int
	], :pointer

	attach_function :GetDlgCtrlID, [
		:pointer
	], :int

	attach_function :GetNextDlgGroupItem, [
		:pointer,
		:pointer,
		:int
	], :pointer

	attach_function :GetNextDlgTabItem, [
		:pointer,
		:pointer,
		:int
	], :pointer

	HWND_BROADCAST = FFI::Pointer.new(0xffff)

	class CREATESTRUCT < FFI::Struct
		layout \
			:lpCreateParams, :pointer,
			:hInstance, :pointer,
			:hMenu, :pointer,
			:hwndParent, :pointer,
			:cy, :int,
			:cx, :int,
			:y, :int,
			:x, :int,
			:style, :long,
			:lpszName, :pointer,
			:lpszClass, :pointer,
			:dwExStyle, :ulong
	end

	WM_NCCREATE = 0x0081
	WM_CREATE = 0x0001
	WM_INITDIALOG = 0x0110

	WM_CLOSE = 0x0010

	WM_DESTROY = 0x0002
	WM_NCDESTROY = 0x0082

	WM_QUIT = 0x0012

	ENDSESSION_CLOSEAPP = 0x0000_0001
	ENDSESSION_CRITICAL = 0x4000_0000
	ENDSESSION_LOGOFF = 0x8000_0000

	WM_QUERYENDSESSION = 0x0011
	WM_ENDSESSION = 0x0016

	class STYLESTRUCT < FFI::Struct
		layout \
			:styleOld, :ulong,
			:styleNew, :ulong
	end

	WM_STYLECHANGING = 0x007c
	WM_STYLECHANGED = 0x007d

	WM_ENABLE = 0x000a

	WA_INACTIVE = 0
	WA_ACTIVE = 1
	WA_CLICKACTIVE = 2

	WM_ACTIVATE = 0x0006

	WM_SETFOCUS = 0x0007
	WM_KILLFOCUS = 0x0008

	SW_PARENTOPENING = 3
	SW_PARENTCLOSING = 1
	SW_OTHERZOOM = 2
	SW_OTHERUNZOOM = 4

	WM_SHOWWINDOW = 0x0018

	class MINMAXINFO < FFI::Struct
		layout \
			:ptReserved, POINT,
			:ptMaxSize, POINT,
			:ptMaxPosition, POINT,
			:ptMinTrackSize, POINT,
			:ptMaxTrackSize, POINT
	end

	WM_GETMINMAXINFO = 0x0024

	class WINDOWPOS < FFI::Struct
		layout \
			:hwnd, :pointer,
			:hwndInsertAfter, :pointer,
			:x, :int,
			:y, :int,
			:cx, :int,
			:cy, :int,
			:flags, :int
	end

	WM_WINDOWPOSCHANGING = 0x0046
	WM_WINDOWPOSCHANGED = 0x0047

	WM_MOVING = 0x0216
	WM_MOVE = 0x0003

	WMSZ_LEFT = 1
	WMSZ_TOP = 3
	WMSZ_RIGHT = 2
	WMSZ_BOTTOM = 6
	WMSZ_TOPLEFT = 4
	WMSZ_TOPRIGHT = 5
	WMSZ_BOTTOMLEFT = 7
	WMSZ_BOTTOMRIGHT = 8

	WM_SIZING = 0x0214

	SIZE_MINIMIZED = 1
	SIZE_MAXIMIZED = 2
	SIZE_RESTORED = 0
	SIZE_MAXHIDE = 4
	SIZE_MAXSHOW = 3

	WM_SIZE = 0x0005

	SB_LEFT = 6
	SB_TOP = 6
	SB_RIGHT = 7
	SB_BOTTOM = 7

	SB_PAGELEFT = 2
	SB_PAGERIGHT = 3
	SB_PAGEUP = 2
	SB_PAGEDOWN = 3

	SB_LINELEFT = 0
	SB_LINERIGHT = 1
	SB_LINEUP = 0
	SB_LINEDOWN = 1

	SB_THUMBPOSITION = 4
	SB_THUMBTRACK = 5

	SB_ENDSCROLL = 8

	WM_HSCROLL = 0x0114
	WM_VSCROLL = 0x0115

	ICON_SMALL = 0
	ICON_BIG = 1
	if WINVER >= WINXP
		ICON_SMALL2 = 2
	end

	WM_SETICON = 0x0080
	WM_GETICON = 0x007f

	WM_SETTEXT = 0x000c
	WM_GETTEXT = 0x000d
	WM_GETTEXTLENGTH = 0x000e

	WM_SETFONT = 0x0030
	WM_GETFONT = 0x0031

	WM_ERASEBKGND = 0x0014

	WM_PAINT = 0x000f

	PRF_CHECKVISIBLE = 0x0000_0001
	PRF_NONCLIENT = 0x0000_0002
	PRF_CLIENT = 0x0000_0004
	PRF_ERASEBKGND = 0x0000_0008
	PRF_CHILDREN = 0x0000_0010
	PRF_OWNED = 0x0000_0020

	WM_PRINT = 0x0317
	WM_PRINTCLIENT = 0x0318

	WM_CAPTURECHANGED = 0x0215

	MK_LBUTTON = 0x0001
	MK_RBUTTON = 0x0002
	MK_MBUTTON = 0x0010
	MK_XBUTTON1 = 0x0020
	MK_XBUTTON2 = 0x0040

	MK_CONTROL = 0x0008
	MK_SHIFT = 0x0004

	WM_LBUTTONDOWN = 0x0201
	WM_LBUTTONUP = 0x0202
	WM_LBUTTONDBLCLK = 0x0203

	WM_RBUTTONDOWN = 0x0204
	WM_RBUTTONUP = 0x0205
	WM_RBUTTONDBLCLK = 0x0206

	WM_MBUTTONDOWN = 0x0207
	WM_MBUTTONUP = 0x0208
	WM_MBUTTONDBLCLK = 0x0209

	XBUTTON1 = 0x0001
	XBUTTON2 = 0x0002

	WM_XBUTTONDOWN = 0x020b
	WM_XBUTTONUP = 0x020c
	WM_XBUTTONDBLCLK = 0x020d

	WHEEL_DELTA = 120

	WM_MOUSEWHEEL = 0x020a
	if WINVER >= WINVISTA
		WM_MOUSEHWHEEL = 0x020e
	end

	WM_MOUSEMOVE = 0x0200

	WM_SYSKEYDOWN = 0x0104
	WM_SYSKEYUP = 0x0105

	WM_SYSCHAR = 0x0106
	WM_SYSDEADCHAR = 0x0107

	WM_KEYDOWN = 0x0100
	WM_KEYUP = 0x0101

	WM_CHAR = 0x0102
	WM_DEADCHAR = 0x0103

	WM_CONTEXTMENU = 0x007b

	WM_INITMENU = 0x0116
	WM_INITMENUPOPUP = 0x0117

	WM_USER = 0x0400
	WM_APP = 0x8000

	SC_DEFAULT = 0xf160

	SC_MOVE = 0xf010
	SC_SIZE = 0xf000
	SC_MINIMIZE = 0xf020
	SC_MAXIMIZE = 0xf030
	SC_RESTORE = 0xf120
	SC_CLOSE = 0xf060

	SC_HSCROLL = 0xf080
	SC_VSCROLL = 0xf070

	SC_NEXTWINDOW = 0xf040
	SC_PREVWINDOW = 0xf050
	SC_ARRANGE = 0xf110

	SC_MOUSEMENU = 0xf090
	SC_KEYMENU = 0xf100
	SC_HOTKEY = 0xf150

	SC_TASKLIST = 0xf130
	SC_SCREENSAVE = 0xf140
	SC_MONITORPOWER = 0xf170

	SC_CONTEXTHELP = 0xf180

	(SYSCMD = {}).
		instance_variable_set(:@last, 0xf00)

	class << SYSCMD
		private :[]=, :store

		def [](key)
			(id = fetch(key, nil)) ?
				id :
				self[key] = (@last -= 1) << 4
		end
	end

	WM_SYSCOMMAND = 0x0112

	(CMD = {}).
		instance_variable_set(:@last, WM_APP)

	class << CMD
		private :[]=, :store

		def [](key)
			(id = fetch(key, nil)) ?
				id :
				self[key] = @last += 1
		end
	end

	WM_COMMAND = 0x0111

	class NMHDR < FFI::Struct
		layout \
			:hwndFrom, :pointer,
			:idFrom, :uint,
			:code, :uint
	end

	WM_NOTIFY = 0x004e

	WM_CTLCOLORBTN = 0x0135

	WM_CTLCOLORSTATIC = 0x0138

	WM_CTLCOLOREDIT = 0x0133

	WM_CTLCOLORLISTBOX = 0x0134

	WM_VKEYTOITEM = 0x002e
	WM_CHARTOITEM = 0x002f

	class DELETEITEMSTRUCT < FFI::Struct
		layout \
			:CtlType, :uint,
			:CtlID, :uint,
			:itemID, :uint,
			:hwndItem, :pointer,
			:itemData, :ulong
	end

	WM_DELETEITEM = 0x002d

	class COMPAREITEMSTRUCT < FFI::Struct
		layout \
			:CtlType, :uint,
			:CtlID, :uint,
			:hwndItem, :pointer,
			:itemID1, :uint,
			:itemData1, :ulong,
			:itemID2, :uint,
			:itemData2, :ulong,
			:dwLocaleId, :ulong
	end

	WM_COMPAREITEM = 0x0039

	WM_CTLCOLORSCROLLBAR = 0x0137

	ODT_MENU = 1
	ODT_BUTTON = 4
	ODT_STATIC = 5
	ODT_LISTBOX = 2
	ODT_COMBOBOX = 3

	class MEASUREITEMSTRUCT < FFI::Struct
		layout \
			:CtlType, :uint,
			:CtlID, :uint,
			:itemID, :uint,
			:itemWidth, :uint,
			:itemHeight, :uint,
			:itemData, :ulong
	end

	WM_MEASUREITEM = 0x002c

	ODA_DRAWENTIRE = 0x0001
	ODA_FOCUS = 0x0004
	ODA_SELECT = 0x0002

	ODS_DEFAULT = 0x0020
	ODS_GRAYED = 0x0002
	ODS_SELECTED = 0x0001
	ODS_CHECKED = 0x0008

	ODS_DISABLED = 0x0004
	ODS_INACTIVE = 0x0080
	ODS_FOCUS = 0x0010
	ODS_HOTLIGHT = 0x0040

	ODS_NOFOCUSRECT = 0x0200
	ODS_NOACCEL = 0x0100

	ODS_COMBOBOXEDIT = 0x1000

	class DRAWITEMSTRUCT < FFI::Struct
		layout \
			:CtlType, :uint,
			:CtlID, :uint,
			:itemID, :uint,
			:itemAction, :uint,
			:itemState, :uint,
			:hwndItem, :pointer,
			:hDC, :pointer,
			:rcItem, RECT,
			:itemData, :ulong
	end

	WM_DRAWITEM = 0x002b

	DLGC_WANTMESSAGE = 0x0004
	DLGC_WANTALLKEYS = 0x0004
	DLGC_WANTTAB = 0x0002
	DLGC_WANTARROWS = 0x0001
	DLGC_WANTCHARS = 0x0080

	DLGC_BUTTON = 0x2000
	DLGC_DEFPUSHBUTTON = 0x0010
	DLGC_UNDEFPUSHBUTTON = 0x0020
	DLGC_RADIOBUTTON = 0x0040
	DLGC_STATIC = 0x0100
	DLGC_HASSETSEL = 0x0008

	WM_GETDLGCODE = 0x0087

	attach_function :RegisterWindowMessage, :RegisterWindowMessageW, [
		:buffer_in
	], :uint

	DM_REPOSITION = WM_USER + 2

	DM_SETDEFID = WM_USER + 1

	DC_HASDEFID = 0x534b

	DM_GETDEFID = WM_USER + 0

	attach_function :SendMessage, :SendMessageW, [
		:pointer,
		:uint,
		:uint,
		:long
	], :long

	attach_function :PostMessage, :PostMessageW, [
		:pointer,
		:uint,
		:uint,
		:long
	], :int

	attach_function :PostQuitMessage, [
		:int
	], :void

	class MSG < FFI::Struct
		layout \
			:hwnd, :pointer,
			:message, :uint,
			:wParam, :uint,
			:lParam, :long,
			:time, :ulong,
			:pt, POINT
	end

	PM_NOREMOVE = 0x0000
	PM_REMOVE = 0x0001
	PM_NOYIELD = 0x0002

	attach_function :PeekMessage, :PeekMessageW, [
		MSG.by_ref(:out),
		:pointer,
		:uint,
		:uint,
		:uint
	], :int

	attach_function :GetMessage, :GetMessageW, [
		MSG.by_ref(:out),
		:pointer,
		:uint,
		:uint
	], :int

	attach_function :IsDialogMessage, [
		:pointer,
		MSG.by_ref(:in)
	], :int

	attach_function :TranslateAccelerator, :TranslateAcceleratorW, [
		:pointer,
		:pointer,
		MSG.by_ref(:in)
	], :int

	attach_function :TranslateMessage, [
		MSG.by_ref(:in)
	], :int

	attach_function :DispatchMessage, :DispatchMessageW, [
		MSG.by_ref(:in)
	], :long

	attach_function :CreateMenu, [

	], :pointer

	attach_function :CreatePopupMenu, [

	], :pointer

	attach_function :DestroyMenu, [
		:pointer
	], :int

	MF_BYCOMMAND = 0x0000_0000
	MF_BYPOSITION = 0x0000_0400

	MF_POPUP = 0x0000_0010
	MF_STRING = 0x0000_0000
	MF_BITMAP = 0x0000_0004
	MF_OWNERDRAW = 0x0000_0100
	MF_SEPARATOR = 0x0000_0800

	MF_MENUBARBREAK = 0x0000_0020
	MF_MENUBREAK = 0x0000_0040
	MF_RIGHTJUSTIFY = 0x0000_4000

	MF_DEFAULT = 0x0000_1000
	MF_ENABLED = 0x0000_0000
	MF_DISABLED = 0x0000_0002
	MF_GRAYED = 0x0000_0001
	MF_CHECKED = 0x0000_0008
	MF_UNCHECKED = 0x0000_0000
	MF_HILITE = 0x0000_0080
	MF_UNHILITE = 0x0000_0000

	MFT_RADIOCHECK = 0x0000_0200

	MFS_GRAYED = 0x0000_0003

	attach_function :AppendMenu, :AppendMenuW, [
		:pointer,
		:uint,
		:uint,
		:buffer_in
	], :int

	attach_function :InsertMenu, :InsertMenuW, [
		:pointer,
		:uint,
		:uint,
		:uint,
		:buffer_in
	], :int

	attach_function :ModifyMenu, :ModifyMenuW, [
		:pointer,
		:uint,
		:uint,
		:uint,
		:buffer_in
	], :int

	attach_function :GetMenuItemID, [
		:pointer,
		:int
	], :uint

	attach_function :GetSubMenu, [
		:pointer,
		:int
	], :pointer

	attach_function :RemoveMenu, [
		:pointer,
		:uint,
		:uint
	], :int

	attach_function :DeleteMenu, [
		:pointer,
		:uint,
		:uint
	], :int

	attach_function :SetMenuDefaultItem, [
		:pointer,
		:uint,
		:uint
	], :int

	GMDI_USEDISABLED = 0x0001
	GMDI_GOINTOPOPUPS = 0x0002

	attach_function :GetMenuDefaultItem, [
		:pointer,
		:uint,
		:uint
	], :uint

	attach_function :EnableMenuItem, [
		:pointer,
		:uint,
		:uint
	], :int

	attach_function :CheckMenuItem, [
		:pointer,
		:uint,
		:uint
	], :ulong

	attach_function :CheckMenuRadioItem, [
		:pointer,
		:uint,
		:uint,
		:uint,
		:uint
	], :int

	attach_function :HiliteMenuItem, [
		:pointer,
		:pointer,
		:uint,
		:uint
	], :int

	attach_function :GetMenuState, [
		:pointer,
		:uint,
		:uint
	], :uint

	MIIM_FTYPE = 0x0000_0100
	MIIM_STATE = 0x0000_0001
	MIIM_ID = 0x0000_0002
	MIIM_SUBMENU = 0x0000_0004
	MIIM_CHECKMARKS = 0x0000_0008
	MIIM_DATA = 0x0000_0020
	MIIM_STRING = 0x0000_0040
	MIIM_BITMAP = 0x0000_0080

	class MENUITEMINFO < FFI::Struct
		layout \
			:cbSize, :uint,
			:fMask, :uint,
			:fType, :uint,
			:fState, :uint,
			:wID, :uint,
			:hSubMenu, :pointer,
			:hbmpChecked, :pointer,
			:hbmpUnchecked, :pointer,
			:dwItemData, :ulong,
			:dwTypeData, :pointer,
			:cch, :uint,
			:hbmpItem, :pointer
	end

	attach_function :InsertMenuItem, :InsertMenuItemW, [
		:pointer,
		:uint,
		:int,
		MENUITEMINFO.by_ref(:in)
	], :int

	attach_function :SetMenuItemInfo, :SetMenuItemInfoW, [
		:pointer,
		:uint,
		:int,
		MENUITEMINFO.by_ref(:in)
	], :int

	attach_function :GetMenuItemInfo, :GetMenuItemInfoW, [
		:pointer,
		:uint,
		:int,
		MENUITEMINFO.by_ref
	], :int

	TPM_LEFTBUTTON = 0x0000
	TPM_RIGHTBUTTON = 0x0002

	TPM_LEFTALIGN = 0x0000
	TPM_CENTERALIGN = 0x0004
	TPM_RIGHTALIGN = 0x0008

	TPM_TOPALIGN = 0x0000
	TPM_VCENTERALIGN = 0x0010
	TPM_BOTTOMALIGN = 0x0020

	TPM_HORIZONTAL = 0x0000
	TPM_VERTICAL = 0x0040

	TPM_NONOTIFY = 0x0080
	TPM_RETURNCMD = 0x0100

	TPM_RECURSE = 0x0001

	attach_function :TrackPopupMenu, [
		:pointer,
		:uint,
		:int,
		:int,
		:int,
		:pointer,
		RECT.by_ref(:in)
	], :int

	attach_function :EndMenu, [

	], :int

	FVIRTKEY = 1
	FCONTROL = 0x08
	FSHIFT = 0x04
	FALT = 0x10

	VK_LBUTTON = 0x01
	VK_RBUTTON = 0x02
	VK_MBUTTON = 0x04
	VK_XBUTTON1 = 0x05
	VK_XBUTTON2 = 0x06

	VK_CONTROL = 0x11
	VK_SHIFT = 0x10
	VK_MENU = 0x12

	VK_LCONTROL = 0xa2
	VK_RCONTROL = 0xa3
	VK_LSHIFT = 0xa0
	VK_RSHIFT = 0xa1
	VK_LMENU = 0xa4
	VK_RMENU = 0xa5
	VK_LWIN = 0x5b
	VK_RWIN = 0x5c

	VK_F1 = 0x70
	VK_F2 = 0x71
	VK_F3 = 0x72
	VK_F4 = 0x73
	VK_F5 = 0x74
	VK_F6 = 0x75
	VK_F7 = 0x76
	VK_F8 = 0x77
	VK_F9 = 0x78
	VK_F10 = 0x79
	VK_F11 = 0x7a
	VK_F12 = 0x7b

	VK_SNAPSHOT = 0x2c
	VK_PAUSE = 0x13
	VK_CANCEL = 0x03

	VK_CAPITAL = 0x14
	VK_NUMLOCK = 0x90
	VK_SCROLL = 0x91

	VK_ESCAPE = 0x1b
	VK_RETURN = 0x0d
	VK_TAB = 0x09
	VK_SPACE = 0x20

	VK_INSERT = 0x2d
	VK_DELETE = 0x2e
	VK_BACK = 0x08

	VK_HOME = 0x24
	VK_END = 0x23
	VK_PRIOR = 0x21
	VK_NEXT = 0x22
	VK_LEFT = 0x25
	VK_RIGHT = 0x27
	VK_UP = 0x26
	VK_DOWN = 0x28

	VK_NUMPAD0 = 0x60
	VK_NUMPAD1 = 0x61
	VK_NUMPAD2 = 0x62
	VK_NUMPAD3 = 0x63
	VK_NUMPAD4 = 0x64
	VK_NUMPAD5 = 0x65
	VK_NUMPAD6 = 0x66
	VK_NUMPAD7 = 0x67
	VK_NUMPAD8 = 0x68
	VK_NUMPAD9 = 0x69
	VK_DECIMAL = 0x6e
	VK_ADD = 0x6b
	VK_SUBTRACT = 0x6d
	VK_MULTIPLY = 0x6a
	VK_DIVIDE = 0x6f

	VK_MEDIA_PLAY_PAUSE = 0xb3
	VK_MEDIA_STOP = 0xb2
	VK_MEDIA_NEXT_TRACK = 0xb0
	VK_MEDIA_PREV_TRACK = 0xb1

	VK_VOLUME_MUTE = 0xad
	VK_VOLUME_UP = 0xaf
	VK_VOLUME_DOWN = 0xae

	class ACCEL < FFI::Struct
		layout \
			:fVirt, :uchar,
			:key, :ushort,
			:cmd, :ushort
	end

	attach_function :CreateAcceleratorTable, :CreateAcceleratorTableW, [
		:pointer,
		:int
	], :pointer

	attach_function :DestroyAcceleratorTable, [
		:pointer
	], :int

	attach_function :CopyAcceleratorTable, :CopyAcceleratorTableW, [
		:pointer,
		:pointer,
		:int
	], :int

	BS_PUSHBUTTON = 0x0000_0000
	BS_DEFPUSHBUTTON = 0x0000_0001

	BS_CHECKBOX = 0x0000_0002
	BS_AUTOCHECKBOX = 0x0000_0003

	BS_3STATE = 0x0000_0005
	BS_AUTO3STATE = 0x0000_0006

	BS_RADIOBUTTON = 0x0000_0004
	BS_AUTORADIOBUTTON = 0x0000_0009

	BS_GROUPBOX = 0x0000_0007

	BS_TEXT = 0x0000_0000
	BS_BITMAP = 0x0000_0080
	BS_ICON = 0x0000_0040
	BS_OWNERDRAW = 0x0000_000b

	BS_LEFT = 0x0000_0100
	BS_CENTER = 0x0000_0300
	BS_RIGHT = 0x0000_0200

	BS_TOP = 0x0000_0400
	BS_VCENTER = 0x0000_0c00
	BS_BOTTOM = 0x0000_0800

	BS_MULTILINE = 0x0000_2000

	BS_LEFTTEXT = 0x0000_0020

	BS_FLAT = 0x0000_8000
	BS_PUSHLIKE = 0x0000_1000

	BS_NOTIFY = 0x0000_4000

	BM_SETSTYLE = 0x00f4

	BM_SETIMAGE = 0x00f7
	BM_GETIMAGE = 0x00f6

	BST_FOCUS = 0x0008
	BST_PUSHED = 0x0004
	BST_UNCHECKED = 0x0000
	BST_CHECKED = 0x0001
	BST_INDETERMINATE = 0x0002

	BM_SETSTATE = 0x00f3
	BM_GETSTATE = 0x00f2

	BM_SETCHECK = 0x00f1
	BM_GETCHECK = 0x00f0

	BM_CLICK = 0x00f5
	if WINVER >= WINVISTA
		BM_SETDONTCLICK = 0x00f8
	end

	BN_SETFOCUS = 6
	BN_KILLFOCUS = 7

	BN_CLICKED = 0
	BN_DBLCLK = 5

	SS_NOPREFIX = 0x0000_0080
	SS_ENDELLIPSIS = 0x0000_4000
	SS_PATHELLIPSIS = 0x0000_8000
	SS_WORDELLIPSIS = 0x0000_c000
	SS_EDITCONTROL = 0x0000_2000

	SS_SIMPLE = 0x0000_000b
	SS_BITMAP = 0x0000_000e
	SS_ICON = 0x0000_0003
	SS_OWNERDRAW = 0x0000_000d

	SS_LEFT = 0x0000_0000
	SS_LEFTNOWORDWRAP = 0x0000_000c
	SS_CENTER = 0x0000_0001
	SS_CENTERIMAGE = 0x0000_0200
	SS_RIGHT = 0x0000_0002
	SS_RIGHTJUST = 0x0000_0400

	SS_SUNKEN = 0x0000_1000

	SS_ETCHEDHORZ = 0x0000_0010
	SS_ETCHEDVERT = 0x0000_0011
	SS_ETCHEDFRAME = 0x0000_0012

	SS_BLACKFRAME = 0x0000_0007
	SS_GRAYFRAME = 0x0000_0008
	SS_WHITEFRAME = 0x0000_0009

	SS_BLACKRECT = 0x0000_0004
	SS_GRAYRECT = 0x0000_0005
	SS_WHITERECT = 0x0000_0006

	if WINVER >= WINXP
		SS_REALSIZECONTROL = 0x0000_0040
	end
	SS_REALSIZEIMAGE = 0x0000_0800

	SS_NOTIFY = 0x0000_0100

	STM_SETIMAGE = 0x0172
	STM_GETIMAGE = 0x0173

	STM_SETICON = 0x0170
	STM_GETICON = 0x0171

	STN_ENABLE = 2
	STN_DISABLE = 3

	STN_CLICKED = 0
	STN_DBLCLK = 1

	ES_NUMBER = 0x2000
	ES_LOWERCASE = 0x0010
	ES_UPPERCASE = 0x0008
	ES_PASSWORD = 0x0020
	ES_MULTILINE = 0x0004
	ES_WANTRETURN = 0x1000

	ES_LEFT = 0x0000
	ES_CENTER = 0x0001
	ES_RIGHT = 0x0002

	ES_AUTOHSCROLL = 0x0080
	ES_AUTOVSCROLL = 0x0040
	ES_NOHIDESEL = 0x0100
	ES_READONLY = 0x0800

	EM_SETLIMITTEXT = 0x00c5
	EM_GETLIMITTEXT = 0x00d5

	EM_SETPASSWORDCHAR = 0x00cc
	EM_GETPASSWORDCHAR = 0x00d2

	EM_SETTABSTOPS = 0x00cb
	EM_FMTLINES = 0x00c8

	EM_SETSEL = 0x00b1
	EM_GETSEL = 0x00b0

	EM_REPLACESEL = 0x00c2

	EM_SETRECT = 0x00b3
	EM_SETRECTNP = 0x00b4
	EM_GETRECT = 0x00b2

	EC_LEFTMARGIN = 0x0001
	EC_RIGHTMARGIN = 0x0002
	EC_USEFONTINFO = 0xffff

	EM_SETMARGINS = 0x00d3
	EM_GETMARGINS = 0x00d4

	EM_SETHANDLE = 0x00bc
	EM_GETHANDLE = 0x00bd

	WB_LEFT = 0
	WB_RIGHT = 1
	WB_ISDELIMITER = 2

	callback :EDITWORDBREAKPROC, [
		:buffer_in,
		:int,
		:int,
		:int
	], :int

	EM_SETWORDBREAKPROC = 0x00d0
	EM_GETWORDBREAKPROC = 0x00d1

	EM_SETMODIFY = 0x00b9
	EM_GETMODIFY = 0x00b8

	EM_CANUNDO = 0x00c6
	EM_UNDO = 0x00c7
	EM_EMPTYUNDOBUFFER = 0x00cd

	EM_SCROLL = 0x00b5
	EM_LINESCROLL = 0x00b6
	EM_SCROLLCARET = 0x00b7
	EM_GETTHUMB = 0x00be

	EM_GETLINECOUNT = 0x00ba
	EM_LINELENGTH = 0x00c1
	EM_GETLINE = 0x00c4
	EM_GETFIRSTVISIBLELINE = 0x00ce
	EM_LINEINDEX = 0x00bb
	EM_LINEFROMCHAR = 0x00c9

	EM_POSFROMCHAR = 0x00d6
	EM_CHARFROMPOS = 0x00d7

	EM_SETREADONLY = 0x00cf

	EN_ERRSPACE = 0x0500
	EN_MAXTEXT = 0x0501

	EN_SETFOCUS = 0x0100
	EN_KILLFOCUS = 0x0200

	EN_UPDATE = 0x0400
	EN_CHANGE = 0x0300

	EN_HSCROLL = 0x0601
	EN_VSCROLL = 0x0602

	LBS_USETABSTOPS = 0x0080
	LBS_MULTICOLUMN = 0x0200
	LBS_MULTIPLESEL = 0x0008
	LBS_EXTENDEDSEL = 0x0800
	LBS_WANTKEYBOARDINPUT = 0x0400
	LBS_COMBOBOX = 0x8000

	LBS_HASSTRINGS = 0x0040
	LBS_OWNERDRAWFIXED = 0x0010
	LBS_OWNERDRAWVARIABLE = 0x0020

	LBS_SORT = 0x0002

	LBS_DISABLENOSCROLL = 0x1000
	LBS_NOINTEGRALHEIGHT = 0x0100
	LBS_NODATA = 0x2000
	LBS_NOSEL = 0x4000
	LBS_NOREDRAW = 0x0004

	LBS_NOTIFY = 0x0001

	LBS_STANDARD = WS_BORDER | WS_VSCROLL | LBS_SORT | LBS_NOTIFY

	attach_function :GetListBoxInfo, [
		:pointer
	], :ulong

	DDL_DRIVES = 0x4000
	DDL_DIRECTORY = 0x0010
	DDL_EXCLUSIVE = 0x8000

	DDL_READWRITE = 0x0000
	DDL_READONLY = 0x0001
	DDL_HIDDEN = 0x0002
	DDL_SYSTEM = 0x0004
	DDL_ARCHIVE = 0x0020

	DDL_POSTMSGS = 0x2000

	attach_function :DlgDirList, :DlgDirListW, [
		:pointer,
		:buffer_inout,
		:int,
		:int,
		:uint
	], :int

	attach_function :DlgDirSelectEx, :DlgDirSelectExW, [
		:pointer,
		:buffer_out,
		:int,
		:int
	], :int

	LB_OKAY = 0
	LB_ERR = -1
	LB_ERRSPACE = -2

	LB_INITSTORAGE = 0x01a8

	LB_SETCOUNT = 0x01a7
	LB_GETCOUNT = 0x018b

	LB_ADDSTRING = 0x0180
	LB_INSERTSTRING = 0x0181
	LB_DIR = 0x018d
	LB_ADDFILE = 0x0196

	LB_DELETESTRING = 0x0182
	LB_RESETCONTENT = 0x0184

	LB_SETCURSEL = 0x0186
	LB_GETCURSEL = 0x0188

	LB_SELECTSTRING = 0x018c

	LB_FINDSTRING = 0x018f
	LB_FINDSTRINGEXACT = 0x01a2

	LB_GETTEXTLEN = 0x018a
	LB_GETTEXT = 0x0189

	LB_SETITEMDATA = 0x019a
	LB_GETITEMDATA = 0x0199

	LB_SETSEL = 0x0185
	LB_GETSEL = 0x0187

	LB_GETSELCOUNT = 0x0190
	LB_GETSELITEMS = 0x0191

	LB_SELITEMRANGEEX = 0x0183

	LB_SETLOCALE = 0x01a5
	LB_GETLOCALE = 0x01a6

	LB_SETTABSTOPS = 0x0192
	LB_SETCOLUMNWIDTH = 0x0195
	if WINVER >= WINXP
		LB_GETLISTBOXINFO = 0x01b2
	end

	LB_SETHORIZONTALEXTENT = 0x0194
	LB_GETHORIZONTALEXTENT = 0x0193

	LB_SETTOPINDEX = 0x0197
	LB_GETTOPINDEX = 0x018e

	LB_SETANCHORINDEX = 0x019c
	LB_GETANCHORINDEX = 0x019d

	LB_SETCARETINDEX = 0x019e
	LB_GETCARETINDEX = 0x019f

	LB_SETITEMHEIGHT = 0x01a0
	LB_GETITEMHEIGHT = 0x01a1

	LB_GETITEMRECT = 0x0198
	LB_ITEMFROMPOINT = 0x01a9

	LBN_ERRSPACE = -2

	LBN_SETFOCUS = 4
	LBN_KILLFOCUS = 5

	LBN_SELCHANGE = 1
	LBN_SELCANCEL = 3

	LBN_DBLCLK = 2

	CBS_SIMPLE = 0x0001
	CBS_DROPDOWN = 0x0002
	CBS_DROPDOWNLIST = 0x0003
	CBS_LOWERCASE = 0x4000
	CBS_UPPERCASE = 0x2000

	CBS_HASSTRINGS = 0x0200
	CBS_OWNERDRAWFIXED = 0x0010
	CBS_OWNERDRAWVARIABLE = 0x0020

	CBS_SORT = 0x0100

	CBS_AUTOHSCROLL = 0x0040
	CBS_DISABLENOSCROLL = 0x0800
	CBS_NOINTEGRALHEIGHT = 0x0400

	class COMBOBOXINFO < FFI::Struct
		layout \
			:cbSize, :ulong,
			:rcItem, RECT,
			:rcButton, RECT,
			:stateButton, :ulong,
			:hwndCombo, :pointer,
			:hwndItem, :pointer,
			:hwndList, :pointer
	end

	attach_function :GetComboBoxInfo, [
		:pointer,
		COMBOBOXINFO.by_ref
	], :int

	attach_function :DlgDirListComboBox, :DlgDirListComboBoxW, [
		:pointer,
		:buffer_inout,
		:int,
		:int,
		:uint
	], :int

	attach_function :DlgDirSelectComboBoxEx, :DlgDirSelectComboBoxExW, [
		:pointer,
		:buffer_out,
		:int,
		:int
	], :int

	CB_OKAY = 0
	CB_ERR = -1
	CB_ERRSPACE = -2

	CB_LIMITTEXT = 0x0141

	CB_INITSTORAGE = 0x0161

	CB_GETCOUNT = 0x0146

	CB_ADDSTRING = 0x0143
	CB_INSERTSTRING = 0x014a
	CB_DIR = 0x0145

	CB_DELETESTRING = 0x0144
	CB_RESETCONTENT = 0x014b

	CB_SETCURSEL = 0x014e
	CB_GETCURSEL = 0x0147

	CB_SELECTSTRING = 0x014d

	CB_FINDSTRING = 0x014c
	CB_FINDSTRINGEXACT = 0x0158

	CB_GETLBTEXTLEN = 0x0149
	CB_GETLBTEXT = 0x0148

	CB_SETITEMDATA = 0x0151
	CB_GETITEMDATA = 0x0150

	CB_SETEDITSEL = 0x0142
	CB_GETEDITSEL = 0x0140

	CB_SETLOCALE = 0x0159
	CB_GETLOCALE = 0x015a

	if WINVER >= WINXP
		CB_GETCOMBOBOXINFO = 0x0164
	end

	CB_SETHORIZONTALEXTENT = 0x015e
	CB_GETHORIZONTALEXTENT = 0x015d

	CB_SETTOPINDEX = 0x015c
	CB_GETTOPINDEX = 0x015b

	CB_SETITEMHEIGHT = 0x0153
	CB_GETITEMHEIGHT = 0x0154

	CB_SETDROPPEDWIDTH = 0x0160
	CB_GETDROPPEDWIDTH = 0x015f

	CB_GETDROPPEDSTATE = 0x0157
	CB_GETDROPPEDCONTROLRECT = 0x0152

	CB_SHOWDROPDOWN = 0x014f

	CB_SETEXTENDEDUI = 0x0155
	CB_GETEXTENDEDUI = 0x0156

	CBN_ERRSPACE = -1

	CBN_SETFOCUS = 3
	CBN_KILLFOCUS = 4

	CBN_EDITUPDATE = 6
	CBN_EDITCHANGE = 5

	CBN_SELCHANGE = 1
	CBN_SELENDOK = 9
	CBN_SELENDCANCEL = 10

	CBN_DBLCLK = 2

	CBN_DROPDOWN = 7
	CBN_CLOSEUP = 8

	SBS_HORZ = 0x0000
	SBS_VERT = 0x0001

	SBS_TOPALIGN = 0x0002
	SBS_BOTTOMALIGN = 0x0004
	SBS_LEFTALIGN = 0x0002
	SBS_RIGHTALIGN = 0x0004

	SBS_SIZEBOX = 0x0008
	SBS_SIZEGRIP = 0x0010

	SBS_SIZEBOXTOPLEFTALIGN = 0x0002
	SBS_SIZEBOXBOTTOMRIGHTALIGN = 0x0004

	OBJID_HSCROLL = 0xffff_fffa - 0x1_0000_0000
	OBJID_VSCROLL = 0xffff_fffb - 0x1_0000_0000
	OBJID_CLIENT = 0xffff_fffc - 0x1_0000_0000

	class SCROLLBARINFO < FFI::Struct
		layout \
			:cbSize, :ulong,
			:rcScrollBar, RECT,
			:dxyLineButton, :int,
			:xyThumbTop, :int,
			:xyThumbBottom, :int,
			:reserved, :int,

			# 0 - scroll bar itself
			# 1 - top/right arrow button
			# 2 - page up/page right region
			# 3 - scroll box
			# 4 - page down/page left region
			# 5 - bottom/left arrow button
			:rgstate, [:ulong, 6]
	end

	attach_function :GetScrollBarInfo, [
		:pointer,
		:long,
		SCROLLBARINFO.by_ref
	], :int

	SBM_ENABLE_ARROWS = 0x00e4

	SBM_SETRANGE = 0x00e2
	SBM_SETRANGEREDRAW = 0x00e6
	SBM_GETRANGE = 0x00e3

	SBM_SETPOS = 0x00e0
	SBM_GETPOS = 0x00e1

	SBM_SETSCROLLINFO = 0x00e9
	SBM_GETSCROLLINFO = 0x00ea

	if WINVER >= WINXP
		SBM_GETSCROLLBARINFO = 0x00eb
	end
end
