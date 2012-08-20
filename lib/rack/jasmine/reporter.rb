require 'json'
module Rack
  module Jasmine
    class Reporter
      def initialize(config)
        @config = config
      end
      
      def call(env)
        req = Rack::Request.new env
        save_coverage_report! req.params['report']
        [
          200,
          { 'Content-Type' => 'text/html'},
          ["<html><body>OK</body></html>"]
        ]
      end

      def not_found
        [404, {"Content-Type" => "text/plain",
               "X-Cascade" => "pass"},
               ["Error..."]]
      end

      def save_coverage_report!(coverage)
        FileUtils.mkdir_p @config.coverage_report_dir
        ::File.open(::File.join(@config.coverage_report_dir, 'jscoverage.json'), 'w') do |file|
          file.write( JSON.pretty_generate( JSON.parse(coverage) ))
        end

        jscoverage_files = %w(
          jscoverage.css jscoverage-highlight.css jscoverage.html
          jscoverage-ie.css jscoverage.js jscoverage-throbber.gif).map do |file|
          ::File.join(@config.src_dir, file)
        end
        FileUtils.cp jscoverage_files, @config.coverage_report_dir
        
        ::File.open(::File.join(@config.coverage_report_dir, 'jscoverage.js'), 'a') do |jscoverage_js|
          jscoverage_js.puts "\njscoverage_isReport = true;"
        end
        puts "Finished writing coverage report"
      end      
    end
  end
end
