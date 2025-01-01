# =========================================================================
#   CMock - Automatic Mock Generation for C
#   ThrowTheSwitch.org
#   Copyright (c) 2007-25 Mike Karlesky, Mark VanderVoord, & Greg Williams
#   SPDX-License-Identifier: MIT
# =========================================================================

# Setup our load path:
[
  'lib'
].each do |dir|
  $:.unshift(File.join("#{__dir__}//..//", dir))
end
