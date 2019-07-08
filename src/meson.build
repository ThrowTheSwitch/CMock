###################################################################################
#                                                                                 #
# NAME: src/meson.build                                                           #
#                                                                                 #
# AUTHOR: Mike Karlesky, Mark VanderVoord, Greg Williams.                         #
# WRITTEN BY: Michael Brockus.                                                    #
#                                                                                 #
# License: MIT                                                                    #
#                                                                                 #
###################################################################################



cmock_src = files('cmock.c')

cmock_dir = include_directories('.')

cmock_lib = library(meson.project_name(), 
    sources: cmock_src,
    dependencies: unity_dep,
    include_directories: cmock_dir)