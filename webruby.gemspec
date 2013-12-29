Gem::Specification.new do |s|
  s.name        =  'webruby'
  s.version     =  '0.2.5'
  s.date        =  '2013-12-29'
  s.summary     =  'webruby'
  s.description =  'compile your favourite Ruby source code for the browser!'
  s.author      =  'Xuejie Xiao'
  s.email       =  'xxuejie@gmail.com'
  s.homepage    =  'https://github.com/xxuejie/webruby'
  s.license     =  'MIT'

  s.bindir      =  'bin'
  s.executables << 'webruby'

  s.files       =  Dir['lib/**/*']
  s.files       += Dir['bin/**/*']
  s.files       += Dir['driver/**/*']
  s.files       += Dir['scripts/**/*']
  s.files       += Dir['templates/**/*']
  s.files       += Dir['modules/**/*'].reject do |f|
    f['modules/emscripten/tests'] ||
    f['modules/emscripten/demos'] ||
    f['modules/emscripten/docs']
  end
end
