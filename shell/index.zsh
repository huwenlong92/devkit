export PATH="$DEVKIT/bin:$PATH"

for f in "$DEVKIT"/shell/*.zsh; do
  [ "$(basename "$f")" = "index.zsh" ] && continue
  [ -f "$f" ] && source "$f"
done
