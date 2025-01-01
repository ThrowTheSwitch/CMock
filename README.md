CMock ![CI](https://github.com/ThrowTheSwitch/CMock/workflows/CI/badge.svg)
=====

CMock is a mock and stub generator and runtime for unit testing C. It's been designed
to work smoothly with Unity Test, another of the embedded-software testing tools 
developed by ThrowTheSwitch.org. CMock automagically parses your C headers and creates
useful and usable mock interfaces for unit testing. Give it a try!

If you don't care to manage unit testing builds yourself, consider checking out Ceedling, 
a test-centered build manager for unit testing C code.

 - [Known Issues](docs/CMockKnownIssues.md)
 - [Change Log](docs/CMockChangeLog.md)

Getting Started
===============

Your first step is to get yourself a copy of CMock. There are a number of ways to do this:

1. If you're using Ceedling, there is no need to install CMock. It will handle it for you.

2. The simplest way is to grab it off github. The Github method looks something like this:

    > git clone --recursive https://github.com/throwtheswitch/cmock.git

3. You can also grab the `zip` file from github. If you do this, you'll also need to grab yourself a
copy of Unity and CException, because github unfortunately doesn't bake dependencies into the zip
files. 

Contributing to this Project
============================

If you plan to help with the development of CMock (or just want to verify that it can
perform its self tests on your system) then you can grab its self-testing dependencies, 
then run its self-tests:

    > cd cmock
    > bundle install   # Ensures you have all RubyGems needed
    > cd test
    > rake             # Run all CMock self tests

Before working on this project, you're going to want to read our guidelines on 
[contributing](docs/CONTRIBUTING.md). 

API Documentation
=================

* Not sure what you're doing?
	* [View docs/CMock_Summary.md](docs/CMock_Summary.md)
* Interested in our MIT license?
	* [View docs/license.txt](LICENSE.txt)
* Are there examples?
	* They are all in [/examples](examples/)
* Any other resources to check out?
	* Definitely! Check out our developer portal on [ThrowTheSwitch.org](http://throwtheswitch.org)
