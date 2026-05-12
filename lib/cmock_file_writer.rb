# =========================================================================
#   CMock - Automatic Mock Generation for C
#   ThrowTheSwitch.org
#   Copyright (c) 2007-26 Mike Karlesky, Mark VanderVoord, & Greg Williams
#   SPDX-License-Identifier: MIT
# =========================================================================

class CMockFileWriter
  attr_reader :config

  def initialize(config)
    @config = config
  end

  def create_subdir(subdir)
    require 'fileutils'
    FileUtils.mkdir_p "#{@config.mock_path}/" unless Dir.exist?("#{@config.mock_path}/")
    FileUtils.mkdir_p "#{@config.mock_path}/#{"#{subdir}/" if subdir}" if subdir && !Dir.exist?("#{@config.mock_path}/#{"#{subdir}/" if subdir}")
  end

  def create_file(filename, subdir)
    raise "Where's the block of data to create?" unless block_given?

    full_file_name_temp = "#{@config.mock_path}/#{"#{subdir}/" if subdir}#{filename}.new"
    full_file_name_done = "#{@config.mock_path}/#{"#{subdir}/" if subdir}#{filename}"
    File.open(full_file_name_temp, 'w') do |file|
      yield(file, filename)
    end
    update_file(full_file_name_done, full_file_name_temp)
  end

  def append_file(filename, subdir)
    raise "Where's the block of data to create?" unless block_given?

    full_file_name = "#{@config.skeleton_path}/#{"#{subdir}/" if subdir}#{filename}"
    File.open(full_file_name, 'a') do |file|
      yield(file, filename)
    end
  end

  private ###################################

  def update_file(dest, src)
    require 'fileutils'

    # Only write files if the contents differ, may prevent unnecessary compilation
    if File.exist?(dest) && File.binread(dest) == File.binread(src)
        FileUtils.rm(src, :force => true)
    else
        FileUtils.rm(dest, :force => true)
        FileUtils.mv(src, dest)
    end
  end
end
