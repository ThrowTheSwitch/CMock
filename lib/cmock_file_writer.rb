# ==========================================
#   CMock Project - Automatic Mock Generation for C
#   Copyright (c) 2007 Mike Karlesky, Mark VanderVoord, Greg Williams
#   [Released under MIT License. Please refer to license.txt for details]
# ========================================== 

class CMockFileWriter

  attr_reader :config

  def initialize(config)
    @config = config
  end

  def create_file(filename, target_folder)
    raise "Where's the block of data to create?" unless block_given?
    create_folders(target_folder)
    if (filename =~ /\.h/)
      full_file_name_temp = "#{target_folder}/include/#{filename}.new"
      full_file_name_done = "#{target_folder}/include/#{filename}"
    else
      full_file_name_temp = "#{target_folder}/C++/#{filename}.new"
      full_file_name_done = "#{target_folder}/C++/#{filename}"
    end
    File.open(full_file_name_temp, 'w') do |file|
      yield(file, filename)
    end
    update_file(full_file_name_done, full_file_name_temp)
  end
  
  def create_folders(target_folder)
    Dir.mkdir(target_folder + "\\include") unless Dir.exists?(target_folder + "\\include")
    Dir.mkdir(target_folder + "\\C++") unless Dir.exists?(target_folder + "\\C++")
  end
  
  def copy_files(source_folder, target_folder, filelist)
      create_folders(target_folder)
    [filelist].flatten.uniq.each do |file|
      puts "Copying file #{file}"
      if (file.match(/\w*\.c/))
        FileUtils.cp(source_folder + "/" + file, target_folder + "/C++")
      else
        FileUtils.cp(source_folder + "/" + file, target_folder + "/include")
      end
    end
  end
  
  private ###################################
  
  def update_file(dest, src)
    require 'fileutils'
    FileUtils.rm(dest) if (File.exist?(dest))
    FileUtils.cp(src, dest)
    FileUtils.rm(src)
  end
end
