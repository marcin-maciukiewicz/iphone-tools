#!/usr/bin/env ruby

# == Synopsis 
#   This is a sample description of the application.
#   Blah blah blah.
#
# == Examples
#   This command does blah blah blah.
#     check-appstore-release /path/to/your/project/
#
#   Other examples:
#     check-appstore-release -q bar.doc
#     check-appstore-release --verbose foo.html
#
# == Usage 
#   check-appstore-release [options] source_file
#
#   For help use: check-appstore-release -h
#
# == Options
#   -h, --help          Displays help message
#   -v, --version       Display the version, then exit
#   -q, --quiet         Output as little as possible, overrides verbose
#   -V, --verbose       Verbose output
#   TO DO - add additional options
#
# == Author
#   Marcin Maciukiewicz
#
# == Copyright
#   Copyright (c) 2007 Marcin Maciukiewicz. Licensed under the Apache 2.0 License:
#   http://www.opensource.org/licenses/apache2.0.php

# TO DO - update Synopsis, Examples, etc
# TO DO - change license if necessary




require 'optparse' 
require 'rdoc/usage'
require 'ostruct'
require 'date'
require 'yaml'
require 'time'


require 'plist-3.0/plist/generator'
require 'plist-3.0/plist/parser'

class App
  VERSION = '0.0.1'
  
  attr_reader :options

  def initialize(arguments, stdin)
    @arguments = arguments
    @stdin = stdin
    
    # Set defaults
    @options = OpenStruct.new
    @options.verbose = false
    @options.quiet = false
    # TO DO - add additional defaults
  end

  # Parse options, check arguments, then process the command
  def run
        
    if parsed_options? && arguments_valid? 
      
      puts "Start at #{DateTime.now}\n\n" if @options.verbose
      
      output_options if @options.verbose # [Optional]
            
      process_arguments            
      process_command
      
      build_version=Time.now.strftime("%Y%m%d.%H%M")
      
      # load project definition
      p_def = YAML.load_file(@project_definition_file)
      project_plist = Plist::parse_xml("#{p_def['project_root']}#{p_def['plist_file']}")
      
      puts "Project configuration:"
      for k,v in p_def do
        puts " * #{k}=#{v}" if not k.eql? 'plist_check'
      end
      puts "\n"
      puts "Project definitions:"
      for k,v in project_plist do
        puts " * #{k}=#{v}"
      end      
      puts "\n\n"
      
      for k,v in p_def['plist_check'] do
        if not project_plist[k].eql? v.to_s
          system("say Build failed.")
          raise "plist values mismatch for key #{k}: #{project_plist[k]} is not equal to expected #{v}" 
        end 
      end
            
      @executable_name=project_plist['CFBundleExecutable']
      
      # wipe out build directory
      puts "Output wipeout\n------------------------------------"
      begin
        FileUtils.rm_r("#{p_def['project_root']}/build")
      rescue
      end
      
      # stamp new version
      puts "New version stamp\n------------------------------------"
      system("(cd #{p_def['project_root']}; agvtool new-version -all #{build_version})")
      
      # call build tool
      puts "Build\n------------------------------------"
     if not system("(cd #{p_def['project_root']}; xcodebuild -configuration \"#{p_def['release_configuration']}\" -sdk iphoneos#{p_def['sdk_version']} clean && xcodebuild -configuration \"#{p_def['release_configuration']}\" -sdk iphoneos#{p_def['sdk_version']})")
        system("say Compilation failed.")
        raise "Compilation failed."
      end
      
      # verify signature
      puts "Signature verification\n------------------------------------"
      if not system("(cd #{p_def['project_root']}; codesign -vv \"build/#{p_def['release_configuration']}-iphoneos/#{@executable_name}.app\")")
        system("say Signature verification failed.")
        raise "Signature verification failed."
      end
      
      system("ZIP_FILE=#{@executable_name}-#{build_version}.zip;TMP_FOLDER=/tmp/iphone-release-adhoc/;mkdir $TMP_FOLDER; cp -Rf \"#{p_def['project_root']}/build/#{p_def['release_configuration']}-iphoneos/#{@executable_name}.app\" $TMP_FOLDER;
        (cd \"#{p_def['project_root']}/build/#{p_def['release_configuration']}-iphoneos/\"; zip -r #{p_def['release_dir']}/#{@executable_name}-#{build_version}.app.dSYM.zip #{@executable_name}.app.dSYM);
        cp #{p_def['provisioning_profile']} $TMP_FOLDER;
        (cd $TMP_FOLDER; zip -r /tmp/$ZIP_FILE *);
        rm -Rf $TMP_FOLDER;
        mv /tmp/$ZIP_FILE #{p_def['release_dir']};
      ")
      
      system("say Build is ready; open #{p_def['release_dir']}")
      
      puts "\nFinished at #{DateTime.now}" if @options.verbose
      
    else
      output_usage
    end
      
  end
  
  protected
  
    def parsed_options?
      
      # Specify options
      opts = OptionParser.new 
      opts.on('-v', '--version')    { output_version ; exit 0 }
      opts.on('-h', '--help')       { output_help }
      opts.on('-V', '--verbose')    { @options.verbose = true }  
      opts.on('-q', '--quiet')      { @options.quiet = true }
      # TO DO - add additional options
            
      opts.parse!(@arguments) rescue return false
      
      process_options
      true      
    end

    # Performs post-parse processing on options
    def process_options
      @options.verbose = false if @options.quiet
    end
    
    def output_options
      puts "Options:\n"
      
      @options.marshal_dump.each do |name, val|        
        puts "  #{name} = #{val}"
      end
    end

    # True if required arguments were provided
    def arguments_valid?
      # TO DO - implement your real logic here
      true if @arguments.length == 1 
    end
    
    # Setup the arguments
    def process_arguments
      @project_definition_file=@arguments[0]
    end
    
    def output_help
      output_version
      RDoc::usage() #exits app
    end
    
    def output_usage
      RDoc::usage('usage') # gets usage from comments above
    end
    
    def output_version
      puts "#{File.basename(__FILE__)} version #{VERSION}"
    end
    
    def process_command
      # TO DO - do whatever this app does
      
      #process_standard_input # [Optional]
    end

    def process_standard_input
      input = @stdin.read      
      # TO DO - process input
      
      # [Optional]
      # @stdin.each do |line| 
      #  # TO DO - process each line
      #end
    end
end


# TO DO - Add your Modules, Classes, etc


# Create and run the application
app = App.new(ARGV, STDIN)
app.run