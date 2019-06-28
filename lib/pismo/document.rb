# encoding: utf-8
require 'pismo/version'
require 'pismo/internal_attributes'
require 'pismo/external_attributes'

module Pismo

  # Pismo::Document represents a single HTML document within Pismo
  class Document

    ruby_version = if RUBY_PATCHLEVEL >= 0 then
                     "#{RUBY_VERSION}p#{RUBY_PATCHLEVEL}"
                   else
                     "#{RUBY_VERSION}dev#{RUBY_REVISION}"
                   end

    attr_reader :doc, :url, :options

    ATTRIBUTE_METHODS = InternalAttributes.instance_methods + ExternalAttributes.instance_methods
    # Supported User-Agent aliases for use with user_agent_alias=.  The
    # description in parenthesis is for informative purposes and is not part of
    # the alias name.
    #
    # * Linux Firefox (43.0 on Ubuntu Linux)
    # * Linux Konqueror (3)
    # * Linux Mozilla
    # * Mac Firefox (43.0)
    # * Mac Mozilla
    # * Mac Safari (9.0 on OS X 10.11.2)
    # * Mac Safari 4
    # * Mechanize (default)
    # * Windows IE 6
    # * Windows IE 7
    # * Windows IE 8
    # * Windows IE 9
    # * Windows IE 10 (Windows 8 64bit)
    # * Windows IE 11 (Windows 8.1 64bit)
    # * Windows Edge
    # * Windows Mozilla
    # * Windows Firefox (43.0)
    # * iPhone (iOS 9.1)
    # * iPad (iOS 9.1)
    # * Android (5.1.1)
    #
    # Example:
    #
    #   doc = Pismo::Document.new 'https://example.com', user_agent_alias: 'Linux Firefox'

    AGENT_ALIASES = {
      'Pismo' => "Pismo/#{Pismo::VERSION} Ruby/#{ruby_version} (https://github.com/peterc/pismo)",
      'Linux Firefox' => 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:43.0) Gecko/20100101 Firefox/43.0',
      'Linux Konqueror' => 'Mozilla/5.0 (compatible; Konqueror/3; Linux)',
      'Linux Mozilla' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624',
      'Mac Firefox' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.11; rv:43.0) Gecko/20100101 Firefox/43.0',
      'Mac Mozilla' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401',
      'Mac Safari 4' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; de-at) AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10',
      'Mac Safari' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_2) AppleWebKit/601.3.9 (KHTML, like Gecko) Version/9.0.2 Safari/601.3.9',
      'Windows Chrome' => 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.125 Safari/537.36',
      'Windows IE 6' => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
      'Windows IE 7' => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)',
      'Windows IE 8' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)',
      'Windows IE 9' => 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)',
      'Windows IE 10' => 'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; WOW64; Trident/6.0)',
      'Windows IE 11' => 'Mozilla/5.0 (Windows NT 6.3; WOW64; Trident/7.0; rv:11.0) like Gecko',
      'Windows Edge' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2486.0 Safari/537.36 Edge/13.10586',
      'Windows Mozilla' => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
      'Windows Firefox' => 'Mozilla/5.0 (Windows NT 6.3; WOW64; rv:43.0) Gecko/20100101 Firefox/43.0',
      'iPhone' => 'Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B5110e Safari/601.1',
      'iPad' => 'Mozilla/5.0 (iPad; CPU OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1',
      'Android' => 'Mozilla/5.0 (Linux; Android 5.1.1; Nexus 7 Build/LMY47V) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/47.0.2526.76 Safari/537.36',
    }
    DEFAULT_OPTIONS = {
      user_agent: AGENT_ALIASES['Mac Safari'],
      image_extractor: false,
      min_image_width: 100,
      min_image_height: 100
    }

    include Pismo::InternalAttributes
    include Pismo::ExternalAttributes

    def initialize(handle, options = {})
      @options = DEFAULT_OPTIONS.merge options
      url = @options.delete(:url)
      load(handle, url)
    end

    # An HTML representation of the document
    def html
      @doc.to_s
    end

    def load(handle, url = nil)
      @url = url if url
      @url = handle if handle =~ /\Ahttp/i

      @html = if handle =~ /\Ahttp/i
                open(handle, 'User-Agent' => user_agent) { |f| f.read }
              elsif handle.is_a?(StringIO) || handle.is_a?(IO) || handle.is_a?(Tempfile)
                handle.read
              else
                handle
              end

      @doc = Nokogiri::HTML(@html)
    end

    def match(args = [], all = false)

      @doc.match([*args], all)
    end

    private

    def user_agent
      if agent = @options[:user_agent]
        return AGENT_ALIASES[agent] if AGENT_ALIASES.key?(agent)
        agent
      elsif agent = @options[:user_agent_alias]
        return AGENT_ALIASES[agent] if AGENT_ALIASES.key?(agent)
        DEFAULT_OPTIONS[:user_agent]
      else
        DEFAULT_OPTIONS[:user_agent]
      end
    end
  end
end
