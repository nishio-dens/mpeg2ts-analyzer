require 'bindata'

class TsAdaptationField < BinData::Record
  endian :big

  # Adaptation Field Structure
  bit8 :adaptation_field_length

  buffer :field, onlyif: -> { adaptation_field_length > 0 }, length: :adaptation_field_length do
    bit1 :discontinuity_indicator
    bit1 :random_access_indicator
    bit1 :elementary_stream_priority_indicator
    bit1 :pcr_flag
    bit1 :opcr_flag
    bit1 :splicing_point_flag
    bit1 :transport_private_data_flag
    bit1 :adaptation_field_extension_flag

    struct :pcr, onlyif: -> { pcr_flag == 1 } do
      bit33 :program_clock_reference_base
      bit6  :reserved
      bit9  :original_program_reference_extension
    end

    struct :opcr, onlyif: -> { opcr_flag == 1 } do
      bit33 :original_program_clock_reference_base
      bit6  :reserved
      bit9  :original_program_clock_reference_extension
    end

    struct :splicing_point, onlyif: -> { splicing_point_flag == 1 } do
      bit8 :splicing_countdown
    end

    struct :transport_private_data, onlyif: -> { transport_private_data_flag == 1 } do
      bit8 :transport_private_data_length
      string :private_data_byte, read_length: :transport_private_data_length
    end

    struct :adaptation_field_extension, onlyif: -> { adaptation_field_extension_flag == 1 } do
      bit8 :adaptation_field_extension_length

      buffer :body, length: :adaptation_field_extension_length do
        bit1 :ltw_flag
        bit1 :piecewise_rate_flag
        bit1 :seamless_splice_flag
        bit5 :reserved

        struct :ltw, onlyif: -> { ltw_flag == 1 } do
          bit1  :ltw_valid_flag
          bit15 :ltw_offset
        end

        struct :piecewise_rate, onlyif: -> { piecewise_rate_flag == 1 } do
          bit2  :reserved
          bit22 :piecewise_rate
        end

        struct :seamless_splice, onlyif: -> { seamless_splice_flag == 1 } do
          bit4  :splice_type
          bit3  :dts_next_au_32to30
          bit1  :marker_bit1
          bit15 :dts_next_au_29to15
          bit1  :marker_bit2
          bit15 :dts_next_au_14to0
          bit1  :marker_bit3
        end

        rest :reserved2
      end
    end

    rest :stuffing_byte
  end
end
