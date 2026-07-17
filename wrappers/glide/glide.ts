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

const search_url = "https://www.rebang.online/?q=";

function url_from_input(input: string): string {
  const trimmed = input.trim();
  if (/^[a-z][a-z0-9+.-]*:/i.test(trimmed)) return trimmed;
  if (/^(localhost|[\w-]+(\.[\w-]+)+)(:\d+)?([/?#].*)?$/i.test(trimmed)) {
    return `https://${trimmed}`;
  }
  return `${search_url}${encodeURIComponent(trimmed)}`;
}

glide.keymaps.set("normal", "go", async () => {
  await glide.commandline.show({
    input: glide.ctx.url.toString(),
    options: [{
      label: "open in current tab",
      matches: () => true,
      async execute({ input }) {
        if (!input.trim()) return;
        await browser.tabs.update({ url: url_from_input(input) });
      },
    }],
  });
}, { description: "open URL in current tab" });

glide.keymaps.set("normal", "gO", async () => {
  await glide.commandline.show({
    title: "open URL in new tab",
    options: [{
      label: "open in new tab",
      matches: () => true,
      async execute({ input }) {
        if (!input.trim()) return;
        await browser.tabs.create({ active: true, url: url_from_input(input) });
      },
    }],
  });
}, { description: "open URL in new tab" });

glide.keymaps.set("normal", "<leader>ce", "config_edit", {
  description: "edit Glide config",
});
glide.keymaps.set("normal", "<leader>cr", "config_reload", {
  description: "reload Glide config",
});
glide.keymaps.set("normal", "<leader>cp", "config_path", {
  description: "show Glide config path",
});
