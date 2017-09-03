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

  module PTS_DTS_FLAG
    NO        = 0b00
    FORBIDDEN = 0b01
    PTS_ONLY  = 0b10
    PTS_DTS   = 0b11
  end

  module TRICK_MODE
    FAST_FORWARD = 0b000
    SLOW_MOTION  = 0b001
    FREEZE_FRAME = 0b010
    FAST_REVERSE = 0b011
    SLOW_REVERSE = 0b100
    RESERVED     = (0b101..0b111)
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

  # Pes Packet Structure
  endian :big

  bit24 :packet_start_code_prefix
  bit8  :stream_id
  bit16 :pes_packet_length

  buffer :type1, onlyif: -> { !PES_NOT_TYPE1.include?(stream_id) }, length: :pes_packet_length do
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

    struct :escr, onlyif: -> { escr_flag == 1 } do
      bit2  :reserved
      bit3  :escr_base32_30
      bit1  :marker_bit1
      bit15 :escr_base29_15
      bit1  :marker_bit2
      bit15 :escr_base14_0
      bit1  :marker_bit3
      bit9  :escr_extension
      bit1  :marker_bit4
    end

    struct :es_rate, onlyif: -> { es_rate_flag == 1 } do
      bit1  :marker_bit1
      bit22 :es_rate
      bit1  :marker_bit2
    end

    struct :dsm_trick_mode, onlyif: -> { dsm_trick_mode_flag == 1 } do
      bit3 :trick_mode_control

      struct :fast_forward, onlyif: -> { trick_mode_control == TRICK_MODE::FAST_FORWARD } do
        bit2 :field_id
        bit1 :intra_frame_refresh
        bit2 :frequency_truncation
      end

      struct :slow_motion,  onlyif: -> { trick_mode_control == TRICK_MODE::FAST_FORWARD } do
        bit5 :rep_cntrl
      end

      struct :freeze_frame, onlyif: -> { trick_mode_control == TRICK_MODE::FAST_FORWARD } do
        bit2 :field_id
        bit3 :reserved
      end

      struct :fast_reverse, onlyif: -> { trick_mode_control == TRICK_MODE::FAST_FORWARD } do
        bit2 :field_id
        bit1 :intra_slice_refresh
        bit2 :frequency_truncation
      end

      struct :slow_reverse, onlyif: -> { trick_mode_control == TRICK_MODE::FAST_FORWARD } do
        bit5 :rep_cntrl
      end

      struct :reserved,     onlyif: -> { TRICK_MODE::RESERVED.cover?(trick_mode_control) } do
        bit5 :reserved
      end
    end

    struct :additional_copy_info, onlyif: -> { additional_copy_info_flag == 1 } do
      bit1 :marker_bit
      bit7 :additional_copy_info
    end

    struct :pes_crc, onlyif: -> { pes_crc_flag == 1 } do
      bit16 :previous_pes_packet_crc
    end

    struct :pes_extension, onlyif: -> { pes_extension_flag == 1 } do
      bit1 :pes_private_data_flag
      bit1 :pack_header_field_flag
      bit1 :program_packet_sequence_counter_flag
      bit1 :p_std_buffer_flag
      bit3 :reserved
      bit1 :pes_extension_flag_2

      struct :pes_private_data, onlyif: -> { pes_private_data_flag == 1 } do
        bit128 :pes_private_data
      end

      struct :pack_header_field, onlyif: -> { pack_header_field_flag == 1 } do
        bit8 :pack_field_length
        string :pack_header, length: :pack_field_length
      end

      struct :program_packet_sequence_counter, onlyif: -> { program_packet_sequence_counter_flag == 1 } do
        bit1 :marker_bit1
        bit7 :program_packet_sequence_counter
        bit1 :marker_bit2
        bit1 :mpeg1_mpeg2_identifier
        bit6 :original_stuff_length
      end

      struct :p_std_buffer, onlyif: -> { p_std_buffer_flag == 1 } do
        bit2  :reserved_01
        bit1  :p_std_buffer_scale
        bit13 :p_std_buffer_size
      end

      struct :pes_extension2, onlyif: -> { pes_extension_flag_2 == 1 } do
        bit1 :marker_bit
        bit7 :pes_extension_field_length
        string :reserved, length: :pes_extension_field_length
      end
    end

    # Stuffing Byte
    #   fixed 8-bit value equal to '1111 1111' that can be inserted by the encoder
    #   no more than 32 stuffing bytes shall be present in on PES packet header
    rest :stuffing_byte_pes_packet_data_byte
  end

  struct :type2, onlyif: -> { PES_TYPE2.include?(stream_id) } do
    string :pes_packet_data_byte, length: :pes_packet_length
  end

  struct :padding, onlyif: -> { stream_id == STREAM_ID::PADDING_STREAM } do
    string :padding_byte, length: :padding_byte
  end
end
