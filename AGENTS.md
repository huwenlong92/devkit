# Agent Notes

- Treat `/Users/huwenlong/data/lab/devkit` as the writable development workspace for this project.
- Do not modify `/Users/huwenlong/devkit` by default. That directory is the user's installed DevKit and must remain clean so `devkit refresh` / `git pull` can work.
- If the user explicitly allows debugging in `/Users/huwenlong/devkit` or other user-home paths, keep changes temporary, restore them before finishing, and verify `git -C /Users/huwenlong/devkit status --short` is clean.
- Prefer validating fixes from the development workspace. Ask before syncing files into the user's installed DevKit.
