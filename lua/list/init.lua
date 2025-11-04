local M = {}

M.setup = function(opts)
  opts = opts or {}
  -- Setup configuration if needed in the future
end

-- Detect list format from a line
-- Returns table with list info or nil if not a list
M.detect_list_format = function(line)
  -- Match indentation
  local indent = line:match("^(%s*)")
  local indent_len = #indent
  local content = line:sub(indent_len + 1)

  -- Match checkbox (both checked and unchecked)
  local checkbox_marker, checkbox_state, checkbox_content =
    content:match("^([%-%*])%s+%[([%sx])%]%s*(.*)")
  if checkbox_marker then
    return {
      type = "checkbox",
      marker = checkbox_marker,
      checked = checkbox_state == "x",
      indent = indent_len,
      content = checkbox_content,
    }
  end

  -- Match ordered list
  local number, ordered_content = content:match("^(%d+)%.%s+(.*)")
  if number then
    return {
      type = "ordered",
      number = tonumber(number),
      indent = indent_len,
      content = ordered_content,
    }
  end

  -- Match bullet list
  local bullet_marker, bullet_content = content:match("^([%-%*])%s+(.*)")
  if bullet_marker then
    return {
      type = "bullet",
      marker = bullet_marker,
      indent = indent_len,
      content = bullet_content,
    }
  end

  return nil
end

-- Auto-continue list on new line
M.auto_continue_list = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_num = cursor[1]
  local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]

  local list_info = M.detect_list_format(line)

  if not list_info then
    -- Not a list, just insert a new line
    vim.api.nvim_buf_set_lines(0, line_num, line_num, false, { "" })
    vim.api.nvim_win_set_cursor(0, { line_num + 1, 0 })
    return
  end

  -- Check if the list item is empty (only has the marker)
  if list_info.content == "" then
    -- Remove the list marker and insert empty line
    local indent_str = string.rep(" ", list_info.indent)
    vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { indent_str })
    vim.api.nvim_buf_set_lines(0, line_num, line_num, false, { "" })
    vim.api.nvim_win_set_cursor(0, { line_num + 1, 0 })
    return
  end

  -- Create continuation line with same format
  local indent_str = string.rep(" ", list_info.indent)
  local new_line

  if list_info.type == "checkbox" then
    new_line = indent_str .. list_info.marker .. " [ ] "
  elseif list_info.type == "ordered" then
    new_line = indent_str .. tostring(list_info.number + 1) .. ". "
  elseif list_info.type == "bullet" then
    new_line = indent_str .. list_info.marker .. " "
  end

  vim.api.nvim_buf_set_lines(0, line_num, line_num, false, { new_line })
  vim.api.nvim_win_set_cursor(0, { line_num + 1, #new_line })
end

-- Find parent checkbox by looking upward from the current line
local find_parent_checkbox = function(line_num, child_indent)
  local i = line_num - 1
  while i >= 1 do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
    local info = M.detect_list_format(line)

    if not info then
      -- Non-list line encountered, no parent found
      return nil
    end

    if info.indent < child_indent and info.type == "checkbox" then
      -- Found parent checkbox
      return i, info
    end

    if info.indent < child_indent then
      -- Found a parent but it's not a checkbox
      return nil
    end

    i = i - 1
  end

  return nil
end

-- Get all children at the immediate child level of a parent
local get_all_children_at_level = function(parent_line_num, parent_indent)
  local children = {}
  local total_lines = vim.api.nvim_buf_line_count(0)
  local expected_child_indent = parent_indent + 4 -- Assuming 4-space indentation

  local i = parent_line_num + 1
  while i <= total_lines do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
    local info = M.detect_list_format(line)

    if not info then
      -- Non-list line, stop searching
      break
    end

    if info.indent < expected_child_indent then
      -- Reached a sibling or parent level, stop
      break
    end

    if info.indent == expected_child_indent then
      -- This is an immediate child
      table.insert(children, { line_num = i, info = info })
    end

    i = i + 1
  end

  return children
end

-- Update parent checkbox based on children states
-- Forward declaration for recursion
local update_parent_checkbox
update_parent_checkbox = function(line_num, current_indent)
  local parent_line_num, parent_info = find_parent_checkbox(line_num, current_indent)

  if not parent_line_num or not parent_info then
    -- No parent found
    return
  end

  -- Get all children of the parent
  local children = get_all_children_at_level(parent_line_num, parent_info.indent)

  -- Count total children, checkbox children, and checked children
  local total_children = #children
  local checkbox_children = 0
  local checked_children = 0

  for _, child in ipairs(children) do
    if child.info.type == "checkbox" then
      checkbox_children = checkbox_children + 1
      if child.info.checked then
        checked_children = checked_children + 1
      end
    end
  end

  -- Only update parent if all children are checkboxes
  if checkbox_children == 0 or checkbox_children ~= total_children then
    return
  end

  -- Determine parent's new state
  local should_be_checked = (checked_children == checkbox_children)

  -- Update parent if needed
  if parent_info.checked ~= should_be_checked then
    local new_state_char = should_be_checked and "x" or " "
    local indent_str = string.rep(" ", parent_info.indent)
    local new_line = indent_str
      .. parent_info.marker
      .. " ["
      .. new_state_char
      .. "] "
      .. parent_info.content

    vim.api.nvim_buf_set_lines(0, parent_line_num - 1, parent_line_num, false, { new_line })

    -- Recursively update grandparents
    update_parent_checkbox(parent_line_num, parent_info.indent)
  end
end

-- Toggle checkbox state
M.toggle_checkbox = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_num = cursor[1]
  local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]

  local list_info = M.detect_list_format(line)

  -- Only process if it's a checkbox
  if not list_info or list_info.type ~= "checkbox" then
    return
  end

  -- Toggle the current checkbox
  local new_state = not list_info.checked
  local new_state_char = new_state and "x" or " "
  local indent_str = string.rep(" ", list_info.indent)
  local new_line = indent_str
    .. list_info.marker
    .. " ["
    .. new_state_char
    .. "] "
    .. list_info.content

  -- Update current line
  vim.api.nvim_buf_set_lines(0, line_num - 1, line_num, false, { new_line })

  -- Find and toggle all children
  local total_lines = vim.api.nvim_buf_line_count(0)
  local parent_indent = list_info.indent
  local i = line_num + 1

  while i <= total_lines do
    local child_line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
    local child_info = M.detect_list_format(child_line)

    -- Stop if we encounter a line with equal or lesser indent, or non-list line
    if not child_info then
      break
    end

    if child_info.indent <= parent_indent then
      break
    end

    -- Toggle child checkbox if it is one
    if child_info.type == "checkbox" then
      local child_indent_str = string.rep(" ", child_info.indent)
      local child_new_line = child_indent_str
        .. child_info.marker
        .. " ["
        .. new_state_char
        .. "] "
        .. child_info.content
      vim.api.nvim_buf_set_lines(0, i - 1, i, false, { child_new_line })
    end

    i = i + 1
  end

  -- Update parent checkboxes if needed
  update_parent_checkbox(line_num, list_info.indent)
end

-- Helper function to determine the next format in the cycle
-- Cycle: bullet(-) -> bullet(*) -> ordered -> checkbox -> bullet(-)
local get_next_format = function(current_info)
  if current_info.type == "bullet" then
    if current_info.marker == "-" then
      return "bullet", "*"
    else -- marker == "*"
      return "ordered", nil
    end
  elseif current_info.type == "ordered" then
    return "checkbox", nil
  elseif current_info.type == "checkbox" then
    return "bullet", "-"
  end
end

-- Convert a list item to a new format
local convert_list_format = function(line, list_info, new_type, new_marker, number)
  local indent_str = string.rep(" ", list_info.indent)
  local content = list_info.content

  if new_type == "bullet" then
    return indent_str .. new_marker .. " " .. content
  elseif new_type == "ordered" then
    return indent_str .. tostring(number) .. ". " .. content
  elseif new_type == "checkbox" then
    return indent_str .. "- [ ] " .. content
  end
end

-- Find all sibling list items (same indent level, contiguous)
local find_siblings = function(line_num, target_indent)
  local siblings = {}
  local total_lines = vim.api.nvim_buf_line_count(0)

  -- Search upward for siblings
  local i = line_num - 1
  while i >= 1 do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
    local info = M.detect_list_format(line)

    if not info then
      -- Non-list line, stop searching upward
      break
    end

    if info.indent < target_indent then
      -- Found parent level, stop
      break
    end

    if info.indent == target_indent then
      -- Found a sibling
      table.insert(siblings, 1, { line_num = i, info = info, line = line })
    end

    i = i - 1
  end

  -- Add current line
  local current_line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
  local current_info = M.detect_list_format(current_line)
  table.insert(siblings, { line_num = line_num, info = current_info, line = current_line })

  -- Search downward for siblings
  i = line_num + 1
  while i <= total_lines do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
    local info = M.detect_list_format(line)

    if not info then
      -- Non-list line, stop searching downward
      break
    end

    if info.indent < target_indent then
      -- Found parent level, stop
      break
    end

    if info.indent == target_indent then
      -- Found a sibling
      table.insert(siblings, { line_num = i, info = info, line = line })
    end

    i = i + 1
  end

  return siblings
end

-- Cycle list format for sibling elements only
M.cycle_sibling_list_format = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_num = cursor[1]
  local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]

  local list_info = M.detect_list_format(line)

  if not list_info then
    -- Not a list, do nothing
    return
  end

  -- Find all siblings at the same indent level
  local siblings = find_siblings(line_num, list_info.indent)

  if #siblings == 0 then
    return
  end

  -- Determine the next format
  local new_type, new_marker = get_next_format(list_info)

  -- Update all siblings
  local number_counter = 1
  for _, sibling in ipairs(siblings) do
    local new_line =
      convert_list_format(sibling.line, sibling.info, new_type, new_marker, number_counter)
    vim.api.nvim_buf_set_lines(0, sibling.line_num - 1, sibling.line_num, false, { new_line })

    if new_type == "ordered" then
      number_counter = number_counter + 1
    end
  end
end

-- Find all list items in a contiguous block
local find_contiguous_list_block = function(line_num)
  local items = {}
  local total_lines = vim.api.nvim_buf_line_count(0)

  -- Search upward
  local i = line_num - 1
  while i >= 1 do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
    local info = M.detect_list_format(line)

    if not info then
      -- Non-list line, stop searching upward
      break
    end

    table.insert(items, 1, { line_num = i, info = info, line = line })
    i = i - 1
  end

  -- Add current line
  local current_line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]
  local current_info = M.detect_list_format(current_line)
  table.insert(items, { line_num = line_num, info = current_info, line = current_line })

  -- Search downward
  i = line_num + 1
  while i <= total_lines do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1]
    local info = M.detect_list_format(line)

    if not info then
      -- Non-list line, stop searching downward
      break
    end

    table.insert(items, { line_num = i, info = info, line = line })
    i = i + 1
  end

  return items
end

-- Cycle list format for all elements in the contiguous list block
M.cycle_all_list_format = function()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_num = cursor[1]
  local line = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]

  local list_info = M.detect_list_format(line)

  if not list_info then
    -- Not a list, do nothing
    return
  end

  -- Find all items in the contiguous list block
  local items = find_contiguous_list_block(line_num)

  if #items == 0 then
    return
  end

  -- Determine the next format based on the current line
  local new_type, new_marker = get_next_format(list_info)

  -- Track number counter per indent level for ordered lists
  local number_counters = {}

  -- Update all items
  for _, item in ipairs(items) do
    -- Reset counter when moving back to parent level
    local indent_key = item.info.indent
    if new_type == "ordered" then
      if not number_counters[indent_key] then
        number_counters[indent_key] = 1
      end
    end

    local number = number_counters[indent_key] or 1
    local new_line = convert_list_format(item.line, item.info, new_type, new_marker, number)
    vim.api.nvim_buf_set_lines(0, item.line_num - 1, item.line_num, false, { new_line })

    if new_type == "ordered" then
      number_counters[indent_key] = number_counters[indent_key] + 1
    end
  end
end

return M
