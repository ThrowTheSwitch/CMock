# CMock - Change Log

## A Note

This document captures significant features and fixes to the CMock project core source files 
and scripts. More detail can be found in the history on Github. 

This project is now tracking changes in more detail. Previous releases get less detailed as
we move back in histroy. 

Prior to 2012, the project was hosted on SourceForge.net
Prior to 2008, the project was an internal project and not released to the public.

## Log

### CMock 2.7.0 (July 2026)

New Features:

  - Significant improvements to array and pointer handling:
    - Arrays are now passed as arrays. Yes, even multidimensional ones. (Fixes #69, #119, #213, #422)
    - Array plugin now supports comparing `char*` (string) arguments as byte arrays via `_ExpectWithArray`, while still treating them as strings via `_Expect` (Fixes #262 and #177)
    - Improved automatic detection of pointer/length argument pairs (Fixes #520)
    - When a pointer is auto-paired with a size argument, `_ExpectWithArrayExtended` is also generated as a fallback to allow explicit depth override (Fixes #476)
    - `void*` arguments now default to pointer comparison without the array plugin, and to byte-by-byte comparison when the array plugin is active (Fixes #400)
    - Handles *simple* preprocessor features like #if 1 and #if 0 (Fixes #163)
    - Ignores static assertions of various types (Fixes #128)
    - Added option to trace all mock setup and mocked calls (Implements #403)
  - Significant improvements to header parsing speed

Significant Bugfixes:

  - Fixed matching of pointer/len argument pairs in reverse order (Fixes #479)
  - Fixed handling of array of pointers or a pointer to an array (Fixes #450)
  - Fixed const and pointer order handling issues (Fixes #484 and #485)
  - Fixed handling of skeleton paths (Fixes #488)
  - Fixed handling of memory alignment issues (Fixes #178)
  - Fixed handling of failures in teardown (#67)
  - Improved handling of function-looking structs (Fixes #513 and #334)
  - Improved handling of function-looking macros (Fixes #502)
  - Improved handling of volatiles (Fixes #110 and #135)
  - Improved handling of stub and callback counters (Fixes #132)
  - Improved handling and testing of Windows (Fixes #435)

Other:

  - Added verification that memory errors are reported and stop tests (Verifies #463)
  - Added verification that CMock features pass Valgrind (Verifies #506)
  - Documented custom type support (#124)

#### Major Code/Doc Contributors

These individuals contributed significant features, bugfixes, and improvements.

  - Mark VanderVoord
  - Roland Stahn
  - bal-stan

#### Also, thanks for your contributions!

Matt Sullivan, Peter Backeman, ml-physec

### CMock 2.6.0 (January 2025)

New Features:

  - Reintroduced option to run CMock without setjmp (slightly limited)
  - Significant speed improvements to parsing

Significant Bugfixes:

  - Make return-thru-pointer calls const
  - Fix handling of static inlines
  - Fix some situations where parenthetical statements were misinterpreted as functions
  - Fix error in skeleton creation
  - Improvements towards making generated code fully C-compliant and warning free

Other:

  - Improve error message wording where possible
  - Improve documentation
  - Updated to Ruby 3.0 - 3.3
  - Reintroduce matrix testing across multiple Ruby versions

### CMock 2.5.3 (January 2021)

New Features:

  - Support mocks in sub-folders
  - Improved handling of static and inline functions
  - Stateless Ignore plugin added

Significant Bugfixes:

  - Allow setting values to empty at command prompt
  - Improvements towards making generated code fully C-compliant and warning free

Other:
  
  - Really basic mocking of cpp files (like C files with extern C)

### CMock 2.5.2 (May 2020)

Significant Bugfixes:

  - Fix whitespace errors
  - Fix Stop Ignore

### CMock 2.5.1 (April 2020)

New Features:

  - Add StopIgnore function to Ignore Plugin
  - Add ability to generate skeleton from a header.
  - Inline functions now have option to remove and mock (with Ceedling's help)

Significant Bugfixes:

  - Convert internal handling of bools to chars from ints for memory savings
  - Convert CMOCK_MEM_INDEX_TYPE default type to size_t 
  - Switch to old-school comments for supporting old C compilers
  - Significant improvements to handling array length expressions
  - Significant improvements to our "C parser"
  - Added brace-pair counting to improve parsing
  - Fixed error when `:unity_helper_path` is relative

Other:

 - Improve documentation
 - Optimize speed for pass case, particularly in `_verify()` functions
 - Increased depth of unit and system tests

### CMock 2.5.0 (October 2019)

New Features:

  - New memory bounds checking.
  - New memory alignment algorithm.
  - Add `ExpectAnyArgs` plugin
  - Divided `CVallback` from `Stub` functionality so we can do both.
  - Improved wording of failure messages.
  - Added `:treat_as_array` configuration option

Significant Bugfixes:

  - Fixed bug where `CMock_Guts_MemBytesUsed()` didn't always return `0` before usage
  - Fixed bug which sometimes got `CMOCK_MEM_ALIGN` wrong
  - Fixed bug where `ExpectAnyArgs` was generated for functions without args.
  - Better handling of function pointers

Other:

  - `void*` now tested as bytewise array comparison.
  - Documentation fixes, particularly to examples.
  - Added `resetTest` to documentation
  - New handling of messaging to greatly reduce memory footprint

### CMock 2.4.6 (November 2017)

Significant Bugfixes:

  - Fixed critical bug when running dynamic memory.

### CMock 2.4.5 (September 2017)

New Features:

  - Simple threading of mocks introduced.

Significant Bugfixes:
  
  - Improvements to handling pointer const arguments.
  - Treat `char*` separately from an array of bytes.
  - Fixed handling of string arguments.
  - Preserve `const` in all arguments.
  - Fixed race condition when `require`ing plugins

Other:

  - Expand docs on `strict_mock_calling`

### CMock 2.4.4 (April 2017)

New Features:

  - Add `INCLUDE_PATH` option for specifying source

Significant Bugfixes:

  - Parsing improvements related to braces, brackets, and parenthesis
  - `ReturnThruPtr` checks destination not null before copying data.
  - Stub overrides Ignore
  - Improvements to guessing memory alignment based on datatypes

Other:

  - Reorganize testing into subdirectory to not clutter for new users
  - Docs switching to markdown from pdf

### CMock 2.4.3 (October 2016)

New Features:

  - Support multiple helper header files.
  - Add ability to use `weak` symbols if compiler supports it
  - Add mock suffix option in addition to mock prefix.

Significant Bugfixes:

  - Improved UNICODE support



