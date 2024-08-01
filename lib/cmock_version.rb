module CMockVersion
  # Where is the header file from here?
  path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'src', 'cmock.h'))

  # Actually look up the version in the header file
  a = [0, 0, 0]
  begin
    File.readlines(path).each do |line|
      %w[VERSION_MAJOR VERSION_MINOR VERSION_BUILD].each_with_index do |field, i|
        m = line.match(/CMOCK_#{field}\s+(\d+)/)
        a[i] = m[1] unless m.nil?
      end
    end
  rescue StandardError
    abort('Can\'t find my header file.')
  end

  # splat it to return the final value
  CMOCK_VERSION = a.join('.')

  GEM = CMOCK_VERSION
end
