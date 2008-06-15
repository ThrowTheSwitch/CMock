
class CMockFileWriter

  require 'ftools'

  def initialize(config)
    @config = config
  end

  def create_file(filename)
    raise "Where's the block of data to create?" unless block_given?
    full_file_name_temp = "#{@config.mock_path}/#{filename}.new"
    full_file_name_done = "#{@config.mock_path}/#{filename}"
    File.open(full_file_name_temp, 'w') do |file|
      yield(file, filename)
    end
    update_file(full_file_name_done, full_file_name_temp)
  end
  
  private ###################################
  
  def update_file(dest, src)
    File.delete(dest) if (File.exist?(dest))
    File.copy(src, dest)
    File.delete(src)
  end
end
