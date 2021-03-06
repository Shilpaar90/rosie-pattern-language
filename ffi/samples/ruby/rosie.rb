# coding: utf-8
#  -*- Mode: Ruby; -*-                                              
# 
#  rosie.rb
# 
#  © Copyright IBM Corporation 2016, 2017.
#  LICENSE: MIT License (https://opensource.org/licenses/mit-license.html)
#  AUTHOR: Jamie A. Jennings

# gem install ffi
require 'ffi'

module Rosie

  class CString < FFI::Struct
    layout :len, :uint32,
           :ptr, :pointer
  end

  class CStringArray < FFI::Struct
    layout :n, :uint32,
           :ptr, :pointer
  end

  extend FFI::Library
  ffi_convention :stdcall       # needed?
  ffi_lib_flags :now            # required so other shared objects can resolve names
  ffi_lib "./librosie.so"

  attach_function 'rosieL_clear_environment', [:pointer, CString], CStringArray.val
  attach_function 'rosieL_match', [:pointer, CString, CString], CStringArray.val
  attach_function 'rosieL_get_environment', [:pointer, CString], CStringArray.val
  attach_function 'rosieL_load_manifest', [:pointer, CString], CStringArray.val
  attach_function 'rosieL_load_file', [:pointer, CString], CStringArray.val
  attach_function 'rosieL_configure_engine', [:pointer, CString], CStringArray.val
  attach_function 'rosieL_load_string', [:pointer, CString], CStringArray.val
  attach_function 'rosieL_info', [:pointer], CStringArray.val
  attach_function 'rosieL_inspect_engine', [:pointer], CStringArray.val
  attach_function 'rosieL_eval', [:pointer, CString, CString], CStringArray.val
  attach_function 'rosieL_eval_file', [:pointer, CString, CString, CString, CString], CStringArray.val
  attach_function 'rosieL_match_file', [:pointer, CString, CString, CString, CString], CStringArray.val
  attach_function 'rosieL_set_match_exp_grep_TEMPORARY', [:pointer, CString], CStringArray.val

  attach_function 'rosieL_initialize', [ CString, CStringArray ], :pointer
  attach_function 'rosieL_finalize', [ :pointer ], :void

  attach_function 'rosieL_free_string', [ CString.val ], :void
  attach_function 'rosieL_free_string_ptr', [ CString ], :void
  attach_function 'rosieL_free_stringArray', [ CStringArray.val ], :void
  attach_function 'rosieL_free_stringArray_ptr', [ CStringArray ], :void

  def Rosie.to_CString(str)
    instance = CString.new
    instance[:len] = str.length
    instance[:ptr] = FFI::MemoryPointer.from_string(str)
    instance
  end

  def Rosie.from_CStringArray(retval)
    ptr_array = FFI::Pointer.new(FFI::Pointer, retval[:ptr]).read_array_of_pointer(retval[:n])
    strings = []
    for i in 0..(retval[:n]-1) do
      cstr = Rosie::CString.new ptr_array[i]
      strings[i] = cstr[:ptr].read_string(cstr[:len])
    end
    return strings
  end

  # N.B. (1) jruby reports that read_string_length is not a method of
  # FFI::Pointer, AND (2) it appears that read_string accepts a length argument.
  def Rosie.print_string_array(retval)
    print "Number of strings returned from api call is: ", retval[:n], "\n"
    ptr_array = FFI::Pointer.new(FFI::Pointer, retval[:ptr]).read_array_of_pointer(retval[:n])
    for i in 0..(retval[:n]-1) do
      str = Rosie::CString.new ptr_array[i]
      print "  [", i, "] len=", str[:len], ", ptr=", str[:ptr].read_string(str[:len]), "\n"
    end
  end

end  #module Rosie

