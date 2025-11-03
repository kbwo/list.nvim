describe("toggle_checkbox", function()
  local list = require("list")

  before_each(function()
    -- Create a new buffer for each test
    vim.api.nvim_command("new")
  end)

  after_each(function()
    -- Clean up buffer
    vim.api.nvim_command("bdelete!")
  end)

  it("should toggle unchecked checkbox to checked", function()
    local lines = {
      "- [ ] Task 1",
    }
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    list.toggle_checkbox()

    local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(result[1] == "- [x] Task 1")
  end)

  it("should toggle checked checkbox to unchecked", function()
    local lines = {
      "- [x] Task 1",
    }
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    list.toggle_checkbox()

    local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(result[1] == "- [ ] Task 1")
  end)

  it("should handle checkbox with * marker", function()
    local lines = {
      "* [ ] Task with asterisk",
    }
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    list.toggle_checkbox()

    local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(result[1] == "* [x] Task with asterisk")
  end)

  it("should do nothing on non-checkbox line", function()
    local lines = {
      "- Regular bullet",
    }
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    list.toggle_checkbox()

    local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(result[1] == "- Regular bullet")
  end)

  it("should toggle parent and all children", function()
    local lines = {
      "- [ ] Parent",
      "    - [ ] Child 1",
      "    - [ ] Child 2",
      "- [ ] Sibling",
    }
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    list.toggle_checkbox()

    local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(result[1] == "- [x] Parent")
    assert(result[2] == "    - [x] Child 1")
    assert(result[3] == "    - [x] Child 2")
    assert(result[4] == "- [ ] Sibling") -- Sibling should not be affected
  end)

  it("should toggle parent and nested children", function()
    local lines = {
      "- [ ] Parent",
      "    - [ ] Child 1",
      "        - [ ] Grandchild",
      "    - [ ] Child 2",
    }
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    list.toggle_checkbox()

    local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(result[1] == "- [x] Parent")
    assert(result[2] == "    - [x] Child 1")
    assert(result[3] == "        - [x] Grandchild")
    assert(result[4] == "    - [x] Child 2")
  end)

  it("should toggle parent and children back to unchecked", function()
    local lines = {
      "- [x] Parent",
      "    - [x] Child 1",
      "    - [x] Child 2",
    }
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    list.toggle_checkbox()

    local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(result[1] == "- [ ] Parent")
    assert(result[2] == "    - [ ] Child 1")
    assert(result[3] == "    - [ ] Child 2")
  end)

  it("should handle children with mixed markers", function()
    local lines = {
      "- [ ] Parent",
      "    * [ ] Child with asterisk",
      "    - [ ] Child with dash",
    }
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    list.toggle_checkbox()

    local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(result[1] == "- [x] Parent")
    assert(result[2] == "    * [x] Child with asterisk")
    assert(result[3] == "    - [x] Child with dash")
  end)

  it("should stop at non-child items", function()
    local lines = {
      "- [ ] Parent",
      "    - [ ] Child",
      "Regular text",
      "    - [ ] Not a child (separated by text)",
    }
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    list.toggle_checkbox()

    local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(result[1] == "- [x] Parent")
    assert(result[2] == "    - [x] Child")
    assert(result[3] == "Regular text")
    assert(result[4] == "    - [ ] Not a child (separated by text)") -- Should not toggle
  end)

  it("should handle indented parent checkbox", function()
    local lines = {
      "    - [ ] Indented parent",
      "        - [ ] Child",
    }
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    list.toggle_checkbox()

    local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(result[1] == "    - [x] Indented parent")
    assert(result[2] == "        - [x] Child")
  end)

  it("should toggle only the current checkbox if it has no children", function()
    local lines = {
      "- [ ] Task 1",
      "- [ ] Task 2",
    }
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })

    list.toggle_checkbox()

    local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    assert(result[1] == "- [x] Task 1")
    assert(result[2] == "- [ ] Task 2") -- Should not be affected
  end)

  describe("parent auto-update", function()
    it("should check parent when all siblings are checked", function()
      local lines = {
        "- [ ] Parent",
        "    - [ ] Child 1",
        "    - [ ] Child 2",
      }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      -- Check Child 1
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      list.toggle_checkbox()

      local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(result[1] == "- [ ] Parent") -- Parent still unchecked
      assert(result[2] == "    - [x] Child 1")
      assert(result[3] == "    - [ ] Child 2")

      -- Check Child 2 - now all siblings are checked, parent should be checked
      vim.api.nvim_win_set_cursor(0, { 3, 0 })
      list.toggle_checkbox()

      result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(result[1] == "- [x] Parent") -- Parent should be checked
      assert(result[2] == "    - [x] Child 1")
      assert(result[3] == "    - [x] Child 2")
    end)

    it("should uncheck parent when a child is unchecked", function()
      local lines = {
        "- [x] Parent",
        "    - [x] Child 1",
        "    - [x] Child 2",
      }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      -- Uncheck Child 1
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      list.toggle_checkbox()

      local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(result[1] == "- [ ] Parent") -- Parent should be unchecked
      assert(result[2] == "    - [ ] Child 1")
      assert(result[3] == "    - [x] Child 2")
    end)

    it("should work with multiple levels", function()
      local lines = {
        "- [ ] Grandparent",
        "    - [ ] Parent",
        "        - [ ] Child 1",
        "        - [ ] Child 2",
      }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      -- Check Child 1
      vim.api.nvim_win_set_cursor(0, { 3, 0 })
      list.toggle_checkbox()

      local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(result[1] == "- [ ] Grandparent")
      assert(result[2] == "    - [ ] Parent")
      assert(result[3] == "        - [x] Child 1")
      assert(result[4] == "        - [ ] Child 2")

      -- Check Child 2 - Parent and Grandparent should be checked
      vim.api.nvim_win_set_cursor(0, { 4, 0 })
      list.toggle_checkbox()

      result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(result[1] == "- [x] Grandparent")
      assert(result[2] == "    - [x] Parent")
      assert(result[3] == "        - [x] Child 1")
      assert(result[4] == "        - [x] Child 2")
    end)

    it("should not affect parent if it has non-checkbox children", function()
      local lines = {
        "- [ ] Parent",
        "    - [ ] Child checkbox",
        "    - Regular bullet",
      }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      -- Check the child checkbox
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      list.toggle_checkbox()

      local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(result[1] == "- [ ] Parent") -- Parent should remain unchecked
      assert(result[2] == "    - [x] Child checkbox")
      assert(result[3] == "    - Regular bullet")
    end)

    it("should handle when there is no parent", function()
      local lines = {
        "- [ ] Task 1",
        "- [ ] Task 2",
      }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      -- Toggle Task 1
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      list.toggle_checkbox()

      local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(result[1] == "- [x] Task 1")
      assert(result[2] == "- [ ] Task 2") -- Should not be affected
    end)

    it("should handle mixed markers in siblings", function()
      local lines = {
        "- [ ] Parent",
        "    * [ ] Child 1 (asterisk)",
        "    - [ ] Child 2 (dash)",
      }
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      -- Check both children
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      list.toggle_checkbox()
      vim.api.nvim_win_set_cursor(0, { 3, 0 })
      list.toggle_checkbox()

      local result = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(result[1] == "- [x] Parent") -- Parent should be checked
      assert(result[2] == "    * [x] Child 1 (asterisk)")
      assert(result[3] == "    - [x] Child 2 (dash)")
    end)
  end)
end)
