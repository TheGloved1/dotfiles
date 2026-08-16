# TMUX: open a new session if none exists, or a window in the existing session
tmux() {
  if [ -z $TMUX ]; then
    if command tmux has-session -t TMUX 2>/dev/null; then
      command tmux new-window -t TMUX
      command tmux attach -t TMUX
    else
      command tmux new -s TMUX
    fi
  fi
}