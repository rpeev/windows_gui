require 'weakref'
require 'ffi'

WINDOWS_GUI_VERSION = '4.0.3'

WINDOWS_GUI_VISUAL_STYLES = true unless defined?(WINDOWS_GUI_VISUAL_STYLES)
WINDOWS_GUI_DPI_AWARE = true unless defined?(WINDOWS_GUI_DPI_AWARE)

module WindowsGUI
	extend FFI::Library

	def FormatException(ex)
		str, trace = ex.to_s, ex.backtrace

		str << "\n\n-- backtrace --\n\n" << trace.join("\n") if trace

		str
	end

	Id2Ref = {}

	def Id2RefTrack(obj)
		Id2Ref[oid = obj.object_id] = WeakRef.new(obj)

		STDERR.puts "Object id #{oid} of #{obj} stored in Id2Ref track hash" if $DEBUG

		ObjectSpace.define_finalizer(obj, -> id {
			Id2Ref.delete(id)

			STDERR.puts "Object id #{id} deleted from Id2Ref track hash" if $DEBUG
		})

		oid
	end

	def UsingFFIStructs(*structs)
		yield(*structs)
	ensure
		structs.each { |struct|
			struct.pointer.free

			STDERR.puts "#{struct} freed" if $DEBUG
		}
	end

	def UsingFFIMemoryPointers(*ptrs)
		yield(*ptrs)
	ensure
		ptrs.each { |ptr|
			ptr.free

			STDERR.puts "#{ptr} freed" if $DEBUG
		}
	end

	def Detonate(on, name, *args)
		result = send(name, *args)
		failed = [*on].include?(result)

		raise "#{name} failed (result: #{result})" if failed

		result
	ensure
		yield result if failed && block_given?
	end

	# TODO: GetLastError always returns 0
	def DetonateLastError(on, name, *args)
		result = send(name, *args)
		failed = [*on].include?(result)
		last_error = 0

		raise "#{name} failed (last error: #{last_error = GetLastError()})" if failed

		result
	ensure
		yield result, last_error if failed && block_given?
	end

	module_function \
		:FormatException,
		:Id2RefTrack,
		:UsingFFIStructs,
		:UsingFFIMemoryPointers,
		:Detonate,
		:DetonateLastError

	INVALID_HANDLE_VALUE = FFI::Pointer.new(-1)

	def MAKEWORD(lobyte, hibyte)
		(lobyte & 0xff) | ((hibyte & 0xff) << 8)
	end

	def LOBYTE(word)
		word & 0xff
	end

	def HIBYTE(word)
		(word >> 8) & 0xff
	end

	def MAKELONG(loword, hiword)
		(loword & 0xffff) | ((hiword & 0xffff) << 16)
	end

	def LOWORD(long)
		long & 0xffff
	end

	def HIWORD(long)
		(long >> 16) & 0xffff
	end

	def LOSHORT(long)
		((loshort = LOWORD(long)) > 0x7fff) ? loshort - 0x1_0000 : loshort
	end

	def HISHORT(long)
		((hishort = HIWORD(long)) > 0x7fff) ? hishort - 0x1_0000 : hishort
	end

	module_function \
		:MAKEWORD,
		:LOBYTE,
		:HIBYTE,
		:MAKELONG,
		:LOWORD,
		:HIWORD,
		:LOSHORT,
		:HISHORT

	def L(str)
		(str << "\0").encode!('utf-16le')
	end

	def PWSTR(wstr)
		raise 'Invalid Unicode string' unless
			wstr.encoding == Encoding::UTF_16LE && wstr[-1] == L('')

		FFI::MemoryPointer.new(:ushort, wstr.length).
			put_bytes(0, wstr)
	end

	module_function \
		:L,
		:PWSTR

	APPNAME = L(File.basename($0, '.rbw'))

	class POINT < FFI::Struct
		layout \
			:x, :long,
			:y, :long
	end

	class SIZE < FFI::Struct
		layout \
			:cx, :long,
			:cy, :long
	end

	class RECT < FFI::Struct
		layout \
			:left, :long,
			:top, :long,
			:right, :long,
			:bottom, :long
	end
end
