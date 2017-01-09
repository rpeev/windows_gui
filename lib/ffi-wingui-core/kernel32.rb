require_relative 'common'

module WinGUI
	ffi_lib 'kernel32'
	ffi_convention :stdcall

	attach_function :SetLastError, [
		:ulong
	], :void

	attach_function :GetLastError, [

	], :ulong

	def Detonate(on, name, *args)
		raise "#{name} failed" if
			(failed = [*on].include?(result = send(name, *args)))

		result
	ensure
		yield failed if block_given?
	end

	def DetonateLastError(on, name, *args)
		raise "#{name} failed (last error: #{GetLastError()})" if
			(failed = [*on].include?(result = send(name, *args)))

		result
	ensure
		yield failed if block_given?
	end

	module_function :Detonate, :DetonateLastError

	class OSVERSIONINFOEX < FFI::Struct
		extend Util::ScopedStruct

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

	attach_function :GetVersionEx, :GetVersionExW, [
		OSVERSIONINFOEX.by_ref
	], :int

	OSVERSION = OSVERSIONINFOEX.new.tap { |ovi|
		at_exit { OSVERSION.pointer.free }

		ovi[:dwOSVersionInfoSize] = ovi.size

		DetonateLastError(0, :GetVersionEx,
			ovi
		)
	}

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

	NTDDI_VERSION = MAKELONG(
		MAKEWORD(OSVERSION[:wServicePackMinor], OSVERSION[:wServicePackMajor]),
		MAKEWORD(OSVERSION[:dwMinorVersion], OSVERSION[:dwMajorVersion])
	)

	WIN2K = 0x0500
	WINXP = 0x0501
	WINVISTA = 0x0600
	WIN7 = 0x0601

	WINVER = HIWORD(NTDDI_VERSION)

	def TARGETVER(version, message)
		version = MAKELONG(0x0000, version) if version < 0xffff

		exit(-1) if NTDDI_VERSION < version &&
			MessageBox(nil,
				message,
				APPNAME,
				MB_YESNO | MB_ICONERROR | MB_DEFBUTTON2
			) == IDNO
	end

	module_function :TARGETVER

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
			extend Util::ScopedStruct

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

			COMMON_CONTROLS_ACTCTX[:cookie].free
		}
	end

	def EnableVisualStyles
		return unless WINVER >= WINXP

		raise 'Visual styles already enabled' if
			COMMON_CONTROLS_ACTCTX[:activated]

		manifest = "#{ENV['TEMP']}/Ruby.FFI.WinGUI.Common-Controls.manifest"

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

		ACTCTX.new { |ac|
			ac[:cbSize] = ac.size

			PWSTR(L(manifest)) { |source|
				ac[:lpSource] = source

				COMMON_CONTROLS_ACTCTX[:handle] =
					DetonateLastError(INVALID_HANDLE_VALUE, :CreateActCtx,
						ac
					)
			}
		}

		DetonateLastError(0, :ActivateActCtx,
			COMMON_CONTROLS_ACTCTX[:handle], COMMON_CONTROLS_ACTCTX[:cookie]
		) { |failed|
			next unless failed

			ReleaseActCtx(COMMON_CONTROLS_ACTCTX[:handle])
			COMMON_CONTROLS_ACTCTX[:handle] = INVALID_HANDLE_VALUE
		}

		COMMON_CONTROLS_ACTCTX[:activated] = true
	end

	module_function :EnableVisualStyles

	EnableVisualStyles() if WINGUI_VISUAL_STYLES

	attach_function :MulDiv, [
		:int,
		:int,
		:int
	], :int
end
