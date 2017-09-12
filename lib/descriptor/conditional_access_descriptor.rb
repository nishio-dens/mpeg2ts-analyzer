require 'bindata'

class ConditionalAccessDescriptor < BinData::Record
  TAG_ID = 0x09

  endian :big

  bit8  :descriptor_tag
  bit8  :descriptor_length
  bit16 :conditional_access_method_identifier
  bit3  :reserved_111
  bit13 :conditional_access_pid
  rest  :private_data
end
