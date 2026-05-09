-- AstroNvim plugins configuration

require("lazy").setup({
	{
		"AstroNvim/AstroNvim",
		version = "^5",
		import = "astronvim.plugins",
		opts = {
			mapleader = " ",
			maplocalleader = ",",
			icons_enabled = true,
			pin_plugins = nil,
			update_notifications = true,
			sessions = {
				autosave = {
					last = true,
					cwd = true,
				},
			},
		},
	},
	{
		"AstroNvim/astrocore",
	},
	{
		"AstroNvim/astrolsp",
	},
	{
		"nvimtools/none-ls.nvim",
	},

	{
		"AstroNvim/astroui",
		opts = {
			colorscheme = "tokyonight-night",
		},
	},

	{
		"AstroNvim/astrocommunity",
		{ import = "astrocommunity.pack.lua" },
		{ import = "astrocommunity.color.transparent-nvim" },
		{ import = "astrocommunity.colorscheme.tokyonight-nvim" },
		{ import = "astrocommunity.media.cord-nvim" },
		{ import = "astrocommunity.ai.opencode-nvim" },
		{ import = "astrocommunity.git.codediff-nvim" },
		{ import = "astrocommunity.note-taking.obisidan-nvim" },
		{ import = "astrocommunity.terminal-integration.vim-tmux-navigator" },
		{ import = "astrocommunity.terminal-integration.floaterm" },
		{ import = "astrocommunity.workflow.bad-practices-nvim" },
		{ import = "astrocommunity.split-and-window.neominimap-nvim" },
		{ import = "astrocommunity.recipes.ai" },
		{ import = "astrocommunity.pack.godot" },
	},

	-- Additional plugins that need to be fetched from GitHub
	{
		"ray-x/lsp_signature.nvim",
		event = "BufRead",
		config = function()
			require("lsp_signature").setup()
		end,
	},

	{
		"folke/snacks.nvim",
		opts = {
			dashboard = {
				preset = {
					header = table.concat({
						"           __            __                                       __               ",
						"          /  |          /  |                                     /  |              ",
						"  ______  $$/   _______ $$ |____    ______   _______   __     __ $$/  _____  ____  ",
						" /      \\ /  | /       |$$      \\  /      \\ /       \\ /  \\   /  |/  |/     \\/    \\ ",
						"/$$$$$$  |$$ |/$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$  |$$  \\ /$$/ $$ |$$$$$$ $$$$  |",
						"$$ |  $$/ $$ |$$ |      $$ |  $$ |$$    $$ |$$ |  $$ | $$  /$$/  $$ |$$ | $$ | $$ |",
						"$$ |      $$ |$$ \\_____ $$ |  $$ |$$$$$$$$/ $$ |  $$ |  $$ $$/   $$ |$$ | $$ | $$ |",
						"$$ |      $$ |$$       |$$ |  $$ |$$       |$$ |  $$ |   $$$/    $$ |$$ | $$ | $$ |",
						"$$/       $$/  $$$$$$$/ $$/   $$/  $$$$$$$/ $$/   $$/     $/     $$/ $$/  $$/  $$/ ",
					}, "\n"),
				},
			},
		},
	},

	-- {
	--   "nvim-treesitter/nvim-treesitter",
	--   opts = {
	--     ensure_installed = {
	--       "lua",
	--       "vim",
	--     },
	--   },
	-- },

	-- Mason tool installer (automatic installation of LSP servers, formatters, linters)
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		opts = {
			ensure_installed = {
				-- LSP servers
				"lua-language-server",
				"bash-language-server",
				"json-lsp",
				"yaml-language-server",
				"marksman",
				"rust-analyzer",
				"clangd",
				"nil",
				-- Formatters
				"prettier",
				"stylua",
				"shfmt",
				"nixpkgs-fmt",
				-- Linters
				"markdownlint",
				"shellcheck",
				-- Debuggers
				-- "debugpy",
				-- Other tools
				-- "tree-sitter-cli",
			},
			auto_update = true,
			run_on_start = true,
			start_on_start = true,
		},
	},
}, {
	performance = {
		rtp = {
			disabled_plugins = {
				"gzip",
				"netrwPlugin",
				"tarPlugin",
				"tohtml",
				"zipPlugin",
			},
		},
	},
})
