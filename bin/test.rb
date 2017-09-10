$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rubygems'
require 'mpeg2ts'

if ENV['ENV'] == "development"
  require 'pry'
end

video_path = ARGV[0]
parser = PacketParser.new(video_path)
packet_group = parser.read_next

binding.pry
puts "END"
