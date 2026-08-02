// close everything except the tab in front.
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
