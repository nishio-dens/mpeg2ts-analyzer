require 'bindata'

class ProgramMapTable < BinData::Record
  # Constants

  module STREAM_TYPE
    RESERVED                 = 0x00
    ISO_IEC_11172_VIDEO      = 0x01
    H262_OR_ISO_IEC_13818_2_OR_ISO_IEC_11172_2_VIDEO_STREAM = 0x02
    ISO_IEC_11172_Audio      = 0x03
    ISO_IEC_13818_3_AUDIO    = 0x04
    H222_PRIVATE_SECTION     = 0x05
    H222_PRIVATE_DATA        = 0x06
    ISO_IEC_13522_MHEG       = 0x07
    H222_ANNEX_A_DSM_CC      = 0x08
    H222_1                   = 0x09
    ISO_IEC_13818_6_TYPE_A   = 0x0a
    ISO_IEC_13818_6_TYPE_B   = 0x0b
    ISO_IEC_13818_6_TYPE_C   = 0x0c
    ISO_IEC_13818_6_TYPE_D   = 0x0d
    H222_AUXILIARY           = 0x0e
    ISO_IEC_13818_7_AUDIO    = 0x0f
    ISO_IEC_14496_2_VISUAL   = 0x10
    ISO_IEC_14496_3_AUDIO    = 0x11
    ISO_IEC_14496_1_STREAM_1 = 0x12
    ISO_IEC_14496_1_STREAM_2 = 0x13
    SYNC_DOWNLOAD_PROTOCOL   = 0x14
    H222_RESERVED            = (0x15..0x7f)
    USER_PRIVATE             = (0x80..0xff)
  end

  class StreamInfo < BinData::Record
    endian :big

    bit8  :stream_type
    bit3  :reserved_0
    bit13 :elementary_pid
    bit4  :reserved_1
    bit12 :es_info_length
    rest :_descriptor

    def length
      # 5bytes = (8 + 3 + 13 + 4 + 12) bits
      5 + es_info_length
    end

    def descriptor
      DescriptorParser.parse(_descriptor[0..(es_info_length - 1)])
    end

    def descriptor_bytes
      descriptor.bytes.map { |v| "%02x" % v }.join(" ")
    end

    def video?
      stream_type == STREAM_TYPE::H262_OR_ISO_IEC_13818_2_OR_ISO_IEC_11172_2_VIDEO_STREAM
    end

    def audio?
      stream_type == STREAM_TYPE::ISO_IEC_13818_7_AUDIO
    end
  end

  # Structure
  endian :big

  bit8  :table_id
  bit1  :section_syntax_indicator
  bit1  :reserved_0
  bit2  :reserved_1
  bit12 :section_length
  bit16 :program_number
  bit2  :reserved_2
  bit5  :version_number
  bit1  :current_next_indicator
  bit8  :section_number
  bit8  :last_section_number
  bit3  :reserved_3
  bit13 :pcr_pid
  bit4  :reserved_4
  bit12 :program_info_length
  string :_descriptor, length: :program_info_length
  string :pmt_data, length: -> { section_length - program_info_length - 13 } # 13 = 9Bytes(program_number .. program_info_length) + 4bytes(CRC)
  bit32 :crc_32

  def descriptor
    DescriptorParser.parse(_descriptor)
  end

  def pmt_records
    records = []
    pointer = 0
    data = pmt_data
    while true
      next_bytes = pmt_data[pointer..-1]
      break if next_bytes.nil?
      record = StreamInfo.read(StringIO.new(next_bytes))
      records << record
      pointer += record.length
    end

    records
  end
end
