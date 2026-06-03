- Simplicity over ALL else.
- Less code is better. Shorter is better. Fewer files is better.
- Flat over nested. If you're 3 levels deep, refactor.
- Explicit over clever. No tricks, no one-liner heroics.
- Don't abstract until you have 3+ duplicates.
- Prefer pure functions over methods with side effects.
- Less statefulness is better. Short-lived state is best.
- Keep state as a single source of truth. Never derive state that can be computed.
- Avoid state entirely when possible; use immutable data.
- Delete dead code. Don't comment it out.

IMPORTANT: Before implementing anything non-trivial, write pseudocode comments first. Plan the shape, THEN fill it in.