require 'bindata'

class PesPacket < BinData::Record
  # Constants
  module STREAM_ID
    PROGRAM_STREAM_MAP       = 0b1011_1100
    PRIVATE_STREAM           = 0b1011_1101
    PADDING_STREAM           = 0b1011_1110
    PRIVATE_STREAM2          = 0b1011_1111
    # Audio stream 110x xxxx, audio stream number x xxxx
    AUDIO_STREAM             = (0b1100_0000..0b1101_1111)
    # Video stream 1110 xxxx, video stream number xxxx
    VIDEO_STREAM             = (0b1110_0000..0b1110_1111)
    ECM_STREAM               = 0b1111_0000
    EMM_STREAM               = 0b1111_0001
    DSMCC_STREAM             = 0b1111_0010
    ISO_IEC_13522_STREAM     = 0b1111_0011
    H222_TYPE_A              = 0b1111_0100
    H222_TYPE_B              = 0b1111_0101
    H222_TYPE_C              = 0b1111_0110
    H222_TYPE_D              = 0b1111_0111
    H222_TYPE_E              = 0b1111_1000
    ANCILLARY_STREAM         = 0b1111_1001
    SL_PACKETIZED_STREAM     = 0b1111_1001
    FLEXMUX_STREAM           = 0b1111_1011
    RESERVED_STREAM          = (0b1111_1100..0b1111_1110)
    PROGRAM_STREAM_DIRECTORY = 0b1111_1111
  end

  PES_NOT_TYPE1 = [
    STREAM_ID::PROGRAM_STREAM_MAP,
    STREAM_ID::PADDING_STREAM,
    STREAM_ID::PRIVATE_STREAM2,
    STREAM_ID::ECM_STREAM,
    STREAM_ID::EMM_STREAM,
    STREAM_ID::PROGRAM_STREAM_DIRECTORY,
    STREAM_ID::DSMCC_STREAM,
    STREAM_ID::H222_TYPE_E
  ]
  PES_TYPE2 = [
    STREAM_ID::PROGRAM_STREAM_MAP,
    STREAM_ID::PRIVATE_STREAM2,
    STREAM_ID::ECM_STREAM,
    STREAM_ID::EMM_STREAM,
    STREAM_ID::PROGRAM_STREAM_DIRECTORY,
    STREAM_ID::DSMCC_STREAM,
    STREAM_ID::H222_TYPE_E
  ]

  module PTS_DTS_FLAG
    NO        = 0b00
    FORBIDDEN = 0b01
    PTS_ONLY  = 0b10
    PTS_DTS   = 0b11
  end

  # Pes Packet Structure
  endian :big

  bit24 :packet_start_code_prefix
  bit8  :stream_id
  bit16 :pes_packet_length

  struct :type1, onlyif: -> { !PES_NOT_TYPE1.include?(stream_id) } do
    bit2 :reserved_10
    bit2 :pes_scrambling_control
    bit1 :pes_priority
    bit1 :data_alignment_indicator
    bit1 :copyright
    bit1 :original_or_copy
    bit2 :pts_dts_flags
    bit1 :escr_flag
    bit1 :es_rate_flag
    bit1 :dsm_trick_mode_flag
    bit1 :additional_copy_info_flag
    bit1 :pes_crc_flag
    bit1 :pes_extension_flag
    bit8 :pes_header_data_length

    struct :pts_only, onlyif: -> { pts_dts_flags == PTS_DTS_FLAG::PTS_ONLY } do
      bit4  :reserved_0010
      bit3  :pts32_30
      bit1  :marker_bit1
      bit15 :pts29_15
      bit1  :marker_bit2
      bit15 :pts14_0
      bit1  :marker_bit3
    end

    struct :pts_dts, onlyif: -> { pts_dts_flags == PTS_DTS_FLAG::PTS_DTS } do
      bit4  :reserved_0010
      bit3  :pts32_30
      bit1  :marker_bit1
      bit15 :pts29_15
      bit1  :marker_bit2
      bit15 :pts14_0
      bit1  :marker_bit3

      bit4  :reserved_0010_2
      bit3  :dts32_30
      bit1  :marker_bit4
      bit15 :dts29_15
      bit1  :marker_bit5
      bit15 :dts14_0
      bit1  :marker_bit6
    end

    # ESCR

    # ES

    # DSM

    # ADDITIONAL COPY INFO

    # PES_CRC

    # PES_EXTENSION

    # STUFFING / BYTE
  end

  struct :type2, onlyif: -> { PES_TYPE2.include?(stream_id) } do
    # TODO
  end

  struct :padding, onlyif: -> { stream_id == STREAM_ID::PADDING_STREAM } do
    # TODO
  end
end
