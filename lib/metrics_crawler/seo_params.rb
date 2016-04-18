require 'open-uri'
require 'nokogiri'
require 'PageRankr'
require_relative 'connection_checker'

module MetricsCrawler
  class SeoParams
    include ConnectionChecker

    YACA_LINK           = 'https://yandex.ru/yaca/?text='.freeze
    PRCY_LINK           = 'http://pr-cy.ru/a'.freeze
    LINKPAD_LINK        = 'https://www.linkpad.ru/?search='.freeze
    DMOZ_LINK           = 'https://www.dmoz.org/search?q='.freeze
    ALEXA_LINK          = 'http://www.alexa.com/siteinfo'.freeze
    PRCY_YAINDEX_XPATH  = './/div[@id="box-basik"][1]//div[@class="box-content"]//div[@class="row"]//div[@class="col-sm-4"][1]//div[@class="pull-right"][3]//a'.freeze
    PRCY_GOINDEX_XPATH  = './/div[@id="box-basik"][2]//div[@class="box-content"]//div[@class="row"]//div[@class="col-sm-4"][1]//div[@class="pull-right"][3]//a'.freeze
    PRCY_HOSTINFO_XPATH = './/div[@id="box-basik"][4]//div[@class="box-content"]//div[@class="row"]//div[@class="col-sm-4"]//div[@class="pull-right"]'.freeze

    def initialize(url, proxy = nil)
      @proxy  = URI.parse(URI.encode(proxy)) unless proxy.nil?
      @url    = prepare_url(url)
    end

    def all
      begin
        yaca      = Nokogiri::HTML(open("#{YACA_LINK}#{@url}", proxy: @proxy, read_timeout: 15))
        doc_prcy  = Nokogiri::HTML(open("#{PRCY_LINK}/#{@url}", proxy: @proxy, read_timeout: 15))
        host_info = get_host_info(doc_prcy)
        result    = {
          proxy:            @proxy.to_s,
          url:              @url,
          yandex_catalog:   get_yandex_catalog(yaca),
          tic:              get_yandex_tic(yaca),
          yandex_index:     get_yandex_index(doc_prcy),
          backlinks:        get_backlinks(@url),
          goggle_pagerank:  get_google_pagerank(@url),
          google_index:     get_google_index(doc_prcy),
          dmoz_catalog:     get_dmoz_catalog(@url),
          alexa_rank:       get_alexa_rank(@url),
          host_age:         host_info[0],
          host_ip:          host_info[1],
          host_country:     host_info[3],
          host_from:        host_info[4],
          host_to:          host_info[5],
          download_speed:   get_benchmarking(@url),
          external_links:   get_external_links(@url)
        }
      rescue => ex
        error_handler("#{ex.class} #{ex.message} #{@url} #{@proxy}")
        # exit
      end
      result
    end

    private

    def get_yandex_catalog(doc)
      response_sites = doc.css('.yaca-snippet__cy')
      response_sites.count > 0 ? true : false
    end

    def get_yandex_tic(doc)
      response_sites = doc.css('.yaca-snippet__cy')
      response_sites.count > 0 ? response_sites.first.text.gsub(/ТИЦ: /, '') : 'Null'
    end

    def get_yandex_index(doc_prcy)
      yandex_index = doc_prcy.xpath(PRCY_YAINDEX_XPATH).text.strip
      yandex_index.gsub(/n\/a/, 'Null')
    end

    def get_google_index(doc_prcy)
      google_index = doc_prcy.xpath(PRCY_GOINDEX_XPATH).text.strip
      google_index.gsub(/n\/a/, 'Null')
    end

    def get_google_pagerank(url)
      PageRankr.proxy_service = PageRankr::ProxyServices::Random.new(@proxy.to_s) unless @proxy.nil?
      pagerank = PageRankr.ranks(url, :google)[:google]
      pagerank.nil? ? 'Null' : pagerank
    end

    def get_backlinks(url)
      PageRankr.proxy_service = PageRankr::ProxyServices::Random.new(@proxy.to_s) unless @proxy.nil?
      backlinks = PageRankr.backlinks(url, :google)[:google]
    rescue SocketError
      error_handler "SocketError: не получилось узнать количество backlinks для #{url}"
      'Null'
    else
      backlinks = 'Null' if backlinks.nil?
      backlinks
    end

    def get_dmoz_catalog(url)
      doc = Nokogiri::HTML(open("#{DMOZ_LINK}#{url}", proxy: @proxy, read_timeout: 15))
      response_dmoz = doc.css('.open-dir-sites')
      response_dmoz.empty? ? false : true
    end

    def get_alexa_rank(url)
      doc = Nokogiri::HTML(open("#{ALEXA_LINK}/#{url}", proxy: @proxy, read_timeout: 15))
      alexa_rank = doc.css('.metrics-data.align-vmiddle').first.text.strip.delete(',').to_i
      alexa_rank.zero? ? 'Null' : alexa_rank
    end

    def get_host_info(doc_prcy)
      result = []
      begin
        registration_info = doc_prcy
      rescue => ex
        error_handler("#{ex.class} #{ex.message}")
        result = %w(Null Null Null Null Null Null)
      else
        registration_info.xpath(PRCY_HOSTINFO_XPATH).each_with_index do |data, i|
          result[i] = data.text.strip.gsub(/(Не определен)а?\./, 'Null')
        end
      end
      result
    end

    def get_benchmarking(url)
      dt = `curl -o /dev/null -s -w %{time_total} 'http://#{url}'`
    rescue Net::ReadTimeout => ex
      error_handler("#{ex.class} #{ex.message}")
      'Null'
    else
      "#{(dt.tr(',', '.').to_f * 100).ceil}ms"
    end

    def get_external_links(url)
      external_links = Nokogiri::HTML(open("#{LINKPAD_LINK}#{url}", proxy: @proxy, read_timeout: 15))
    rescue SocketError, Errno::ETIMEDOUT => ex
      error_handler("#{ex.class} #{ex.message}")
      'Null'
    else
      external_links.css('#a3').text.delete(',')
    end

    def error_handler(error)
      File.open('errors', 'a') do |f|
        f.puts("#{DateTime.now}: #{error}")
      end
    end

    private

    def prepare_url(url)
      url.gsub(/(http:\/\/|https:\/\/)/, '')
      url.chomp!('/') if @url[-1] == '/'
      URI.parse(URI.encode(url)).to_s
    end
  end
end
