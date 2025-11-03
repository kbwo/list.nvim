local list = require("list")

describe("list format cycling", function()
  before_each(function()
    vim.api.nvim_command("enew!")
    vim.bo.filetype = "markdown"
  end)

  describe("cycle_sibling_list_format", function()
    it("cycles dash to asterisk for siblings only", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "- item 1",
        "- item 2",
        "- item 3",
      })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      list.cycle_sibling_list_format()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(lines[1] == "* item 1")
      assert(lines[2] == "* item 2")
      assert(lines[3] == "* item 3")
    end)

    it("cycles asterisk to ordered list for siblings only", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "* item 1",
        "* item 2",
        "* item 3",
      })
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      list.cycle_sibling_list_format()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(lines[1] == "1. item 1")
      assert(lines[2] == "2. item 2")
      assert(lines[3] == "3. item 3")
    end)

    it("cycles ordered list to checkbox for siblings only", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "1. item 1",
        "2. item 2",
        "3. item 3",
      })
      vim.api.nvim_win_set_cursor(0, { 3, 0 })
      list.cycle_sibling_list_format()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(lines[1] == "- [ ] item 1")
      assert(lines[2] == "- [ ] item 2")
      assert(lines[3] == "- [ ] item 3")
    end)

    it("cycles checkbox to dash for siblings only", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "- [ ] item 1",
        "- [x] item 2",
        "- [ ] item 3",
      })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      list.cycle_sibling_list_format()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(lines[1] == "- item 1")
      assert(lines[2] == "- item 2")
      assert(lines[3] == "- item 3")
    end)

    it("preserves indentation when cycling siblings", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "    - item 1",
        "    - item 2",
        "    - item 3",
      })
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      list.cycle_sibling_list_format()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(lines[1] == "    * item 1")
      assert(lines[2] == "    * item 2")
      assert(lines[3] == "    * item 3")
    end)

    it("only affects siblings at same indent level", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "- parent",
        "    - child 1",
        "    - child 2",
        "- sibling",
      })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      list.cycle_sibling_list_format()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(lines[1] == "* parent")
      assert(lines[2] == "    - child 1") -- children unchanged
      assert(lines[3] == "    - child 2") -- children unchanged
      assert(lines[4] == "* sibling")
    end)

    it("stops at non-list lines when finding siblings", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "- item 1",
        "- item 2",
        "",
        "- item 3",
      })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      list.cycle_sibling_list_format()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(lines[1] == "* item 1")
      assert(lines[2] == "* item 2")
      assert(lines[3] == "")
      assert(lines[4] == "- item 3") -- unchanged because of blank line
    end)

    it("handles cursor on child item correctly", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "- parent",
        "    - child 1",
        "    - child 2",
      })
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      list.cycle_sibling_list_format()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(lines[1] == "- parent") -- parent unchanged
      assert(lines[2] == "    * child 1")
      assert(lines[3] == "    * child 2")
    end)

    it("does nothing on non-list line", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "regular text",
      })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      list.cycle_sibling_list_format()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(lines[1] == "regular text")
    end)
  end)

  describe("cycle_all_list_format", function()
    it("cycles all lists in a contiguous block", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "- item 1",
        "    - child 1",
        "    - child 2",
        "- item 2",
      })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      list.cycle_all_list_format()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(lines[1] == "* item 1")
      assert(lines[2] == "    * child 1")
      assert(lines[3] == "    * child 2")
      assert(lines[4] == "* item 2")
    end)

    it("cycles through all format types", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "- item",
      })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })

      -- Dash to asterisk
      list.cycle_all_list_format()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(lines[1] == "* item")

      -- Asterisk to ordered
      list.cycle_all_list_format()
      lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(lines[1] == "1. item")

      -- Ordered to checkbox
      list.cycle_all_list_format()
      lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(lines[1] == "- [ ] item")

      -- Checkbox back to dash
      list.cycle_all_list_format()
      lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(lines[1] == "- item")
    end)

    it("preserves indentation for all items", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "- level 0",
        "    - level 1",
        "        - level 2",
      })
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      list.cycle_all_list_format()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(lines[1] == "* level 0")
      assert(lines[2] == "    * level 1")
      assert(lines[3] == "        * level 2")
    end)

    it("renumbers ordered lists correctly", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "* item 1",
        "    * child 1",
        "    * child 2",
        "* item 2",
      })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      list.cycle_all_list_format()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(lines[1] == "1. item 1")
      assert(lines[2] == "    1. child 1")
      assert(lines[3] == "    2. child 2")
      assert(lines[4] == "2. item 2")
    end)

    it("stops at non-list lines", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "- item 1",
        "- item 2",
        "",
        "- item 3",
      })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      list.cycle_all_list_format()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(lines[1] == "* item 1")
      assert(lines[2] == "* item 2")
      assert(lines[3] == "")
      assert(lines[4] == "- item 3") -- unchanged
    end)

    it("preserves checkbox state when cycling back to checkbox", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "- [x] checked",
        "- [ ] unchecked",
      })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })

      -- Cycle through: checkbox -> dash -> asterisk -> ordered -> checkbox
      list.cycle_all_list_format() -- to dash
      list.cycle_all_list_format() -- to asterisk
      list.cycle_all_list_format() -- to ordered
      list.cycle_all_list_format() -- back to checkbox

      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      -- Note: When cycling back to checkbox, all are unchecked by default
      assert(lines[1] == "- [ ] checked")
      assert(lines[2] == "- [ ] unchecked")
    end)

    it("does nothing on non-list line", function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {
        "regular text",
      })
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
      list.cycle_all_list_format()
      local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
      assert(lines[1] == "regular text")
    end)
  end)
end)
