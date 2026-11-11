---
description: Report and fix something broken in the game
---

The owner is reporting a bug: $ARGUMENTS

1. If the description is missing or vague, ask at most two short questions: what they did, what they expected, what happened instead. Ask them to paste any red text from Godot's Output or Debugger panel.
2. Reproduce it yourself if you can (headless run, or reading the code path). Find the **root cause** before changing anything. Don't patch the symptom.
3. Fix it with the smallest sensible change. If the bug is in the law system, add a test in `tests/` that would have caught it.
4. Run the headless import check (and tests if relevant).
5. Explain in plain language what was wrong (one sentence) and give exact steps to confirm the fix.
6. After they confirm, commit with `fix: ...`.
