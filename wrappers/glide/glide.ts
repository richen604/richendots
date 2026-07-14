/// <reference path="./glide.d.ts" />

// Stay close to Glide defaults while making keymaps robust across layouts.
glide.g.mapleader = "<Space>";
glide.o.keyboard_layout = "qwerty";
glide.o.keymaps_use_physical_layout = "force";

glide.o.which_key_delay = 200;
glide.o.hint_size = "12px";
glide.o.yank_highlight = "#a6e3a1";
glide.o.yank_highlight_time = 180;

glide.keymaps.set("command", "<C-j>", "commandline_focus_next");
glide.keymaps.set("command", "<C-k>", "commandline_focus_back");

glide.keymaps.set("normal", "<leader>ce", "config_edit", {
  description: "edit Glide config",
});
glide.keymaps.set("normal", "<leader>cr", "config_reload", {
  description: "reload Glide config",
});
glide.keymaps.set("normal", "<leader>cp", "config_path", {
  description: "show Glide config path",
});
