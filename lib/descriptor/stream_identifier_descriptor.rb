require 'bindata'

class StreamIdentifierDescriptor < BinData::Record
  TAG_ID = 0x52

  endian :big

  bit8  :descriptor_tag
  bit8  :descriptor_length
  bit8  :component_tag
  rest  :unknown
end
