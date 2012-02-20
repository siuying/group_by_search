require 'rbing'

module GroupBySearch
  class Grouper
    def initialize(searcher)
      @searcher = searcher
    end
    
    def group_by(groups, inputs)
      inputs.inject({}) do |grouped_input, input|
        the_group = @searcher.most_relevant(groups, input)
        grouped_input[the_group] ||= []
        grouped_input[the_group] << input   
        grouped_input
      end
    end    
  end
  
  class Searcher
    def relevance(groups, input)
      groups.inject({}){|map, grp| map[grp] = search_result_count("\"#{input}\" #{grp}"); map }
    end
    
    def most_relevant(groups, input)
      r = relevance(groups, input)
      r.collect{|k, v| [v, k] }.sort_by{|r| r[0] }.collect {|r| r[1] }.last
    end
    
    def search_result_count(term)
      raise 'not implemented'
    end
  end
  
  class BingSearcher < Searcher
    def initialize(api)
      @bing = ::RBing.new(api)
    end

    def search_result_count(term)
      result = @bing.web(term)
      result["Web"]["Total"] rescue 0
    end
  end
end