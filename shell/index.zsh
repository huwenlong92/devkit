export PATH="$DEVKIT/bin:$PATH"

for f in "$DEVKIT"/shell/*.zsh; do
  [ "${f:t}" = "index.zsh" ] && continue
  [ -f "$f" ] && source "$f"
done
