require 'ffi'

WINGUI_VISUAL_STYLES = true unless defined?(WINGUI_VISUAL_STYLES)
WINGUI_DPI_AWARE = true unless defined?(WINGUI_DPI_AWARE)

module WinGUI
	extend FFI::Library

	VERSION = '1.0.2'

	module Util
		def FormatException(ex)
			str, trace = ex.to_s, ex.backtrace

			str << "\n\n-- backtrace --\n\n" << trace.join("\n") if trace

			str
		end

		module_function :FormatException

		Id2Ref = {}

		def Id2RefTrack(object)
			Id2Ref[object.object_id] = object

			ObjectSpace.define_finalizer(object, -> id {
				Id2Ref.delete(id)
			})
		end

		module_function :Id2RefTrack

		unless FFI::Struct.respond_to?(:by_ref)
			class << FFI::Struct
				def by_ref(*args)
					FFI::Type::Builtin::POINTER
				end
			end
		end

		module ScopedStruct
			def new(*args)
				raise ArgumentError, 'Cannot accept both arguments and a block' if
					args.length > 0 && block_given?

				struct = super

				return struct unless block_given?

				begin
					yield struct
				ensure
					struct.pointer.free

					p "Native memory for #{struct} freed" if $DEBUG
				end

				nil
			end
		end
	end

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

	module_function :MAKEWORD, :LOBYTE, :HIBYTE

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

	module_function :MAKELONG, :LOWORD, :HIWORD, :LOSHORT, :HISHORT

	def L(str)
		(str << "\0").encode!('utf-16le')
	end

	def PWSTR(wstr)
		raise 'Invalid Unicode string' unless
			wstr.encoding == Encoding::UTF_16LE && wstr[-1] == L('')

		ptr = FFI::MemoryPointer.new(:ushort, wstr.length).
			put_bytes(0, wstr)

		return ptr unless block_given?

		begin
			yield ptr
		ensure
			ptr.free

			p "Native copy of '#{wstr[0...-1].encode($0.encoding)}' freed" if $DEBUG
		end

		nil
	end

	module_function :L, :PWSTR

	APPNAME = L(File.basename($0, '.rbw'))

	class POINT < FFI::Struct
		extend Util::ScopedStruct

		layout \
			:x, :long,
			:y, :long
	end

	class SIZE < FFI::Struct
		extend Util::ScopedStruct

		layout \
			:cx, :long,
			:cy, :long
	end

	class RECT < FFI::Struct
		extend Util::ScopedStruct

		layout \
			:left, :long,
			:top, :long,
			:right, :long,
			:bottom, :long
	end
end

if __FILE__ == $0
	puts WinGUI::VERSION
end
