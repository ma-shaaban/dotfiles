-- Upgrade every installed Mason package to the registry's latest version.
-- Run by scripts/nvim.sh after the config loads: nvim --headless -c "luafile ..."
require("lazy").load({ plugins = { "mason.nvim" } })
local registry = require("mason-registry")

local done = false
registry.update(function() done = true end)
vim.wait(120000, function() return done end, 200)

local pending, failed = 0, {}
for _, pkg in ipairs(registry.get_installed_packages()) do
  local have, latest = pkg:get_installed_version(), pkg:get_latest_version()
  if have ~= latest and not pkg:is_installing() then
    pending = pending + 1
    print(("mason: %s %s -> %s"):format(pkg.name, have or "?", latest))
    pkg:install({}, function(ok)
      if not ok then table.insert(failed, pkg.name) end
      pending = pending - 1
    end)
  end
end
vim.wait(600000, function() return pending == 0 end, 500)

-- The config's ensure_installed may have queued missing tools at startup;
-- let those finish too instead of aborting them on exit.
vim.wait(3000)
vim.wait(600000, function()
  for _, pkg in ipairs(registry.get_all_packages()) do
    if pkg:is_installing() then return false end
  end
  return true
end, 1000)

if #failed > 0 then
  print("mason: failed: " .. table.concat(failed, ", "))
  vim.cmd("cq")
end
