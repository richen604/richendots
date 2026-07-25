/// <reference path="./glide.d.ts" />

// Stay close to Glide defaults while making keymaps robust across layouts.
glide.g.mapleader = "<Space>";
glide.o.keyboard_layout = "qwerty";
glide.o.keymaps_use_physical_layout = "force";

glide.o.which_key_delay = 200;
glide.o.hint_size = "12px";
glide.o.yank_highlight = "#a6e3a1";
glide.o.yank_highlight_time = 180;

// Glide's menu mode sucks. This fixes focus so input can be captured more reliably.
const command_mode = glide.modes.get("command");
if (command_mode) {
  command_mode.switch_mode_on_focus = false;
}

glide.autocmds.create("ModeChanged", "command:*", () => {
  setTimeout(() => {
    if (glide.commandline.is_active()) {
      void glide.excmds.execute("mode_change command");
    }
  }, 0);
});

glide.keymaps.set("command", "<C-j>", "commandline_focus_next");
glide.keymaps.set("command", "<C-k>", "commandline_focus_back");

const toolbar_attribute = "glide-toolbar-visible";

async function focus_location(open_new_tab = false): Promise<void> {
  const root = document.documentElement;
  const restore_hidden = !root.hasAttribute(toolbar_attribute);
  if (restore_hidden) {
    root.setAttribute(toolbar_attribute, "");
  }

  if (open_new_tab) {
    await glide.excmds.execute("tab_new");
  }

  await glide.keys.send("<C-l>", { skip_mappings: true });

  if (restore_hidden) {
    document.querySelector<HTMLInputElement>("#urlbar-input")?.addEventListener("blur", () => {
      root.removeAttribute(toolbar_attribute);
    }, { once: true });
  }
}

glide.keymaps.set("normal", "go", () => focus_location(), {
  description: "open URL in current tab",
});
glide.keymaps.set("normal", "gO", () => focus_location(true), {
  description: "open URL in new tab",
});

glide.keymaps.set("normal", "<leader>D", async () => {
  const active_tab = await glide.tabs.active();
  const tabs = await glide.tabs.query({ currentWindow: true });
  const tabs_to_close = tabs
    .map(tab => tab.id)
    .filter(id => id !== undefined && id !== active_tab.id);

  if (tabs_to_close.length > 0) {
    await browser.tabs.remove(tabs_to_close);
  }
}, { description: "close all tabs but current" });

glide.keymaps.set("normal", "<leader>ce", "config_edit", {
  description: "edit Glide config",
});
glide.keymaps.set("normal", "<leader>cr", "config_reload", {
  description: "reload Glide config",
});
glide.keymaps.set("normal", "<leader>cp", "config_path", {
  description: "show Glide config path",
});

glide.keymaps.set("normal", "<leader>ub", () => {
  document.documentElement.toggleAttribute(toolbar_attribute);
}, { description: "toggle browser toolbar" });
