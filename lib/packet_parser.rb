class PacketParser
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
end
