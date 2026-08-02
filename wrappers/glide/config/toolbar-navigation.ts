// reveal the hidden toolbar only while entering a url.
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

// manually show or hide the browser toolbar.
glide.keymaps.set("normal", "<leader>ub", () => {
  document.documentElement.toggleAttribute(toolbar_attribute);
}, { description: "toggle browser toolbar" });
