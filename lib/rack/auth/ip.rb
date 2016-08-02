require 'ipaddr'
require 'ipaddr_list'
module Rack
  module Auth
    # in your_app.ru
    #   require 'rack/auth/ip'
    #   # allow access only local network
    #   use Rack::Auth::IP, %w( 192.168.0.0/24 )

    #   # you can use block
    #   # ip is IPAddr instance.
    #   use Rack::Auth::IP do |ip|
    #     Your::Model::IP.count({ :ip => ip.to_s }) != 0
    #   end
    class IP
      module Util
        # consider using reverse proxy
        def detect_ips(env)
          if env['HTTP_X_FORWARDED_FOR']
            env['HTTP_X_FORWARDED_FOR'].split(',')
          else
            [env['REMOTE_ADDR']]
          end
        end

        module_function :detect_ips
      end
      include Util

      def initialize(app, ip_list = nil, &block)
        @app = app
        @ip_list = ip_list

        @ip_list = IPAddrList.new(@ip_list) if @ip_list && !@ip_list.empty?

        @cond = block
      end

      def call(env)
        ips = detect_ips(env)

        ips.each do |ip|
          req_ip = IPAddr.new(ip)

          if @ip_list && @ip_list.include?(req_ip)
            return @app.call(env)
          elsif @cond && @cond.call(req_ip)
            return @app.call(env)
          end
        end

        [403, { 'Content-Type' => 'text/plain' }, ['Forbidden']]
      end
    end
  end
end
