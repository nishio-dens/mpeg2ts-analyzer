class PacketParser
  module SECTION_TYPE
    PAT      = 0x0000 # Program Association Table
    CAT      = 0x0001 # Conditional Access Table
    PMT      = 0x0002 # Program Map Table
    RESERVED = (0x0003..0x000F)
    # 0x0010 - 0x1FFE User defined
    NULL     = 0x1fff # Null Packet
  end

  # ARIB PID
  module ARIB_SECTION_TYPE
    include SECTION_TYPE

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

  def initialize(video_path)
    @video_path = video_path
    @stream = TsStream.new(video_path)
    @current_packet_group = []
  end

  def read_next
    @current_packet_group = @stream.next_packet_group
  end

  def current_packet_group
    @current_packet_group
  end

  def adaptation_fields
    current_packet_group.map(&:adaptation_field).compact
  end

  def pes?
    first_packet = @current_packet_group[0]
    !first_packet.nil? && first_packet.pes_start?
  end

  def pes_header
    Pes.read(@current_packet_group[0].payload_data_bytes) if pes?
  end

  def pes_data_bytes
    if pes?
      first_packet_bytes = pes_header.data_byte
      rest_packet_bytes = @current_packet_group.reject(&:payload_start?).map(&:payload_data_bytes).join

      [first_packet_bytes].push(rest_packet_bytes).flatten.compact.join
    end
  end

  def section?
    first_packet = @current_packet_group[0]
    !first_packet.nil? && first_packet.psi_start?
  end

  def section_data_bytes
    if section?
      first_packet_payload, _prev_packet_payload = @current_packet_group[0].payload_data_bytes
      _next_group_payload, last_packet_payload = @current_packet_group[-1].payload_data_bytes
      mid_packet_payload = @current_packet_group[1..-2].reject(&:payload_start?).map(&:payload_data_bytes)

      [first_packet_payload, mid_packet_payload, last_packet_payload].flatten.compact.join
    end
  end

  def section
    return nil unless section?
    data_bytes = self.section_data_bytes
    return nil if data_bytes.nil?

    table_id = data_bytes.bytes[0]
    case table_id
    when ARIB_SECTION_TYPE::PAT
      ProgramAssociationTable.read(data_bytes)
    else
      puts "UNKNOWN Section #{table_id.to_s(16)}"
    end
  end
end
