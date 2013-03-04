require "shorturl/exceptions"
require "net/http"
require "cgi"

module ShortURL
  class Service
    attr_accessor :port, :code, :method, :action, :field, :block, :response_block, :ssl

    # Intialize the service with a hostname (required parameter) and you
    # can override the default values for the HTTP port, expected HTTP
    # return code, the form method to use, the form action, the form
    # field which contains the long URL, and the block of what to do
    # with the HTML code you get.
    def initialize(hostname) # :yield: service
      @hostname = hostname
      @port = 80
      @code = 200
      @method = :post
      @action = "/"
      @field = "url"
      @ssl = false

      if block_given?
        yield self
      end
    end

    # Now that our service is set up, call it with all the parameters to
    # (hopefully) return only the shortened URL.
    def call(url)
      Net::HTTP.start(@hostname, @port,
                      :use_ssl     => ssl,
                      :verify_mode => OpenSSL::SSL::VERIFY_NONE,
                      :scheme      => ssl ? 'https' : 'http'
                     ) { |http|
                       response = case @method
                                  when :post
                                    http.post(@action, "#{@field}=#{CGI.escape(url)}")
                                  when :get
                                    http.get("#{@action}?#{@field}=#{CGI.escape(url)}")
                                  end

                       if response.code == @code.to_s
                         @response_block ? @response_block.call(response) : @block.call(response.read_body)
                       end
                     }
    rescue Errno::ECONNRESET => e
      raise ServiceNotAvailable, e.to_s, e.backtrace
    end
  end
end