# config_lib_enable=1 # set it to zero to disable
# config_lib_files=("color") # libraries should be automatically loaded from script
config_conf_createlinks=1                                                                                                            # whether automatically create a symbolic link in $HOME for this config #!TODO
config_default_confirm=1                                                                                                             # whether prompt to confirm if default value apply to the missing settings
dotfile_basepath_src="$HOME/dotfile"                                                                                                 # all the stuffs been placed, the default path prefix of genre src
dotfile_basepath_dst="$HOME"                                                                                                         # the same as above
dotfile_genre=("shell" "misc" "script" "nvim" "git" "sync" "tmux" "misc" "winnvim" "wingit" "ssh" "winssh" "nvimdata" "winnvimdata") # the type of dotfiles should tracked by script

g_shell_src_prefix="/"
g_shell_files=("zshrc" "scripts/")
g_shell_dst_prefix="/."
g_shell_osonly=0

g_misc_src_prefix="/"
g_misc_files=("condarc" "gdbinit" "tmux/")
g_misc_dst_prefix="/."
g_misc_osonly=0

g_ssh_src_prefix="/"
g_ssh_files=("ssh/")
g_ssh_dst_prefix="/."
g_ssh_osonly=2

g_winssh_src_prefix="/win-"
g_winssh_files=("ssh/")
g_winssh_dst_prefix="/."
g_winssh_osonly=1

g_script_src_prefix="/scripts/"
g_script_files=("proxy.sh")
g_script_dst_prefix="/."
g_script_osonly=0

g_nvim_src_prefix="/"
g_nvim_files=("nvim")
g_nvim_dst_prefix="/.config/"
g_nvim_osonly=2

g_winnvim_src_prefix="/"
g_winnvim_files=("nvim")
g_winnvim_dst_prefix="/AppData/Local/"
g_winnvim_osonly=1

g_nvimdata_src_prefix="/nvim-data/"
g_nvimdata_files=("site")
g_nvimdata_dst_prefix="/.local/share/nvim/"
g_nvimdata_osonly=2

g_winnvimdata_src_prefix="/nvim-data/"
g_winnvimdata_files=("site")
g_winnvimdata_dst_prefix="/AppData/Local/nvim-data/"
g_winnvimdata_osonly=1

g_git_src_prefix="/git/"
g_git_files=("gitconfig" "gitignore" "ext.gitconfig")
g_git_dst_prefix="/."
g_git_osonly=2

g_wingit_src_prefix="/win-git/"
g_wingit_files=("gitconfig" "gitignore" "ext.gitconfig")
g_wingit_dst_prefix="/."
g_wingit_osonly=1

g_sync_src_prefix="/sync/"
g_sync_files=("dotfiles.conf.sh" "sync-dotfile.sh")
g_sync_dst_prefix="/."
g_sync_osonly=0

g_tmux_src_prefix="/tmux/"
g_tmux_files=("tmux.conf" "tmux.conf.local")
g_tmux_dst_prefix="/."
g_tmux_osonly=0
