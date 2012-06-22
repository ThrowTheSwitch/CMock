

namespace :rcov do

  begin

    require 'rcov/rcovtask'
    desc "Generate code coverage HTML report in pkg/coverage"
    Rcov::RcovTask.new(:coverage) do |t|
      t.test_files = FileList['test/unit/**/*.rb'] + FileList['test/functional/**/*.rb']
      t.verbose = true
      t.output_dir = "coverage"
    end

  rescue LoadError
    
    task :coverage => [ "test:all" ] do
      puts "(rcov:coverage is disabled because rcov not installed)"
    end

  end

end
