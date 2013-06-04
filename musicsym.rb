
require 'thor'
require_relative 'src/symtag'

class CLIApp < Thor
  class_option :verbose, :type => :boolean, :aliases => :v
  class_option :output, :default => './Organized-Music', :aliases => :o, :desc => 'Directory where to put organized files'
  
  desc "make", "Do it now!"
  def make(source_directory)
    output_dir = File.expand_path(options[:output])
    s = SymTag.new(source_directory)
    s.make_all_symlinks(output_dir)
  end

  desc "clean", "delete ouput directory"
  def clean
    output_dir = File.expand_path(options[:output])
    system('rm', '-rf', output_dir)
    puts "Deleted #{output_dir}"
  end
end

CLIApp.start(ARGV)
