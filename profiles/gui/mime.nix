let
  defaultMimeApplications = {
    "inode/directory" = "yazi-kitty.desktop";
    "text/plain" = "nvim.desktop";
    "text/markdown" = "nvim.desktop";
    "text/x-markdown" = "nvim.desktop";
    "text/csv" = "nvim.desktop";
    "text/css" = "nvim.desktop";
    "text/xml" = "nvim.desktop";
    "application/json" = "nvim.desktop";
    "application/javascript" = "nvim.desktop";
    "application/x-shellscript" = "nvim.desktop";
    "application/pdf" = "glide.desktop";
    "application/xhtml+xml" = "glide.desktop";
    "application/xml" = "glide.desktop";
    "text/html" = "glide.desktop";
    "image/png" = "glide.desktop";
    "image/jpeg" = "glide.desktop";
    "image/gif" = "glide.desktop";
    "image/webp" = "glide.desktop";
    "image/svg+xml" = "glide.desktop";
    "video/mp4" = "glide.desktop";
    "video/webm" = "glide.desktop";
    "audio/mpeg" = "glide.desktop";
    "audio/ogg" = "glide.desktop";
    "audio/wav" = "glide.desktop";
    "x-scheme-handler/about" = "glide.desktop";
    "x-scheme-handler/http" = "glide.desktop";
    "x-scheme-handler/https" = "glide.desktop";
    "x-scheme-handler/mailto" = "glide.desktop";
    "application/zip" = "yazi-kitty.desktop";
    "application/x-tar" = "yazi-kitty.desktop";
    "application/gzip" = "yazi-kitty.desktop";
    "application/x-bzip2" = "yazi-kitty.desktop";
    "application/x-7z-compressed" = "yazi-kitty.desktop";
    "application/x-rar-compressed" = "yazi-kitty.desktop";
    "application/zstd" = "yazi-kitty.desktop";
    "application/x-xz" = "yazi-kitty.desktop";
  };
in
{
  xdg.mime = {
    defaultApplications = defaultMimeApplications;
    addedAssociations = defaultMimeApplications;
  };
}
