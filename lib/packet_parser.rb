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

  def payload
    @current_packet_group = @current_packet_group.map(&:payload).join
  end

  def adaptation_fields
    @current_packet_group = @current_packet_group.map(&:adaptation_field).join
  end
end
