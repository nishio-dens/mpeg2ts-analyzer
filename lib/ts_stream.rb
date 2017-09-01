class TsStream
  attr_accessor *%i(filepath io)

  def initialize(filepath)
    @filepath = filepath
    @io = File.open(filepath, "rb")
  end

  def next
    packet = io.read(TsPacket::TS_PACKET_SIZE)
    TsPacket.read(packet)
  end
end
