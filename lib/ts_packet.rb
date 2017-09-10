require 'bindata'

# For more detail to learn about TS Packet, refer to the INTERNATIONAL STANDARD ISO-13818-1.
class TsPacket < BinData::Record
  # Constants

  # MPEG-2 Standard TS Packet size is 188bytes, but 192/204 bytes packet is exist in real world.
  TS_PACKET_SIZE = 188 # bytes
  TS_HEADER_SIZE = 4 # bytes
  TS_PAYLOAD     = TS_PACKET_SIZE - TS_HEADER_SIZE # 144 bytes

  TS_PACKET_START_CODE = 0x47

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
        previous_payload = payload[1..pointer]
        current_payload = payload[(pointer + 1)..-1]
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
