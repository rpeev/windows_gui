if __FILE__ == $0
	require_relative 'common'
	require_relative 'libc'
end

module WindowsGUI
	ffi_lib 'kernel32'
	ffi_convention :stdcall

	attach_function :SetLastError, [
		:ulong
	], :void

	attach_function :GetLastError, [

	], :ulong

	class OSVERSIONINFOEX < FFI::Struct
		layout \
			:dwOSVersionInfoSize, :ulong,
			:dwMajorVersion, :ulong,
			:dwMinorVersion, :ulong,
			:dwBuildNumber, :ulong,
			:dwPlatformId, :ulong,
			:szCSDVersion, [:ushort, 128],
			:wServicePackMajor, :ushort,
			:wServicePackMinor, :ushort,
			:wSuiteMask, :ushort,
			:wProductType, :uchar,
			:wReserved, :uchar
	end

	# TODO: GetVersionEx is deprecated and will report WIN8 on later Windows versions
	# unless a manifest file is used
	# https://msdn.microsoft.com/en-us/library/windows/desktop/dn481241.aspx
	attach_function :GetVersionEx, :GetVersionExW, [
		OSVERSIONINFOEX.by_ref
	], :int

	OSVERSION = OSVERSIONINFOEX.new

	at_exit { OSVERSION.pointer.free }

	OSVERSION[:dwOSVersionInfoSize] = OSVERSION.size
	DetonateLastError(0, :GetVersionEx,
		OSVERSION
	)

	NTDDI_WIN2K = 0x0500_0000

	NTDDI_WIN2KSP1 = 0x0500_0100
	NTDDI_WIN2KSP2 = 0x0500_0200
	NTDDI_WIN2KSP3 = 0x0500_0300
	NTDDI_WIN2KSP4 = 0x0500_0400

	NTDDI_WINXP = 0x0501_0000

	NTDDI_WINXPSP1 = 0x0501_0100
	NTDDI_WINXPSP2 = 0x0501_0200
	NTDDI_WINXPSP3 = 0x0501_0300
	NTDDI_WINXPSP4 = 0x0501_0400

	NTDDI_WS03 = 0x0502_0000

	NTDDI_WS03SP1 = 0x0502_0100
	NTDDI_WS03SP2 = 0x0502_0200
	NTDDI_WS03SP3 = 0x0502_0300
	NTDDI_WS03SP4 = 0x0502_0400

	NTDDI_VISTA = 0x0600_0000

	NTDDI_VISTASP1 = 0x0600_0100
	NTDDI_VISTASP2 = 0x0600_0200
	NTDDI_VISTASP3 = 0x0600_0300
	NTDDI_VISTASP4 = 0x0600_0400

	NTDDI_WS08 = NTDDI_VISTASP1

	NTDDI_WS08SP2 = NTDDI_VISTASP2
	NTDDI_WS08SP3 = NTDDI_VISTASP3
	NTDDI_WS08SP4 = NTDDI_VISTASP4

	NTDDI_WIN7 = 0x0601_0000

	NTDDI_WIN8 = 0x0602_0000
	NTDDI_WINBLUE = 0x0603_0000

	NTDDI_WIN10 = 0x0A00_0000
	NTDDI_WIN10_TH2 = 0x0A00_0001
	NTDDI_WIN10_RS1 = 0x0A00_0002

	NTDDI_VERSION = MAKELONG(
		MAKEWORD(OSVERSION[:wServicePackMinor], OSVERSION[:wServicePackMajor]),
		MAKEWORD(OSVERSION[:dwMinorVersion], OSVERSION[:dwMajorVersion])
	)

	WIN2K = 0x0500
	WINXP = 0x0501
	WINVISTA = 0x0600
	WIN7 = 0x0601
	WIN8 = 0x0602
	WINBLUE = 0x0603
	WIN10 = 0x0A00

	WINVER = HIWORD(NTDDI_VERSION)

	WINNAME = case WINVER
	when WIN2K; 'WIN2K (Windows 2000)'
	when WINXP; 'WINXP (Windows XP)'
	when WINVISTA; 'WINVISTA (Windows Vista)'
	when WIN7; 'WIN7 (Windows 7)'
	when WIN8; 'WIN8 (Windows 8)'
	when WINBLUE; 'WINBLUE (Windows 8.1)'
	when WIN10; 'WIN10 (Windows 10)'
	else
		'unknown Windows version'
	end

	def TARGETVER(version, message)
		version = MAKELONG(0x0000, version) if version < 0xffff

		exit(-1) if NTDDI_VERSION < version &&
			MessageBox(nil,
				message,
				APPNAME,
				MB_YESNO | MB_ICONERROR | MB_DEFBUTTON2
			) == IDNO
	end

	module_function \
		:TARGETVER

	attach_function :GetModuleHandle, :GetModuleHandleW, [
		:buffer_in
	], :pointer

	attach_function :LoadLibrary, :LoadLibraryW, [
		:buffer_in
	], :pointer

	attach_function :FreeLibrary, [
		:pointer
	], :int

	if WINVER >= WINXP
		class ACTCTX < FFI::Struct
			layout \
				:cbSize, :ulong,
				:dwFlags, :ulong,
				:lpSource, :pointer,
				:wProcessorArchitecture, :ushort,
				:wLangId, :ushort,
				:lpAssemblyDirectory, :pointer,
				:lpResourceName, :pointer,
				:lpApplicationName, :pointer,
				:hModule, :pointer
		end

		attach_function :CreateActCtx, :CreateActCtxW, [
			ACTCTX.by_ref
		], :pointer

		attach_function :ReleaseActCtx, [
			:pointer
		], :void

		attach_function :ActivateActCtx, [
			:pointer,
			:pointer
		], :int

		attach_function :DeactivateActCtx, [
			:ulong,
			:ulong
		], :int

		COMMON_CONTROLS_ACTCTX = {
			handle: INVALID_HANDLE_VALUE,
			cookie: FFI::MemoryPointer.new(:ulong),
			activated: false
		}

		at_exit {
			DeactivateActCtx(0, COMMON_CONTROLS_ACTCTX[:cookie].get_ulong(0)) if
				COMMON_CONTROLS_ACTCTX[:activated]

			ReleaseActCtx(COMMON_CONTROLS_ACTCTX[:handle]) unless
				COMMON_CONTROLS_ACTCTX[:handle] == INVALID_HANDLE_VALUE

			COMMON_CONTROLS_ACTCTX[:cookie].free unless
				COMMON_CONTROLS_ACTCTX[:cookie] == FFI::Pointer::NULL

			COMMON_CONTROLS_ACTCTX[:handle] = INVALID_HANDLE_VALUE
			COMMON_CONTROLS_ACTCTX[:cookie] = FFI::Pointer::NULL
			COMMON_CONTROLS_ACTCTX[:activated] = false

			STDERR.puts "Visual styles cleanup (COMMON_CONTROLS_ACTCTX: #{COMMON_CONTROLS_ACTCTX})" if $DEBUG
		}
	end

	def EnableVisualStyles
		return unless WINVER >= WINXP

		raise 'Visual styles already enabled' if
			COMMON_CONTROLS_ACTCTX[:activated]

		manifest = "#{ENV['TEMP']}/windows_gui.manifest"

		File.open(manifest, 'w:utf-8') { |file|
			file << <<-XML
<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<assembly xmlns='urn:schemas-microsoft-com:asm.v1' manifestVersion='1.0'>
	<dependency>
		<dependentAssembly>
<assemblyIdentity
	type='Win32'
	name='Microsoft.Windows.Common-Controls'
	version='6.0.0.0'
	processorArchitecture='*'
	publicKeyToken='6595b64144ccf1df'
	language='*'
/>
		</dependentAssembly>
	</dependency>
</assembly>
			XML
		}

		UsingFFIStructs(ACTCTX.new) { |ac|
			ac[:cbSize] = ac.size

			UsingFFIMemoryPointers(PWSTR(L(manifest))) { |source|
				ac[:lpSource] = source

				COMMON_CONTROLS_ACTCTX[:handle] =
					DetonateLastError(INVALID_HANDLE_VALUE, :CreateActCtx,
						ac
					)
			}
		}

		DetonateLastError(0, :ActivateActCtx,
			COMMON_CONTROLS_ACTCTX[:handle], COMMON_CONTROLS_ACTCTX[:cookie]
		) {
			ReleaseActCtx(COMMON_CONTROLS_ACTCTX[:handle])
			COMMON_CONTROLS_ACTCTX[:handle] = INVALID_HANDLE_VALUE
		}

		COMMON_CONTROLS_ACTCTX[:activated] = true

		STDERR.puts "Visual styles init (COMMON_CONTROLS_ACTCTX: #{COMMON_CONTROLS_ACTCTX})" if $DEBUG
	end

	module_function \
		:EnableVisualStyles

	EnableVisualStyles() if WINDOWS_GUI_VISUAL_STYLES

	attach_function :MulDiv, [
		:int,
		:int,
		:int
	], :int
end
