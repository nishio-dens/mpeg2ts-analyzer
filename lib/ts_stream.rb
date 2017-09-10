class TsStream
  attr_accessor *%i(filepath io)

  def initialize(filepath)
    @filepath = filepath
    @io = File.open(filepath, "rb")

    @buffering = false
    @packet_buffer = []
  end

  def next_packet_group
    packet_group = []
    while packet = TsPacket.read(io.read(TsPacket::TS_PACKET_SIZE))
      if packet.payload_start?
        packet_group = @packet_buffer
        @packet_buffer = [packet]

        if @buffering
          break
        else
          @buffering = true
        end
      elsif @buffering
        @packet_buffer << packet
      else
        puts "Skip read packet"
      end
    end
    packet_group
  end
end
