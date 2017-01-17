require_relative 'common'

module WindowsGUI
	ffi_lib FFI::Library::LIBC
	ffi_convention :cdecl

	attach_function :wcslen, [
		:buffer_in
	], :uint
end
