require 'spec_helper'

if Jasmine::Dependencies.rails2? && !Jasmine::Dependencies.legacy_rails?

  describe "A Rails 2 app" do

    before :each do
      temp_dir_before
      Dir::chdir @tmp
      create_rails 'rails-example'
      Dir::chdir 'rails-example'
    end

    after :each do
      temp_dir_after
    end

    context "before Jasmine has been installed" do

      it "should not show the jasmine:install generator" do
        output = `./script/generate --help`
        output.should_not include('jasmine:install')
      end

      it "should not show jasmine:install help" do
        output = `rails g`
        output.should_not include('This will create')
      end

      it "should not show jasmine rake task" do
        output = `rake -T`
        output.should_not include("jasmine ")
      end

      it "should not show jasmine:ci rake task" do
        output = `rake -T`
        output.should_not include("jasmine:ci")
      end

    end

    context "when the Jasmine generators are available" do
      before :each do
        `mkdir -p lib/generators && ln -s #{@root}/generators/jasmine lib/generators/jasmine`
      end

      it "should show the Jasmine generator" do
        output = `./script/generate --help`
        output.should include("Lib: jasmine")
      end

      it "should show jasmine:install help" do
        output = `./script/generate jasmine --help`

        output.should include("Usage: ./script/generate jasmine")
      end

      context "and been run" do
        before :each do
          `./script/generate jasmine`
        end

        it "should find the Jasmine configuration files" do
          File.exists?("spec/javascripts/support/jasmine.yml").should == true
        end

        %w(
          public/javascripts/Player.js
          public/javascripts/Song.js

          spec/javascripts/PlayerSpec.js
          spec/javascripts/helpers/SpecHelper.js

          spec/javascripts/helpers/jscoverage.js
          spec/javascripts/support/jasmine.yml
          spec/javascripts/support/jasmine_runner.rb
          spec/javascripts/support/jasmine_config.rb
        ).each do |file|
          it "should have the Jasmine example file #{file}" do
            file.should exist
          end
        end

        it "should show jasmine rake task" do
          output = `rake -T`
          output.should include("jasmine ")
        end

        it "should show jasmine:ci rake task" do
          output = `rake -T`
          output.should include("jasmine:ci")
        end
      end
    end
  end
end
