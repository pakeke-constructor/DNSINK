
LuaLS Annotations:

- When defining a function, use LuaLS annotations.
- It's very important to annotate function parameters. Annotating function parameters are more important than annotating the return value.
- Quick scrappy local functions don't neccessarily need annotations, especially if they use simple parameters like `x, y` which are clearly numbers.
- For tables, feel free to use `---@type T[]` or `table<K, V>` depending on the contents of the table.

