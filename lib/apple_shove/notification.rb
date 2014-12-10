require "active_support/json"

module AppleShove
  class Notification

    attr_accessor :p12, :sandbox, :device_token, :payload, :expiration_date, :priority
    
    def initialize(attributes = {})
      [:p12, :device_token, :payload].each do |req_attr|
        raise "#{req_attr} must be specified" unless attributes.keys.collect { |k| k.to_s }.include? req_attr.to_s
      end

      attributes.each { |k, v| self.send("#{k}=", v) }
    
      @sandbox          = false if @sandbox.nil?
      @expiration_date  ||= Time.now + 60*60*24*365
      @priority         ||= 10
    end
    
    def self.parse(json)
      self.new(JSON.parse(json))
    end
    
    def to_json(*a)
      hash = {}
      clean_instance_variables.each { |k| hash[k] = self.send(k) }
      hash.to_json(*a)
    end

    def payload_size
      packaged_message.bytesize
    end

    def packaged_token
      [@device_token.gsub(/[\s|<|>]/,'')].pack('H*')
    end

    def packaged_message
      @packaged_message ||= ActiveSupport::JSON::encode(@payload)
    end

    # Apple APNS format
    def binary_message
      pt = packaged_token
      pm = packaged_message
      [0, 0, 32, pt, 0, payload_size, pm].pack("ccca*cca*")
    end
    
    private
    
    def clean_instance_variables
      self.instance_variables.collect { |i| i[1..-1] }
    end
               
  end
end
