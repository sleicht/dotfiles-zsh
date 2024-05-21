return {
	{
		"nvim-telescope/telescope.nvim",
		opts = {
			defaults = {
				vimgrep_arguments = {
					"rg",
					"--vimgrep",
					"--hidden",
					"--follow",
				},
			},
		},
	},
}
