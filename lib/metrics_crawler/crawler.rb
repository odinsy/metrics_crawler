require 'uri'
require 'parallel'
require 'yaml'
require 'fileutils'
require_relative 'config'
require_relative 'seo_params'
require_relative 'constants'
require_relative 'export'
require_relative 'helpers'

module MetricsCrawler
  class Crawler
    include Export
    include Helpers

    attr_accessor :nodes

    def initialize(config_path = nil)
      @nodes = Config.new(config_path).settings['nodes'] if config_path
    end
    # Запуск сбора метрик
    def run(file, destination, nodes = nil)
      domains = nodes.nil? ? load_domains(file) : split(file, nodes)
      make_header(destination)
      if nodes.nil?
        fetch(domains, destination, nodes)
      else
        Parallel.each(nodes, in_processes: nodes.count) do |node|
          fetch(domains[node], destination, node)
        end
      end
    end
    # Делит входящий файл с доменами на количество переданных нод
    # Возвращает хэш вида {node1: [domain1, domain2], node2: [domain4, domain5], ..}
    def split(file, nodes)
      domains   = load_domains(file)
      part_num  = (domains.count / nodes.count.to_f).ceil
      domains   = domains.each_slice(part_num)
      nodes.zip(domains).to_h
      # nodes.zip(domains).map { |k, v| [k.to_sym, v] }.to_h
    end

    private
    # Сбор результатов для массива доменов
    def fetch(domains, destination, proxy)
      domains.each do |domain|
        output = SeoParams.new(domain, proxy).all
        p output
        save_to_csv(output, destination) unless output.nil?
        sleep 5
      end
    end
    # Загружает домены из файла
    def load_domains(path)
      raise ArgumentError, "File #{path} not found." unless File.exist?(path)
      File.readlines(path).map(&:strip)
    end
  end
end
