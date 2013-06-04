

require 'audioinfo'
require 'fileutils'

class SymTag
  
  def initialize(source_directory, *options)
    @source_directory = File.expand_path(source_directory)
  end

  def get_all_music_files()
    music_file_extensions = %w(.mp3 .m4a .flac)    
    all_files = Dir.glob(File.join(@source_directory, '**', '*'))
    music_files = all_files.select{|f| music_file_extensions.any?{|mfe| mfe == File.extname(f)}}    
  end

  def make_all_symlinks(output_dir)
    files = get_all_music_files()
    files.each{|f| make_symlink(f, output_dir)}
  end

  def get_info(file)
    info = {}
    begin
      AudioInfo.open(file) do |i|
        info = i.to_h
        info['ext'] = i.extension
      end
      if info.ext == 'flac'
        f = FlacInfo.new(file)
        f.tags.each_pair do |k, v|
          key = k.downcase
          info[key] = v unless info.has_key?(key)
        end
      end
    rescue
      puts "Could not read tags from #{file}. File is probably bad."
    end
    info    
  end

  def make_symlink(file, output_dir)
    info = get_info(file)
    unless info.is_a?(Hash) and info.has_key?('artist') and info.has_key?('title')
      return puts "Bad info for #{file}"
    end
    path = File.join(output_dir, info.artist)
    path = File.join(path, info.album) unless info.album.empty?
    ensure_directories(path)
    new_name = "#{info.title}.#{info.ext}"
    new_name = "#{info.tracknum} - #{new_name}" if info.tracknum
    new_name = "#{info.discnumber}.#{new_name}" if info.discnumber
    full_path = File.join(path, new_name)
    begin
      FileUtils.ln_s(file, full_path, :force => true)
    rescue
      puts "Could not link #{new_name}"
    end
  end

  def ensure_directories(path)
    begin
      File.exists?(path) || FileUtils.mkdir_p(path)
    rescue
      puts "Could not make path #{path}"
    end
  end
end
