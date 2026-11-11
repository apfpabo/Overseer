---
description: Build the next roadmap task as one small, testable step
---

Work on the next unchecked task in `docs/ROADMAP.md` (or the task the owner names: $ARGUMENTS).

1. Re-read the relevant parts of `docs/ARCHITECTURE.md` and `docs/CONVENTIONS.md`.
2. If the task is big, split it and do only the first visible, testable piece now.
3. Implement it following the conventions (static typing, data in `data/`, placeholders from `scripts/util/palette.gd`).
4. Run the headless import check and, if the law system was touched, the tests. Fix everything you broke.
5. Update `docs/ARCHITECTURE.md` if you added a system, autoload or folder.
6. Hand over in plain language:
   - **What changed** (1–3 bullets, no jargon)
   - **How to test** (exact clicks/keys after pressing F5, and what they should see)
   - **What's next**
7. Wait for the owner's result. When they confirm it works, tick the task in `docs/ROADMAP.md` and commit.
