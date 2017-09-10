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

  def pes_packet
    Pes.read(@current_packet_group[0].payload_data_bytes) if pes_packet_group?
  end

  def pes_data_bytes
    if pes_packet_group?
      first_packet_bytes = pes_packet.data_byte
      rest_packet_bytes = @current_packet_group.reject(&:payload_start?).map(&:payload_data_bytes).join

      [first_packet_bytes].push(rest_packet_bytes).flatten.compact.join
    end
  end

  def pes_packet_group?
    first_packet = @current_packet_group[0]
    !first_packet.nil? && first_packet.pes_start?
  end

  def adaptation_fields
    current_packet_group.map(&:adaptation_field).compact
  end
end
