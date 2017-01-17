require_relative 'common'
if __FILE__ == $0
	require_relative 'kernel32'
end

module WindowsGUI
	ffi_lib 'gdi32'
	ffi_convention :stdcall

	HGDI_ERROR = FFI::Pointer.new(-1)

	def RGB(r, g, b)
		r | (g << 8) | (b << 16)
	end

	def GetRValue(rgb)
		LOBYTE(rgb)
	end

	def GetGValue(rgb)
		LOBYTE(rgb >> 8)
	end

	def GetBValue(rgb)
		LOBYTE(rgb >> 16)
	end

	module_function :RGB, :GetRValue, :GetGValue, :GetBValue

	attach_function :CreateCompatibleDC, [
		:pointer
	], :pointer

	attach_function :DeleteDC, [
		:pointer
	], :int

	LOGPIXELSX = 88
	LOGPIXELSY = 90

	attach_function :GetDeviceCaps, [
		:pointer,
		:int
	], :int

	attach_function :CreateCompatibleBitmap, [
		:pointer,
		:int,
		:int
	], :pointer

	def DPIAwareFontHeight(pointSize)
		-MulDiv(pointSize, DPIY, 72)
	end

	module_function :DPIAwareFontHeight

	FW_DONTCARE = 0
	FW_THIN = 100
	FW_EXTRALIGHT = 200
	FW_LIGHT = 300
	FW_NORMAL = 400
	FW_MEDIUM = 500
	FW_SEMIBOLD = 600
	FW_BOLD = 700
	FW_EXTRABOLD = 800
	FW_HEAVY = 900

	DEFAULT_CHARSET = 1
	ANSI_CHARSET = 0

	OUT_DEFAULT_PRECIS = 0
	OUT_DEVICE_PRECIS = 5
	OUT_RASTER_PRECIS = 6
	OUT_OUTLINE_PRECIS = 8
	OUT_SCREEN_OUTLINE_PRECIS = 9
	OUT_PS_ONLY_PRECIS = 10
	OUT_TT_PRECIS = 4
	OUT_TT_ONLY_PRECIS = 7

	CLIP_DEFAULT_PRECIS = 0

	DEFAULT_QUALITY = 0
	DRAFT_QUALITY = 1
	PROOF_QUALITY = 2
	NONANTIALIASED_QUALITY = 3
	ANTIALIASED_QUALITY = 4
	if WINVER >= WINXP
		CLEARTYPE_QUALITY = 5
		CLEARTYPE_NATURAL_QUALITY = 6
	end

	DEFAULT_PITCH = 0
	FIXED_PITCH = 1
	VARIABLE_PITCH = 2

	FF_DONTCARE = 0 << 4
	FF_MODERN = 3 << 4
	FF_SWISS = 2 << 4
	FF_ROMAN = 1 << 4
	FF_SCRIPT = 4 << 4
	FF_DECORATIVE = 5 << 4

	class LOGFONT < FFI::Struct
		extend Util::ScopedStruct

		layout \
			:lfHeight, :long,
			:lfWidth, :long,
			:lfEscapement, :long,
			:lfOrientation, :long,
			:lfWeight, :long,
			:lfItalic, :uchar,
			:lfUnderline, :uchar,
			:lfStrikeOut, :uchar,
			:lfCharSet, :uchar,
			:lfOutPrecision, :uchar,
			:lfClipPrecision, :uchar,
			:lfQuality, :uchar,
			:lfPitchAndFamily, :uchar,
			:lfFaceName, [:ushort, 32]
	end

	attach_function :CreateFontIndirect, :CreateFontIndirectW, [
		LOGFONT.by_ref(:in)
	], :pointer

	BS_NULL = 1
	BS_SOLID = 0
	BS_HATCHED = 2
	BS_PATTERN = 3
	BS_DIBPATTERN = 5
	BS_DIBPATTERNPT = 6

	DIB_RGB_COLORS = 0
	DIB_PAL_COLORS = 1

	HS_HORIZONTAL = 0
	HS_VERTICAL = 1
	HS_FDIAGONAL = 2
	HS_BDIAGONAL = 3
	HS_CROSS = 4
	HS_DIAGCROSS = 5

	class LOGBRUSH < FFI::Struct
		extend Util::ScopedStruct

		layout \
			:lbStyle, :uint,
			:lbColor, :ulong,
			:lbHatch, :ulong
	end

	attach_function :CreateBrushIndirect, [
		LOGBRUSH.by_ref(:in)
	], :pointer

	PS_COSMETIC = 0x0000_0000
	PS_GEOMETRIC = 0x0001_0000

	PS_NULL = 5
	PS_SOLID = 0
	PS_DASH = 1
	PS_DOT = 2
	PS_DASHDOT = 3
	PS_DASHDOTDOT = 4
	PS_ALTERNATE = 8
	PS_USERSTYLE = 7
	PS_INSIDEFRAME = 6

	PS_ENDCAP_FLAT = 0x0000_0200
	PS_ENDCAP_SQUARE = 0x0000_0100
	PS_ENDCAP_ROUND = 0x0000_0000

	PS_JOIN_BEVEL = 0x0000_1000
	PS_JOIN_MITER = 0x0000_2000
	PS_JOIN_ROUND = 0x0000_0000

	class LOGPEN < FFI::Struct
		extend Util::ScopedStruct

		layout \
			:lopnStyle, :uint,
			:lopnWidth, POINT,
			:lopnColor, :ulong
	end

	attach_function :CreatePenIndirect, [
		LOGPEN.by_ref(:in)
	], :pointer

	attach_function :ExtCreatePen, [
		:ulong,
		:ulong,
		LOGBRUSH.by_ref(:in),
		:ulong,
		:pointer
	], :pointer

	attach_function :CreateRectRgn, [
		:int,
		:int,
		:int,
		:int
	], :pointer

	attach_function :CreateRoundRectRgn, [
		:int,
		:int,
		:int,
		:int,
		:int,
		:int
	], :pointer

	attach_function :CreateEllipticRgn, [
		:int,
		:int,
		:int,
		:int
	], :pointer

	ALTERNATE = 1
	WINDING = 2

	attach_function :SetPolyFillMode, [
		:pointer,
		:int
	], :int

	attach_function :GetPolyFillMode, [
		:pointer
	], :int

	attach_function :CreatePolygonRgn, [
		:pointer,
		:int,
		:int
	], :pointer

	attach_function :CreatePolyPolygonRgn, [
		:pointer,
		:pointer,
		:int,
		:int
	], :pointer

	attach_function :OffsetRgn, [
		:pointer,
		:int,
		:int
	], :int

	RGN_COPY = 5
	RGN_DIFF = 4
	RGN_AND = 1
	RGN_OR = 2
	RGN_XOR = 3

	ERROR = 0
	NULLREGION = 1
	SIMPLEREGION = 2
	COMPLEXREGION = 3

	attach_function :CombineRgn, [
		:pointer,
		:pointer,
		:pointer,
		:int
	], :int

	attach_function :GetRgnBox, [
		:pointer,
		RECT.by_ref(:out)
	], :int

	attach_function :PtInRegion, [
		:pointer,
		:int,
		:int
	], :int

	attach_function :RectInRegion, [
		:pointer,
		RECT.by_ref(:in)
	], :int

	attach_function :EqualRgn, [
		:pointer,
		:pointer
	], :int

	attach_function :FrameRgn, [
		:pointer,
		:pointer,
		:pointer,
		:int,
		:int
	], :int

	attach_function :FillRgn, [
		:pointer,
		:pointer,
		:pointer
	], :int

	attach_function :DeleteObject, [
		:pointer
	], :int

	attach_function :GetObject, :GetObjectW, [
		:pointer,
		:int,
		:pointer
	], :int

	R2_BLACK = 1
	R2_WHITE = 16

	R2_NOP = 11
	R2_NOT = 6
	R2_COPYPEN = 13
	R2_NOTCOPYPEN = 4

	R2_MERGEPEN = 15
	R2_MERGENOTPEN = 12
	R2_MERGEPENNOT = 14
	R2_NOTMERGEPEN = 2

	R2_MASKPEN = 9
	R2_MASKNOTPEN = 3
	R2_MASKPENNOT = 5
	R2_NOTMASKPEN = 8

	R2_XORPEN = 7
	R2_NOTXORPEN = 10

	attach_function :SetROP2, [
		:pointer,
		:int
	], :int

	attach_function :GetROP2, [
		:pointer
	], :int

	attach_function :SetBkColor, [
		:pointer,
		:ulong
	], :ulong

	attach_function :GetBkColor, [
		:pointer
	], :ulong

	attach_function :SetTextColor, [
		:pointer,
		:ulong
	], :ulong

	attach_function :GetTextColor, [
		:pointer
	], :ulong

	attach_function :SelectObject, [
		:pointer,
		:pointer
	], :pointer

	def UseObjects(hdc, *hgdiobjs)
		holds = []

		hgdiobjs.each { |hgdiobj|
			holds << DetonateLastError([FFI::Pointer::NULL, HGDI_ERROR], :SelectObject,
				hdc, hgdiobj
			)
		}

		yield
	ensure
		holds.each { |hgdiobj|
			SelectObject(hdc, hgdiobj)
		}
	end

	module_function :UseObjects

	AD_COUNTERCLOCKWISE = 1
	AD_CLOCKWISE = 2

	attach_function :SetArcDirection, [
		:pointer,
		:int
	], :int

	attach_function :GetArcDirection, [
		:int
	], :int

	attach_function :SaveDC, [
		:pointer
	], :int

	attach_function :RestoreDC, [
		:pointer,
		:int
	], :int

	attach_function :GetTextExtentPoint32, :GetTextExtentPoint32W, [
		:pointer,
		:buffer_in,
		:int,
		SIZE.by_ref(:out)
	], :int

	attach_function :TextOut, :TextOutW, [
		:pointer,
		:int,
		:int,
		:buffer_in,
		:int
	], :int

	attach_function :MoveToEx, [
		:pointer,
		:int,
		:int,
		POINT.by_ref(:out)
	], :int

	attach_function :LineTo, [
		:pointer,
		:int,
		:int
	], :int

	attach_function :Polyline, [
		:pointer,
		:pointer,
		:int
	], :int

	attach_function :PolylineTo, [
		:pointer,
		:pointer,
		:ulong
	], :int

	attach_function :PolyPolyline, [
		:pointer,
		:pointer,
		:pointer,
		:ulong
	], :int

	attach_function :Arc, [
		:pointer,
		:int,
		:int,
		:int,
		:int,
		:int,
		:int,
		:int,
		:int,
	], :int

	attach_function :ArcTo, [
		:pointer,
		:int,
		:int,
		:int,
		:int,
		:int,
		:int,
		:int,
		:int,
	], :int

	attach_function :AngleArc, [
		:pointer,
		:int,
		:int,
		:ulong,
		:float,
		:float
	], :int

	attach_function :PolyBezier, [
		:pointer,
		:pointer,
		:ulong
	], :int

	attach_function :PolyBezierTo, [
		:pointer,
		:pointer,
		:ulong
	], :int

	PT_MOVETO = 0x06
	PT_LINETO = 0x02
	PT_BEZIERTO = 0x04
	PT_CLOSEFIGURE = 0x01

	attach_function :PolyDraw, [
		:pointer,
		:pointer,
		:pointer,
		:int
	], :int

	attach_function :Rectangle, [
		:pointer,
		:int,
		:int,
		:int,
		:int
	], :int

	attach_function :RoundRect, [
		:pointer,
		:int,
		:int,
		:int,
		:int,
		:int,
		:int
	], :int

	attach_function :Ellipse, [
		:pointer,
		:int,
		:int,
		:int,
		:int
	], :int

	attach_function :Pie, [
		:pointer,
		:int,
		:int,
		:int,
		:int,
		:int,
		:int,
		:int,
		:int
	], :int

	attach_function :Chord, [
		:pointer,
		:int,
		:int,
		:int,
		:int,
		:int,
		:int,
		:int,
		:int
	], :int

	attach_function :Polygon, [
		:pointer,
		:pointer,
		:int
	], :int

	attach_function :PolyPolygon, [
		:pointer,
		:pointer,
		:pointer,
		:int
	], :int
end
