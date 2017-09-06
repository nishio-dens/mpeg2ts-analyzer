require 'bindata'

# For more detail to learn about TS Packet, refer to the INTERNATIONAL STANDARD ISO-13818-1.
class TsPacket < BinData::Record
  # Constants

  # MPEG-2 Standard TS Packet size is 188bytes, but 192/204 bytes packet is exist in real world.
  TS_PACKET_SIZE = 188 # bytes
  TS_HEADER_SIZE = 4 # bytes
  TS_PAYLOAD     = TS_PACKET_SIZE - TS_HEADER_SIZE # 144 bytes

  TS_PACKET_START_CODE = 0x47

  module MPEG_TS_PACKET_TYPE
    PAT      = 0x0000 # Program Association Table
    CAT      = 0x0001 # Conditional Access Table
    PMT      = 0x0002 # Program Map Table
    RESERVED = (0x0003..0x000F)
    # 0x0010 - 0x1FFE User defined
    NULL     = 0x1fff # Null Packet
  end

  # ARIB PID
  module ARIB_PACKET_TYPE
    include MPEG_TS_PACKET_TYPE

    NIT                 = 0x0010 # Network Information Table
    SDT_BAT             = 0x0011 # Service Description Table
    EIT                 = 0x0012 # Event Information Table (For EPG)
    RST                 = 0x0013 # Running Status Table
    TDT_TOT             = 0x0014 # Time Date Table / Time Offset Table for current time information
    DCT                 = 0x0017 # Download Control Table
    DIT                 = 0x001E # Discontinuity Information Table
    SDTT                = 0x001F # Selection Information Table
    LIT                 = 0x0020 # Local Event Information Table
    ERT                 = 0x0021 # Event Relation Table
    PCAT                = 0x0022 # Partial Content Announcement Table
    SDTT2               = 0x0023 # Selection Information Table / Software download
    BIT                 = 0x0024 # Broadcaster Information Table (for EPG)
    NBIT_LDT            = 0x0025 # Network Board Information Table / Linked Description Table
    EIT2                = 0x0026 # Event Information Table (For EPG)
    EIT3                = 0x0027 # Event Information Table (For EPG)
    NIT_ACTUAL          = 0x0040
    NIT_OTHER           = 0x0041
    SDT_ACTUAL          = 0x0042
    SDT_OTHER           = 0x0046
    BAT                 = 0x004A
    EIT_ACTUAL          = 0x004E
    EIT_OTHER           = 0x004F
    EIT_D8_ACTUAL1      = (0x0050..0x005f)
    EIT_D8_OTHER1       = (0x0060..0x006f)
    TDT                 = 0x0070
    RST2                = 0x0071
    ST                  = 0x0072
    TOT                 = 0x0073
    PCAT2               = 0x00C2
    BIT_OPTIONAL        = 0x00C4
    NBIT_OPTIONAL_BODY  = 0x00C5
    NBIT_GBI            = 0x00C6
    LDT                 = 0x00C7
  end

  module ADAPTATION_FIELD_CODE
    RESERVED                     = 0b00
    PAYLOAD_ONLY                 = 0b01
    ADAPTATION_FIELD_ONLY        = 0b10
    ADAPTATION_FIELD_AND_PAYLOAD = 0b11
  end

  PES_START_CODE = [0x00, 0x00, 0x01]


  # TS Packet Structure
  endian :big

  # TS Header
  bit8  :sync_byte
  bit1  :transport_error_indicator
  bit1  :payload_unit_start_indicator
  bit1  :transport_priority
  bit13 :pid
  bit2  :transport_scrambling_control
  bit2  :adaptation_field_control
  bit4  :continuity_counter
  string :adaptation_field_and_payload, length: TS_PAYLOAD


  def valid?
    sync_valid? && !transport_error?
  end

  def sync_valid?
    sync_byte == TS_PACKET_START_CODE
  end

  def transport_error?
    transport_error_indicator == 1
  end

  def payload_start?
    payload_unit_start_indicator == 1
  end

  def mpeg_ts_packet_type
    MPEG_TS_PACKET_TYPE.constants.find { |t| MPEG_TS_PACKET_TYPE.const_get(t) == pid }
  end

  # for japanese tv packet type
  def arib_packet_type
    ARIB_PACKET_TYPE.constants.find { |t| ARIB_PACKET_TYPE.const_get(t) == pid }
  end

  def has_adaptation_field?
    adaptation_field_control == ADAPTATION_FIELD_CODE::ADAPTATION_FIELD_ONLY ||
      adaptation_field_control == ADAPTATION_FIELD_CODE::ADAPTATION_FIELD_AND_PAYLOAD
  end

  def has_payload?
    adaptation_field_control == ADAPTATION_FIELD_CODE::PAYLOAD_ONLY ||
      adaptation_field_control == ADAPTATION_FIELD_CODE::ADAPTATION_FIELD_AND_PAYLOAD
  end

  def adaptation_field
    if has_adaptation_field?
      @_adaptation_field ||= AdaptationField.read(StringIO.new(adaptation_field_and_payload))
    end
  end

  def payload
    return nil unless has_payload?
    data_byte_start = if adaptation_field.nil?
                        0
                      else
                        adaptation_field.adaptation_field_length
                      end
    adaptation_field_and_payload[data_byte_start..-1]
  end

  def pes_start?
    payload_start? && payload[0..2].bytes == PES_START_CODE
  end

  def psi_start?
    payload_start? && payload[0..2].bytes != PES_START_CODE
  end

  def pointer_field
    return nil unless psi_start?
    payload[0].bytes[0]
  end

  def payload_data_bytes
    case
    when pes_start?
      payload
    when psi_start?
      pointer = pointer_field
      if pointer > 0
        previous_payload = [1..pointer]
        current_payload = [(pointer + 1)..-1]
        [current_payload, previous_payload]
      else
        # first byte is pointer
        payload[1..-1]
      end
    else
      payload
    end
  end
end
