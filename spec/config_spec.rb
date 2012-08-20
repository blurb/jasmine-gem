require 'spec_helper'
require 'selenium-webdriver'

describe Jasmine::Config do
  describe "configuration" do
    before :each do
      Jasmine::Dependencies.stub(:rails_3_asset_pipeline?) { false }

      temp_dir_before

      Dir::chdir @tmp
      dir_name = "test_js_project"
      `mkdir -p #{dir_name}`
      Dir::chdir dir_name
      `#{@root}/bin/jasmine init .`

      @project_dir  = Dir.pwd

      @template_dir = File.expand_path(File.join(@root, "generators/jasmine/templates"))
      @config       = Jasmine::Config.new
    end

    after(:each) do
      temp_dir_after
    end

    describe "defaults" do
      it "src_dir uses root when src dir is blank" do
        @config.stub!(:project_root).and_return('some_project_root')
        @config.stub!(:simple_config_file).and_return(File.join(@template_dir, 'spec/javascripts/support/jasmine.yml'))
        YAML.stub!(:load).and_return({'src_dir' => nil})
        @config.src_dir.should == 'some_project_root'
      end

      it "should use correct default yaml config" do
        @config.stub!(:project_root).and_return('some_project_root')
        @config.simple_config_file.should == (File.join('some_project_root', 'spec/javascripts/support/jasmine.yml'))
      end

      describe "coverage" do
        before :each do
          @config.stub!(:project_root).and_return('some_project_root')
          @config.stub!(:simple_config_file).and_return(File.join(@template_dir, 'spec/javascripts/support/jasmine.yml'))
          YAML.stub!(:load).and_return({'src_dir' => nil})
        end

        it "is disabled" do
          @config.should_not have_coverage_enabled
        end

        it "uses tmp" do
          @config.coverage_temp_dir.should == 'tmp'
        end

        it "uses public/coverage" do
          @config.coverage_report_dir.should == File.join('public', 'coverage')
        end

        it "has utf-8 encoding" do
          @config.coverage_encoding.should == "utf-8"
        end

        it "does not skip any paths" do
          @config.coverage_skipped_paths.should == []
        end
      end
    end

    describe "simple_config" do
      before(:each) do
        @config.stub!(:src_dir).and_return(File.join(@project_dir, "."))
        @config.stub!(:spec_dir).and_return(File.join(@project_dir, "spec/javascripts"))
      end

      describe "using default jasmine.yml" do
        before(:each) do
          @config.stub!(:simple_config_file).and_return(File.join(@template_dir, 'spec/javascripts/support/jasmine.yml'))
        end

        it "should disable coverage support" do
          @config.should_not have_coverage_enabled
        end

        it "should find the source files" do
          @config.src_files.should =~ ['public/javascripts/Player.js', 'public/javascripts/Song.js']
        end

        it "should find the stylesheet files" do
          @config.stylesheets.should == []
        end

        it "should find the spec files" do
          @config.spec_files.should == ['PlayerSpec.js']
        end

        it "should find any helpers" do
          @config.helpers.should == ['helpers/SpecHelper.js']
        end

        it "should build an array of all the JavaScript files to include, source files then spec files" do
          @config.js_files.should == [
                  '/public/javascripts/Player.js',
                  '/public/javascripts/Song.js',
                  '/__spec__/helpers/SpecHelper.js',
                  '/__spec__/PlayerSpec.js'
          ]
        end

        it "should allow the js_files to be filtered" do
          @config.js_files("PlayerSpec.js").should == [
                  '/public/javascripts/Player.js',
                  '/public/javascripts/Song.js',
                  '/__spec__/helpers/SpecHelper.js',
                  '/__spec__/PlayerSpec.js'
          ]
        end

        it "should report the full paths of the spec files" do
          @config.spec_files_full_paths.should == [File.join(@project_dir, 'spec/javascripts/PlayerSpec.js')]
        end
      end

      it "should parse ERB" do
        @config.stub!(:simple_config_file).and_return(File.expand_path(File.join(@root, 'spec', 'fixture','jasmine.erb.yml')))
        Dir.stub!(:glob).and_return { |glob_string| [glob_string] }
        @config.src_files.should == ['file0.js', 'file1.js', 'file2.js',]
      end

      describe "if jasmine.yml not found" do
        before(:each) do
          File.stub!(:exist?).and_return(false)
        end

        it "should default to loading no source files" do
          @config.src_files.should be_empty
        end

        it "should default to loading no stylesheet files" do
          @config.stylesheets.should be_empty
        end

      end

      describe "if jasmine.yml is empty" do
        before(:each) do
          @config.stub!(:simple_config_file).and_return(File.join(@template_dir, 'spec/javascripts/support/jasmine.yml'))
          YAML.stub!(:load).and_return(false)
        end

        it "should default to loading no source files" do
          @config.src_files.should be_empty
        end

        it "should default to loading no stylesheet files" do
          @config.stylesheets.should be_empty
        end
      end

      describe "should use the first appearance of duplicate filenames" do
        before(:each) do
          Dir.stub!(:glob).and_return { |glob_string| [glob_string] }
          fake_config = Hash.new.stub!(:[]).and_return { |x| ["file1.ext", "file2.ext", "file1.ext"] }
          @config.stub!(:simple_config).and_return(fake_config)
          @config.stub!(:coverage_enabled?).and_return(false)
        end

        it "src_files" do
          @config.src_files.should == ['file1.ext', 'file2.ext']
        end

        it "stylesheets" do
          @config.stylesheets.should == ['file1.ext', 'file2.ext']
        end

        it "spec_files" do
          @config.spec_files.should == ['file1.ext', 'file2.ext']
        end

        it "helpers" do
          @config.spec_files.should == ['file1.ext', 'file2.ext']
        end

        it "js_files" do
          @config.js_files.should == ["/file1.ext",
                                      "/file2.ext",
                                      "/__spec__/file1.ext",
                                      "/__spec__/file2.ext",
                                      "/__spec__/file1.ext",
                                      "/__spec__/file2.ext"]
        end

        it "spec_files_full_paths" do
          @config.spec_files_full_paths.should == [
                  File.expand_path("spec/javascripts/file1.ext", @project_dir),
                  File.expand_path("spec/javascripts/file2.ext", @project_dir)
          ]
        end
      end

      describe "should permit explicity-declared filenames to pass through regardless of their existence" do
        before(:each) do
          Dir.stub!(:glob).and_return { |glob_string| [] }
          fake_config = Hash.new.stub!(:[]).and_return { |x| ["file1.ext", "!file2.ext", "**/*file3.ext"] }
          @config.stub!(:simple_config).and_return(fake_config)
        end

        it "should contain explicitly files" do
          @config.src_files.should == ["file1.ext"]
        end
      end

      describe "should allow .gitignore style negation (!pattern)" do
        before(:each) do
          Dir.stub!(:glob).and_return { |glob_string| [glob_string] }
          fake_config = Hash.new.stub!(:[]).and_return { |x| ["file1.ext", "!file1.ext", "file2.ext"] }
          @config.stub!(:simple_config).and_return(fake_config)
          @config.stub!(:coverage_enabled?).and_return(false)
        end

        it "should not contain negated files" do
          @config.src_files.should == ["file2.ext"]
        end
      end

      it "simple_config stylesheets" do
        @config.stub!(:simple_config_file).and_return(File.join(@template_dir, 'spec/javascripts/support/jasmine.yml'))

        YAML.stub!(:load).and_return({'stylesheets' => ['foo.css', 'bar.css']})
        Dir.stub!(:glob).and_return { |glob_string| [glob_string] }

        @config.stylesheets.should == ['foo.css', 'bar.css']
      end

      it "using rails jasmine.yml" do
        ['public/javascripts/prototype.js',
         'public/javascripts/effects.js',
         'public/javascripts/controls.js',
         'public/javascripts/dragdrop.js',
         'public/javascripts/application.js'].each { |f| `touch #{f}` }

        @config.stub!(:simple_config_file).and_return(File.join(@template_dir, 'spec/javascripts/support/jasmine-rails.yml'))

        @config.spec_files.should == ['PlayerSpec.js']
        @config.helpers.should == ['helpers/SpecHelper.js']
        @config.src_files.should == ['public/javascripts/prototype.js',
                                     'public/javascripts/effects.js',
                                     'public/javascripts/controls.js',
                                     'public/javascripts/dragdrop.js',
                                     'public/javascripts/application.js',
                                     'public/javascripts/Player.js',
                                     'public/javascripts/Song.js']
        @config.js_files.should == [
                '/public/javascripts/prototype.js',
                '/public/javascripts/effects.js',
                '/public/javascripts/controls.js',
                '/public/javascripts/dragdrop.js',
                '/public/javascripts/application.js',
                '/public/javascripts/Player.js',
                '/public/javascripts/Song.js',
                '/__spec__/helpers/SpecHelper.js',
                '/__spec__/PlayerSpec.js',
        ]
        @config.js_files("PlayerSpec.js").should == [
                '/public/javascripts/prototype.js',
                '/public/javascripts/effects.js',
                '/public/javascripts/controls.js',
                '/public/javascripts/dragdrop.js',
                '/public/javascripts/application.js',
                '/public/javascripts/Player.js',
                '/public/javascripts/Song.js',
                '/__spec__/helpers/SpecHelper.js',
                '/__spec__/PlayerSpec.js'
        ]
      end

      describe "with coverage enabled"  do
        before :each do
          @config.stub!(:coverage_config).and_return({
            'enabled'     => true,
            'encoding'    => 'utf-8',
            'temp_dir'    => 'tmp',
            'report_dir'  => 'public/coverage',
          })
        end

        describe "when jscoverage is not in the PATH" do
          before :each do
            @config.stub!(:jscoverage_in_path?).and_return(false)
          end

          it "warns the user" do
            output = capture_stdout{ @config.src_files }
            output.should =~ /warn.*jscoverage/i
          end

          it "disables coverage" do
            capture_stdout do
              @config.should_not have_coverage_enabled
            end
          end
        end

        describe "when jscoverage is in the PATH" do
          before :each do
            @config.stub!(:jscoverage_in_path?).and_return(true)
          end

          it "does not warn the user about jscoverage not being in the PATH" do
            output = capture_stdout{ @config.src_files }
            output.should_not =~ /warn.*jscoverage/i
          end

          describe "src_files" do
            it "invokes jscoverage on the first, and only the first, invocation" do
              expected_args = %W{
                jscoverage
                --encoding="utf-8"
                #{File.join 'tmp', 'javascripts', 'uninstrumented'}
                #{File.join 'tmp', 'javascripts', 'instrumented' }
              }.join(' ')
              @config.should_receive(:system).exactly(:once).with(expected_args)
              3.times{ @config.src_files }
            end

            it "copies and instruments paths" do
              instrumented_js_dir = File.join('tmp', 'javascripts', 'instrumented')
              @config.src_files.each do |src_file|
                File.join(instrumented_js_dir, src_file).should exist
              end
            end

            context "with a non-default encoding" do
              before :each do
                @config.stub!(:coverage_encoding){'ascii'}
              end

              it "invokes jscoverage with the specified encoding" do
                expected_args = %W{
                  jscoverage
                  --encoding="ascii"
                  #{File.join 'tmp', 'javascripts', 'uninstrumented'}
                  #{File.join 'tmp', 'javascripts', 'instrumented' }
                }.join(' ')
                @config.should_receive(:system).with(expected_args)
                @config.src_files
              end
            end

            context "with a specified set of paths to not instrument" do
              before :each do
                @config.stub!(:coverage_skipped_paths){["path1", "path2"]}
              end

              it "invokes jscoverage with --no-instrument" do
                expected_args = %W{
                  jscoverage
                  --encoding="utf-8"
                  --no-instrument="path1"
                  --no-instrument="path2"
                  #{File.join 'tmp', 'javascripts', 'uninstrumented'}
                  #{File.join 'tmp', 'javascripts', 'instrumented' }
                }.join(' ')
                @config.should_receive(:system).with(expected_args)
                @config.src_files
              end
            end
          end

          describe "src_dir" do
            before :each do
              @config.unstub! :src_dir
            end

            it "returns coverage_instrumented_dir" do
              @config.src_dir.should == File.join('tmp', 'javascripts', 'instrumented')
            end
          end

          describe "raw_src_dir" do
            it "returns the src directory" do
              File.expand_path(@config.src_dir).should == File.expand_path(@project_dir)
            end
          end
        end
      end
    end
  end

  describe "jasmine_stylesheets" do
    it "should return the relative web server path to the core Jasmine css stylesheets" do
      #TODO: wrap Jasmine::Core with a class that knows about the core path and the relative mapping.
      Jasmine::Core.stub(:css_files).and_return(["my_css_file1.css", "my_css_file2.css"])
      Jasmine::Config.new.jasmine_stylesheets.should == ["/__JASMINE_ROOT__/my_css_file1.css", "/__JASMINE_ROOT__/my_css_file2.css"]
    end
  end

  describe "jasmine_javascripts" do
    it "should return the relative web server path to the core Jasmine css javascripts" do
      Jasmine::Core.stub(:js_files).and_return(["my_js_file1.js", "my_js_file2.js"])
      Jasmine::Config.new.jasmine_javascripts.should == ["/__JASMINE_ROOT__/my_js_file1.js", "/__JASMINE_ROOT__/my_js_file2.js"]
    end
  end

  describe "when the asset pipeline is active" do
    before do
      Jasmine::Dependencies.stub(:rails_3_asset_pipeline?) { true }
    end

    let(:src_files) { ["assets/some.js", "assets/files.js"] }

    let(:config) do
      Jasmine::Config.new.tap do |config|
        #TODO: simple_config should be a passed in hash
        config.stub(:simple_config)  { { 'src_files' => src_files} }
      end
    end

    it "should use AssetPipelineMapper to return src_files" do
      mapped_files =  ["some.js", "files.js"]
      Jasmine::AssetPipelineMapper.stub_chain(:new, :files).and_return(mapped_files)
      config.src_files.should == mapped_files
    end

    it "should pass the config src_files to the AssetPipelineMapper" do
      Jasmine::Config.stub(:simple_config)
      Jasmine::AssetPipelineMapper.should_receive(:new).with(src_files).and_return(double("mapper").as_null_object)
      config.src_files
    end

    describe "coverage support" do
      def stub_env_hash(hash)
        ENV.stub!(:[]) do |arg|
          hash[arg]
        end
        ENV.stub(:has_key?){|k| hash.has_key? k}
      end
      
      it "uses JASMINE_COVERAGE_ENABLED if JASMINE_COVERAGE_ENABLED is set" do
        stub_env_hash({"JASMINE_COVERAGE_ENABLED" => "true" })
        config = Jasmine::Config.new
        config.stub!(:simple_config){ Hash.new }
        config.should have_coverage_enabled
      end
    end
  end
end
