if __FILE__ == $0
	require_relative 'common'
end

module WindowsGUI
	ffi_lib FFI::Library::LIBC
	ffi_convention :cdecl

	attach_function :windows_gui_wcslen, :wcslen, [
		:buffer_in
	], :size_t
end
