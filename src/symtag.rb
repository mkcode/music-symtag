

require 'audioinfo'
require 'fileutils'
require 'active_support/core_ext'
require 'pathname'

class SymTag
  
  def initialize(source_directory, *options)
    @source_directory = Pathname.new(File.expand_path(source_directory))
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
      sane_info = {}
      info.each_pair{|k, v| sane_info[k.downcase] = sanitize_tag_value(v)}
      info = sane_info
      if info['album artist'] and info['album artist'].match(/.*various artists.*/i)
        # puts "==========VARIOUS ARTISTS============="
        info['compilation'] = 'yes'
        info['artist'] = "Various Artists"
      end
    rescue
      puts "Could not read tags from #{file}. File is probably bad."
    ensure
      return info
    end
  end

  def sanitize_tag_value(tag)
    tag.to_s.chomp.truncate(50).gsub(' the ', ' The ').gsub("/", '&').gsub(/\0/, '').gsub(/\u0000/, '')
  end

  def make_symlink(file, output_dir)
    info = get_info(file)
    # puts info.inspect
    return puts "Bad info for #{file}" unless (info['artist'] and info['artist'] != '') and (info['title'] and info['title'] != '')
    path = File.join(output_dir, info.artist)
    path = File.join(path, info['album']) if info['album'] and info['album'] != ''
    ensure_directories(path)
    new_name = "#{info['title']}.#{info['ext']}"
    new_name = "#{info['tracknum']} - #{new_name}" if info['tracknum'] and info['tracknum'] != ''
    new_name = "#{info['discnumber']}.#{new_name}" if info['discnumber'] and info['discnumber'] != ''
    full_path = Pathname.new(File.join(path, new_name))
    path = Pathname.new(path)
    relative_path = Pathname.new(file).relative_path_from(Pathname.new(path)) 
    begin
      FileUtils.cd path
      FileUtils.ln_s(relative_path, new_name, :force => true)
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
