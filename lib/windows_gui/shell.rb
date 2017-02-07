if __FILE__ == $0
	require_relative 'common'
	require_relative 'libc'
end

module WindowsGUI
	ffi_lib 'shell32'
	ffi_convention :stdcall

	SE_ERR_FNF = 2
	SE_ERR_PNF = 3
	SE_ERR_ACCESSDENIED = 5
	SE_ERR_OOM = 8
	SE_ERR_DLLNOTFOUND = 32
	SE_ERR_SHARE = 26
	SE_ERR_ASSOCINCOMPLETE = 27
	SE_ERR_DDETIMEOUT = 28
	SE_ERR_DDEFAIL = 29
	SE_ERR_DDEBUSY = 30
	SE_ERR_NOASSOC = 31

	attach_function :ShellExecute, :ShellExecuteW, [
		:pointer,
		:buffer_in,
		:buffer_in,
		:buffer_in,
    :buffer_in,
		:int
	], :int
end
