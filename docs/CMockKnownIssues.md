# CMock - Known Issues

## A Note

This project will do its best to keep track of significant bugs that might effect your usage of this
project and its supporting scripts. A more detailed and up-to-date list for cutting edge CMock can
be found on our Github repository.

## Issues

  - Able to parse most C header files without preprocessor needs, but when handling headers with significant preprocessor usage (#ifdefs, etc), it can get confused
  - Multi-dimensional arrays currently simplified to single dimensional arrays of the full size
  - Incomplete support for VarArgs
