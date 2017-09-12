class DescriptorParser
  module DESCRIPTOR
    CONDITIONAL_ACCESS_DESCRIPTOR = 0x09
    STREAM_IDENTIFIER_DESCRIPTOR  = 0x52
  end

  def self.parse(data_bytes)
    tag = data_bytes.bytes[0]
    case tag
    when DESCRIPTOR::CONDITIONAL_ACCESS_DESCRIPTOR
      ConditionalAccessDescriptor.read(StringIO.new(data_bytes))
    when DESCRIPTOR::STREAM_IDENTIFIER_DESCRIPTOR
      StreamIdentifierDescriptor.read(StringIO.new(data_bytes))
    else
      puts "Unknown Descriptor. Tag: #{tag}"
    end
  end
end
