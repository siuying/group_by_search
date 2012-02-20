require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

include GroupBySearch

describe "GroupBySearch" do

  describe "Searcher" do
    let(:groups) {["football", "basketball"]}
    let(:inputs) {["David Beckham", "Jeremy Lin"]}

    describe "#relevance" do
      it "should return relevance of each group to the input" do
        searcher = Searcher.new
        searcher.stub(:search_result_count).with("\"David Beckham\" football").and_return(2000)
        searcher.stub(:search_result_count).with("\"David Beckham\" basketball").and_return(5)
        searcher.stub(:search_result_count).with("\"Jeremy Lin\" football").and_return(10)
        searcher.stub(:search_result_count).with("\"Jeremy Lin\" basketball").and_return(1000)

        beckham = searcher.relevance(groups, inputs[0])
        jeremy  = searcher.relevance(groups, inputs[1])
        
        beckham.should == {"football" => 2000, "basketball" => 5}
        jeremy.should == {"football" => 10, "basketball" => 1000}
      end
    end

    describe "#most_relevant" do
      it "should return most relevance group for each input" do
        searcher = Searcher.new
        searcher.stub(:search_result_count).with("\"David Beckham\" football").and_return(2000)
        searcher.stub(:search_result_count).with("\"David Beckham\" basketball").and_return(5)
        searcher.stub(:search_result_count).with("\"Jeremy Lin\" football").and_return(10)
        searcher.stub(:search_result_count).with("\"Jeremy Lin\" basketball").and_return(1000)

        beckham_sport = searcher.most_relevant(groups, inputs[0])
        jeremy_sport  = searcher.most_relevant(groups, inputs[1])
        beckham_sport.should == "football"
        jeremy_sport.should == "basketball"
      end
    end
    
  end
  
  describe "Grouper" do
    let(:groups) {["football", "basketball"]}
    let(:inputs) {["David Beckham", "Jeremy Lin"]}

    it "should use searcher" do
      searcher = double(:searcher)
      searcher.stub(:most_relevant).with(groups, "David Beckham").and_return("football")
      searcher.stub(:most_relevant).with(groups, "Jeremy Lin").and_return("basketball")
      
      grouper = Grouper.new(searcher)
      grouped_inputs = grouper.group_by(groups, inputs)
      grouped_inputs["football"].should == ["David Beckham"]
      grouped_inputs["basketball"].should == ["Jeremy Lin"]
    end
  end
  
  describe "BingSearcher" do
    let(:searcher) {
      raise "must define ENV['BING_API_KEY'] first!" unless ENV['BING_API_KEY']
      BingSearcher.new ENV['BING_API_KEY']
    }
    let(:groups) {["football", "basketball", "quidditch"]}

    it "should found 'football' as most relevant group for Beckham" do
      VCR.use_cassette('bing_relevant_beckham') do
        group = searcher.most_relevant(groups, "David Beckham")
        group.should == "football"
      end
    end

    it "should found 'quidditch' as most relevant group for Potter" do
      VCR.use_cassette('bing_relevant_harry') do
        group = searcher.most_relevant(groups, "Harry Potter")
        group.should == "quidditch"
      end
    end
  end
  

  describe "Grouper with BingSearcher" do
    let(:grouper) {
      raise "must define ENV['BING_API_KEY'] first!" unless ENV['BING_API_KEY']
      Grouper.new(BingSearcher.new(ENV['BING_API_KEY'])) 
    }

    let(:groups) {["football", "basketball", "quidditch"]}
    let(:inputs) {["David Beckham", "Harry Potter", "Jeremy Lin", "Michael Jordan"]}

    it "should group input into results" do
      VCR.use_cassette('bing_searcher') do
        result = grouper.group_by(groups, inputs)
        result["football"].should == ["David Bechham"]
        result["quidditch"].should == ["Harry Potter"]
        result["basketball"].should == ["Jeremy Lin", "Michael Jordan"]
      end      
    end
  end
end
