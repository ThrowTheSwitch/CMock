# =========================================================================
#   CMock - Automatic Mock Generation for C
#   ThrowTheSwitch.org
#   Copyright (c) 2007-25 Mike Karlesky, Mark VanderVoord, & Greg Williams
#   SPDX-License-Identifier: MIT
# =========================================================================

# Setup our load path:
[
  './lib',
  './vendor/behaviors/lib',
  './vendor/hardmock/lib',
  './vendor/unity/auto/',
  './test/system/'
].each do |dir|
  $:.unshift(File.join(File.expand_path("#{File.dirname(__FILE__)}//..//"), dir))
end
