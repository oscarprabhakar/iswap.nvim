local queries = require('nvim-treesitter.query')
local ui = require('iswap.ui')
local internal = require('iswap.internal')
local ts_utils = require('nvim-treesitter.ts_utils')
local default_config = require('iswap.defaults')
local util = require('iswap.util')
local err = util.err

local M = {}

M.config = default_config

function M.setup(config)
  M.config = setmetatable(config, { __index = default_config })
end

function M.evaluate_config(config)
  return config and setmetatable(config, {__index = M.config}) or M.config
end

function M.init()
  require 'nvim-treesitter'.define_modules {
    iswap = {
      module_path = 'iswap.internal',
      is_supported = function(lang)
        return queries.get_query(lang, 'iswap-list') ~= nil
      end
    }
  }
end

function M.iswap(config)
  config = M.evaluate_config(config)
  local bufnr = vim.api.nvim_get_current_buf()
  local winid = vim.api.nvim_get_current_win()

  local parent = internal.get_list_node_at_cursor(winid, config)
  if not parent then
    err('did not find a satisfiable parent node', config.debug)
    return
  end
  local children = ts_utils.get_named_children(parent)
  local sr, sc, er, ec = parent:range()
  -- a and b are the nodes to swap
  local user_input = ui.prompt(bufnr, config, children, {{sr, sc}, {er, ec}}, 2)
  if not (type(user_input) == 'table' and #user_input == 2) then
    err('did not get two valid user inputs', config.debug)
    return
  end
  local a, b = unpack(user_input)
  if a == nil or b == nil then
    err('some of the nodes were nil', config.debug)
    return
  end
  ts_utils.swap_nodes(a, b, bufnr)
end

-- TODO: refactor iswap() and iswap_with()
-- swap current with one other node
function M.iswap_with(config)
  config = M.evaluate_config(config)
  local bufnr = vim.api.nvim_get_current_buf()
  local winid = vim.api.nvim_get_current_win()

  local parent = internal.get_list_node_at_cursor(winid, config)
  if not parent then
    err('did not find a satisfiable parent node', config.debug)
    return
  end
  local children = ts_utils.get_named_children(parent)


  local cur_nodes = util.nodes_containing_cursor(children)
  if #cur_nodes == 0 then
    err('not on a node!', 1)
  end

  if #cur_nodes > 1 then
    err('multiple found, using first', config.debug)
  end

  local cur_node = children[cur_nodes[1]]
  table.remove(children, cur_nodes[1])

  local sr, sc, er, ec = parent:range()
  -- a and b are the nodes to swap
  local user_input = ui.prompt(bufnr, config, children, {{sr, sc}, {er, ec}}, 1)
  if not (type(user_input) == 'table' and #user_input == 1) then
    err('did not get two valid user inputs', config.debug)
    return
  end
  local a = unpack(user_input)
  if a == nil then
    err('the node was nil', config.debug)
    return
  end
  ts_utils.swap_nodes(a, cur_node, bufnr)
end

return M
