# frozen_string_literal: true

require 'ipaddr'
require 'socket'
require 'json'
require 'set'
require_relative 'group'
require_relative 'products/device'

module Wizrb
  module Shared
    class Discover
      BROADCAST_ADDR = '255.255.255.255'
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
        @devices = []
      end

      def all(filters: {})
        open_socket
        listen_registration
        dispatch_registration
        wait_registration(filters)
        close_socket
        group_devices
      end

      def home(id)
        all(filters: { 'homeId' => id })
      end

      def room(id)
        all(filters: { 'roomId' => id })
      end

      def self.all(wait: 2, filters: {})
        new(wait: wait).all(filters: filters)
      end

      def self.home(id, wait: 2)
        new(wait: wait).home(id)
      end

      def self.room(id, wait: 2)
        new(wait: wait).room(id)
      end

      private

      def open_socket
        @socket = UDPSocket.open.tap do |socket|
          socket.setsockopt(:SOL_SOCKET, :SO_REUSEPORT, 1)
          socket.setsockopt(:SOL_SOCKET, :SO_BROADCAST, 1)
        end
      end

      def listen_registration
        @socket.bind(BIND_ADDR, PORT)
      end

      def dispatch_registration
        @socket.send(REGISTRATION_MESSAGE, 0, BROADCAST_ADDR, PORT)
        sleep 0.5
        @socket.send(REGISTRATION_MESSAGE, 0, BROADCAST_ADDR, PORT)
      end

      def wait_registration(filters = {})
        responses = Set.new
        loop do
          ready = @socket.wait_readable(@wait)
          break if ready.nil?

          response = @socket.recvfrom(65_536)
          responses << response
        end
        @devices = parse_responses(responses, filters)
      end

      def parse_responses(responses, filters)
        devices = []
        responses.each do |data, addr|
          device = parse_response(data, addr)
          devices << device if device && (filters.to_a - device.system_config.to_a).empty?
        end
        devices
      end

      def close_socket
        @socket.close
        @socket = nil
      end

      def parse_response(data, addr)
        response = JSON.parse(data)
        return unless response.dig('result', 'success') && addr[1] && addr[2]

        Wizrb::Shared::Products::Device.new(ip: addr[2], port: addr[1])
      rescue StandardError
        nil
      end

      def group_devices
        Wizrb::Shared::Group.new(devices: @devices)
      end
    end
  end
end
