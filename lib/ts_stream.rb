class TsStream
  attr_accessor *%i(filepath io)

  def initialize(filepath)
    @filepath = filepath
    @io = File.open(filepath, "rb")

    @packet_buffer = []
  end

  def next_pes_or_section
    packet = io.read(TsPacket::TS_PACKET_SIZE)
    TsPacket.read(packet)
  end
end
