require 'metrics_crawler/crawler'

describe 'Crawler' do
  let! (:crawler) { build(:crawler) }
  let! (:domains_path) { File.expand_path("../../data/domains", __FILE__) }
  let! (:nodes) { ["http://node01.example.com:80", "http://node02.example.com:80"] }

  describe '#run' do
    it 'responds to method #run' do
      expect(crawler).to respond_to(:run)
    end
  end

  describe '#split' do
    it 'responds to method #split' do
      expect(crawler).to respond_to(:split)
    end
    it 'returns a hash' do
      expect(crawler.split(domains_path, nodes)).to be_a(Hash)
    end
    it 'splits incoming file with domains into the number of nodes' do
      expect(crawler.split(domains_path, nodes)).to eq({"http://node01.example.com:80"=>["google.com", "https://vz.ru"], "http://node02.example.com:80"=>["http://ok.ru/", "cnn.com"]})
    end
    it "throw an exception when file does not exist" do
      expect{ crawler.split("incorrect_file", nodes) }.to raise_error("File incorrect_file not found.")
    end
  end
end
