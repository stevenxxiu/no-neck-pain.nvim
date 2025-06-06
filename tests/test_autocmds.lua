local Helpers = dofile("tests/helpers.lua")

local child = Helpers.new_child_neovim()

local T = MiniTest.new_set({
    hooks = {
        -- This will be executed before every (even nested) case
        pre_case = function()
            -- Restart child process with custom 'init.lua' script
            child.restart({ "-u", "scripts/minimal_init.lua" })
        end,
        -- This will be executed one after all tests from this set are finished
        post_once = child.stop,
    },
})

T["auto command"] = MiniTest.new_set()

T["auto command"]["does not create side buffers window's width < options.width"] = function()
    child.lua([[ require('no-neck-pain').setup({width=1000}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1000 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
    })
end

T["auto command"]["starts the plugin on VimEnter"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "enabled", true)
end

T["auto command"]["disabling clears VimEnter autocmd"] = function()
    child.restart({ "-u", "scripts/init_auto_open.lua" })
    child.nnp()
    child.wait()

    -- errors because it doesn't exist
    Helpers.expect.error(function()
        child.api.nvim_get_autocmds({ group = "NoNeckPainVimEnterAutocmd" })
    end)
end

T["auto command"]["does not shift when opening/closing float window"] = function()
    child.lua([[ require('no-neck-pain').setup({width=50}) ]])
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.left", 13, 15)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.right", 13, 15)

    child.api.nvim_open_win(
        0,
        true,
        { width = 100, height = 100, relative = "cursor", row = 0, col = 0 }
    )

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002, 1003 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.left", 13, 15)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.right", 13, 15)

    -- Close float window keeps the buffer here with the same width
    child.fn.win_gotoid(1003)
    child.cmd("q")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.state(child, "tabs[1].wins.main", {
        curr = 1000,
        left = 1001,
        right = 1002,
    })

    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.left", 13, 15)
    Helpers.expect.buf_width_in_range(child, "_G.NoNeckPain.state.tabs[1].wins.main.right", 13, 15)
end

T["skipEnteringNoNeckPainBuffer"] = MiniTest.new_set()

T["skipEnteringNoNeckPainBuffer"]["goes to new valid buffer when entering side"] = function()
    child.lua(
        [[ require('no-neck-pain').setup({width=50, autocmds = { skipEnteringNoNeckPainBuffer = true }}) ]]
    )
    child.nnp()

    Helpers.expect.config(child, "autocmds.skipEnteringNoNeckPainBuffer", true)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1001)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1002)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.cmd("split")

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1003, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1003)

    child.fn.win_gotoid(1000)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1003)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1003)

    child.fn.win_gotoid(1001)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1002)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1003)
end

T["skipEnteringNoNeckPainBuffer"]["handles ltr and rtl on many buffers"] = function()
    child.lua(
        [[ require('no-neck-pain').setup({width=50, autocmds = { skipEnteringNoNeckPainBuffer = true }}) ]]
    )
    child.nnp()

    Helpers.expect.config(child, "autocmds.skipEnteringNoNeckPainBuffer", true)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.cmd("top new")
    child.cmd("top new")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1003, 1001, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1004)

    child.fn.win_gotoid(1003)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1003)

    child.fn.win_gotoid(1001)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1000)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1001)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1003)
end

T["skipEnteringNoNeckPainBuffer"]["does not register if scratchPad feature is enabled (global)"] = function()
    child.lua(
        [[ require('no-neck-pain').setup({width=50, buffers = { scratchPad = { enabled = true } }, autocmds = { skipEnteringNoNeckPainBuffer = true }}) ]]
    )
    child.nnp()

    Helpers.expect.config(child, "buffers.left.scratchPad.enabled", true)
    Helpers.expect.config(child, "buffers.right.scratchPad.enabled", true)
    Helpers.expect.config(child, "autocmds.skipEnteringNoNeckPainBuffer", true)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1001)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1001)
end

T["skipEnteringNoNeckPainBuffer"]["does not register if scratchPad feature is enabled (left)"] = function()
    child.lua(
        [[ require('no-neck-pain').setup({width=50, buffers = { left = { scratchPad = { enabled = true } } }, autocmds = { skipEnteringNoNeckPainBuffer = true }}) ]]
    )
    child.nnp()

    Helpers.expect.config(child, "buffers.left.scratchPad.enabled", true)
    Helpers.expect.config(child, "buffers.right.scratchPad.enabled", false)
    Helpers.expect.config(child, "autocmds.skipEnteringNoNeckPainBuffer", true)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1001)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1001)
end

T["skipEnteringNoNeckPainBuffer"]["does not register if scratchPad feature is enabled (right)"] = function()
    child.lua(
        [[ require('no-neck-pain').setup({width=50, buffers = { right = { scratchPad = { enabled = true } } }, autocmds = { skipEnteringNoNeckPainBuffer = true }}) ]]
    )
    child.nnp()

    Helpers.expect.config(child, "buffers.left.scratchPad.enabled", false)
    Helpers.expect.config(child, "buffers.right.scratchPad.enabled", true)
    Helpers.expect.config(child, "autocmds.skipEnteringNoNeckPainBuffer", true)

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.fn.win_gotoid(1001)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1001)
end

T["skipEnteringNoNeckPainBuffer"]["one side only + full width split doesn't bring back to original position"] = function()
    child.lua(
        [[ require('no-neck-pain').setup({width=50, autocmds = { skipEnteringNoNeckPainBuffer = true }, buffers = { right = { enabled = false }}}) ]]
    )
    child.nnp()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.cmd("botright new")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1002)

    child.fn.win_gotoid(1001)
    child.wait()
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)
end

T["skipEnteringNoNeckPainBuffer"]["does not reroute to invalid windows"] = function()
    child.lua(
        [[ require('no-neck-pain').setup({width=50, autocmds = { skipEnteringNoNeckPainBuffer = true }}) ]]
    )
    child.nnp()

    child.cmd("e foo")
    child.wait()
    child.cmd("e bar")
    child.wait()

    Helpers.expect.equality(child.get_wins_in_tab(), { 1001, 1000, 1002 })
    Helpers.expect.equality(child.api.nvim_get_current_win(), 1000)

    child.cmd("bd")
    child.wait()

    if child.fn.has("nvim-0.10") == 0 then
        Helpers.expect.equality(child.get_wins_in_tab(), { 1004, 1003, 1005 })
        Helpers.expect.equality(child.api.nvim_get_current_win(), 1003)
    else
        Helpers.expect.equality(child.get_wins_in_tab(), { 1005, 1004, 1006 })
        Helpers.expect.equality(child.api.nvim_get_current_win(), 1004)
    end
end

return T
