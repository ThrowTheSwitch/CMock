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
  rescue SystemCallError => e
    raise "Unable to create mock output directory: #{e.message}. Check :mock_path ('#{@config.mock_path}') configuration."
  end

  def create_skeleton_subdir(subdir)
    require 'fileutils'
    base = effective_skeleton_path
    FileUtils.mkdir_p base
    FileUtils.mkdir_p "#{base}/#{subdir}" if subdir
  rescue SystemCallError => e
    raise "Unable to create skeleton output directory: #{e.message}. Check :skeleton_path ('#{base}') configuration."
  end

  def create_file(filename, subdir)
    raise "Where's the block of data to create?" unless block_given?

    full_file_name_temp = "#{@config.mock_path}/#{"#{subdir}/" if subdir}#{filename}.new"
    full_file_name_done = "#{@config.mock_path}/#{"#{subdir}/" if subdir}#{filename}"
    File.open(full_file_name_temp, 'w') do |file|
      yield(file, filename)
    end
    update_file(full_file_name_done, full_file_name_temp)
  rescue SystemCallError => e
    raise "Unable to write mock file '#{full_file_name_done}': #{e.message}. Check :mock_path ('#{@config.mock_path}') and :subdir ('#{subdir}') configuration."
  end

  def create_skeleton_file(filename, subdir)
    raise "Where's the block of data to create?" unless block_given?

    base = effective_skeleton_path
    full_file_name_temp = "#{base}/#{"#{subdir}/" if subdir}#{filename}.new"
    full_file_name_done = "#{base}/#{"#{subdir}/" if subdir}#{filename}"
    File.open(full_file_name_temp, 'w') do |file|
      yield(file, filename)
    end
    update_file(full_file_name_done, full_file_name_temp)
  rescue SystemCallError => e
    raise "Unable to write skeleton file '#{full_file_name_done}': #{e.message}. Check :skeleton_path ('#{base}') and :subdir ('#{subdir}') configuration."
  end

  def skeleton_file_path(filename, subdir)
    base = effective_skeleton_path
    "#{base}/#{"#{subdir}/" if subdir}#{filename}"
  end

  def append_file(filename, subdir)
    raise "Where's the block of data to create?" unless block_given?

    full_file_name = "#{@config.skeleton_path}/#{"#{subdir}/" if subdir}#{filename}"
    File.open(full_file_name, 'a') do |file|
      yield(file, filename)
    end
  end

  private ###################################

  def effective_skeleton_path
    path = @config.skeleton_path
    path.nil? || path.empty? ? @config.mock_path : path
  end

  def update_file(dest, src)
    require 'fileutils'
    FileUtils.rm(dest, :force => true)
    FileUtils.mv(src, dest)
  end
end
