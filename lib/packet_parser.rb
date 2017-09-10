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
end
