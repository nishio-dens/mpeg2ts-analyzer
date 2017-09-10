require 'bindata'

class ProgramAssociationTable < BinData::Record
  # Constants
  class PatRecord < BinData::Record
    RECORD_LENGTH = 4

    endian :big

    bit16 :program_number
    bit3  :reserved_111

    struct :network, onlyif: -> { program_number == 0 } do
      bit13 :network_pid
    end

    struct :program_map, onlyif: -> { program_number != 0 } do
      bit13 :program_map_pid
    end
  end

  # Structure
  endian :big

  bit8  :table_id
  bit1  :section_syntax_indicator
  bit1  :reserved_0
  bit2  :reserved_1
  bit12 :section_length
  bit16 :transport_stream_id
  bit2  :reserved_2
  bit5  :version_number
  bit1  :current_next_indicator
  bit8  :section_number
  bit8  :last_section_number
  string :pat_data, length: -> { section_length - 9 } # 9 = 5Bytes(transport_stream_id .. last_section_number) + 4bytes(CRC)
  bit32 :crc_32
  rest  :stuffing_byte

  def pat_records
    pat_data
      .chars
      .each_slice(PatRecord::RECORD_LENGTH)
      .map { |v| StringIO.new(v.join) }
      .map { |data| PatRecord.read(data) }
  end
end
