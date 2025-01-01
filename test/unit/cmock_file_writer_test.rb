# =========================================================================
#   CMock - Automatic Mock Generation for C
#   ThrowTheSwitch.org
#   Copyright (c) 2007-25 Mike Karlesky, Mark VanderVoord, & Greg Williams
#   SPDX-License-Identifier: MIT
# =========================================================================

require File.expand_path(File.dirname(__FILE__)) + "/../test_helper"
require File.expand_path(File.dirname(__FILE__)) + '/../../lib/cmock_file_writer'

describe CMockFileWriter, "Verify CMockFileWriter Module" do

  before do
    create_mocks :config
    @cmock_file_writer = CMockFileWriter.new(@config)
  end

  after do
  end

  it "complain if a block was not specified when calling create" do
    begin
      @cmock_file_writer.create_file("test.txt")
      assert false, "Should Have Thrown An Error When Calling Without A Block"
    rescue
    end
  end
end
