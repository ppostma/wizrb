# frozen_string_literal: true

require 'ipaddr'
require 'socket'
require 'timeout'
require 'json'
require_relative 'group'

module Wizrb
  module Lighting
    class Discover
      MULTICAST_ADDR = '224.0.0.1'
      BIND_ADDR = '0.0.0.0'
      PORT = 38_899
      REGISTRATION_MESSAGE = {
        method: 'registration',
        params: {
          phoneMac: 'ABCDEFGHIJKL',
          register: false,
          phoneIp: '1.2.3.4',
          id: '1'
        }
      }.to_json

      def initialize(wait: 2)
        @wait = wait
        @listening = false
        @thread = nil
        @bulbs = []
      end

      def all
        open_socket
        listen_registration
        dispatch_registration
        sleep(@wait)
        close_registration
        close_socket
        Wizrb::Lighting::Group.new(bulbs: @bulbs)
      end

      private

      def open_socket
        bind_address = IPAddr.new(MULTICAST_ADDR).hton + IPAddr.new(BIND_ADDR).hton

        @socket = UDPSocket.open.tap do |socket|
          socket.setsockopt(:IPPROTO_IP, :IP_ADD_MEMBERSHIP, bind_address)
          socket.setsockopt(:IPPROTO_IP, :IP_MULTICAST_TTL, 1)
          socket.setsockopt(:SOL_SOCKET, :SO_REUSEPORT, 1)
        end
      end

      def listen_registration
        @listening = true

        @socket.bind(BIND_ADDR, PORT)

        @thread = Thread.new do
          while @listening
            data, addr = @socket.recvfrom(65_536)
            bulb = parse_response(data, addr)
            @bulbs << bulb unless bulb.nil?
          end
        end
      end

      def dispatch_registration
        @socket.send(REGISTRATION_MESSAGE, 0, MULTICAST_ADDR, PORT)
      end

      def close_registration
        @listening = false
        @thread.terminate
      end

      def close_socket
        @socket.close
        @socket = nil
      end

      def parse_response(data, addr)
        response = JSON.parse(data)

        if response.dig('result', 'success') && addr[1] && addr[2]
          Wizrb::Lighting::Products::Bulb.new(ip: addr[2], port: addr[1])
        end
      rescue StandardError
        nil
      end
    end
  end
end