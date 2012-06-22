
namespace :ci do
  desc "Continuous integration target"
  task :continuous => [ 'rcov:coverage' ] 
end
