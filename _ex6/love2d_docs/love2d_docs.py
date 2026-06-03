
'''
Love2D API documentation lookup tool for coding agents.

Parses the love2d API (from love2d_docs.json) into typed dataclasses,
and exposes a single `love2d_docs(query, verbosity)` function for lookup.
Agents can quickly check function signatures, object methods, and module
contents without reading the massive JSON directly.

Usage:
  love2d_docs("love.graphics")           -- list all functions/types in a module
  love2d_docs("love.graphics.newCanvas")  -- look up a specific function
  love2d_docs("love.audio.newSource")     -- look up a specific function
  love2d_docs("Canvas")                   -- look up a type and its methods
  love2d_docs("Canvas:getFilter")         -- look up a specific method on a type

Verbosity:
  0 (default) -- signatures only, concise. Good for browsing.
  1           -- full descriptions, all variants, argument details.

Example output (verbosity=0):
  love2d_docs("love.graphics.rectangle")
  => rectangle(mode: DrawMode, x: number, y: number, width: number, height: number)
     rectangle(mode: DrawMode, x: number, y: number, width: number, height: number, rx: number, ry: number)

  love2d_docs("Canvas")
  => Canvas
     Supertypes: Texture, Drawable, Object
       getFilter() -> min, mag, anisotropy
       getDimensions() -> width, height
       ...
'''


from __future__ import annotations
from dataclasses import dataclass, field
import json, os
import ex6


@dataclass
class Argument:
    name: str = ""
    type: str = ""
    description: str = ""
    default: str = ""
    table: list[Argument] = field(default_factory=list)


@dataclass
class ReturnValue:
    name: str = ""
    type: str = ""
    description: str = ""


@dataclass
class Variant:
    description: str = ""
    arguments: list[Argument] = field(default_factory=list)
    returns: list[ReturnValue] = field(default_factory=list)

    def sig(self, name: str):
        args = ", ".join(f"{a.name}: {a.type}" for a in self.arguments)
        ret = ""
        if self.returns:
            ret = " -> " + ", ".join(r.type for r in self.returns)
        return f"{name}({args}){ret}"

    def fmt(self):
        lines = []
        if self.description:
            lines.append(self.description)
        if self.arguments:
            lines.append("  Arguments:")
            for a in self.arguments:
                lines.append(f"    {a.name} ({a.type or '?'}): {a.description}")
        if self.returns:
            lines.append("  Returns:")
            for r in self.returns:
                lines.append(f"    {r.name} ({r.type or '?'}): {r.description}")
        return "\n".join(lines)


@dataclass
class Function:
    name: str = ""
    description: str = ""
    variants: list[Variant] = field(default_factory=list)

    def fmt(self, verbosity: int = 0):
        if verbosity == 0:
            return "\n".join(v.sig(self.name) for v in self.variants)
        lines = [f"{self.name}: {self.description}"]
        for i, v in enumerate(self.variants):
            if len(self.variants) > 1:
                lines.append(f"  Variant {i+1}: {v.sig(self.name)}")
            lines.append(v.fmt())
        return "\n".join(lines)


@dataclass
class EnumConstant:
    name: str = ""
    description: str = ""


@dataclass
class Enum:
    name: str = ""
    description: str = ""
    constants: list[EnumConstant] = field(default_factory=list)


@dataclass
class LoveType:
    name: str = ""
    description: str = ""
    supertypes: list[str] = field(default_factory=list)
    functions: list[Function] = field(default_factory=list)
    constructors: list[str] = field(default_factory=list)

    def fmt(self, verbosity: int = 0):
        if verbosity == 0:
            lines = [self.name]
            if self.supertypes:
                lines.append(f"Supertypes: {', '.join(self.supertypes)}")
            for fn in self.functions:
                lines.append(f"  {fn.variants[0].sig(fn.name) if fn.variants else fn.name}")
            return "\n".join(lines)
        lines = [f"{self.name}: {self.description}"]
        if self.supertypes:
            lines.append(f"Supertypes: {', '.join(self.supertypes)}")
        fns = [f.name for f in self.functions]
        if fns:
            lines.append(f"Methods: {', '.join(fns)}")
        return "\n".join(lines)


@dataclass
class Module:
    name: str = ""
    description: str = ""
    functions: list[Function] = field(default_factory=list)
    types: list[LoveType] = field(default_factory=list)
    enums: list[Enum] = field(default_factory=list)

    def fmt(self, verbosity: int = 0):
        if verbosity == 0:
            lines = [f"love.{self.name}"]
            for fn in self.functions:
                lines.append(f"  {fn.variants[0].sig(fn.name) if fn.variants else fn.name}")
            if self.types:
                lines.append(f"Types: {', '.join(t.name for t in self.types)}")
            if self.enums:
                lines.append(f"Enums: {', '.join(e.name for e in self.enums)}")
            return "\n".join(lines)
        lines = [f"love.{self.name}: {self.description}"]
        fns = [f.name for f in self.functions]
        if fns:
            lines.append(f"Functions: {', '.join(fns)}")
        types = [t.name for t in self.types]
        if types:
            lines.append(f"Types: {', '.join(types)}")
        enums = [e.name for e in self.enums]
        if enums:
            lines.append(f"Enums: {', '.join(enums)}")
        return "\n".join(lines)


@dataclass
class LoveAPI:
    version: str = ""
    functions: list[Function] = field(default_factory=list)
    modules: list[Module] = field(default_factory=list)
    types: list[LoveType] = field(default_factory=list)
    callbacks: list[Function] = field(default_factory=list)


def _make(cls, data):
    """Recursively construct a dataclass from a dict."""
    if not isinstance(data, dict):
        return data
    hints = cls.__dataclass_fields__
    kwargs = {}
    for k, v in data.items():
        if k not in hints:
            continue
        ft = hints[k].type
        if isinstance(v, list):
            # resolve the inner type from e.g. "list[Argument]"
            inner = _resolve_type(ft)
            if inner and hasattr(inner, '__dataclass_fields__'):
                kwargs[k] = [_make(inner, item) for item in v]
            else:
                kwargs[k] = v
        elif isinstance(v, dict):
            inner = _resolve_type(ft)
            if inner and hasattr(inner, '__dataclass_fields__'):
                kwargs[k] = _make(inner, v)
            else:
                kwargs[k] = v
        else:
            kwargs[k] = v
    return cls(**kwargs)


_TYPE_MAP = {
    'Argument': Argument, 'ReturnValue': ReturnValue, 'Variant': Variant,
    'Function': Function, 'EnumConstant': EnumConstant, 'Enum': Enum,
    'LoveType': LoveType, 'Module': Module, 'LoveAPI': LoveAPI,
}

def _resolve_type(type_str: str):
    """Extract inner class from type strings like 'list[Function]' or 'Function'."""
    m = __import__('re').match(r'list\[(\w+)\]', type_str)
    if m:
        return _TYPE_MAP.get(m.group(1))
    return _TYPE_MAP.get(type_str)


JSON_PATH = os.path.join(os.path.dirname(__file__), "love2d_docs.json")

with open(JSON_PATH, "r") as f:
    _DATA: LoveAPI = _make(LoveAPI, json.load(f))

# Build lookup indices
_MODULES: dict[str, Module] = {m.name: m for m in _DATA.modules}
_TYPES: dict[str, LoveType] = {}
for t in _DATA.types:
    _TYPES[t.name] = t
for mod in _DATA.modules:
    for t in mod.types:
        _TYPES[t.name] = t


def love2d_docs(ctx: ex6.Context, query: str, verbosity: int = 0):
    """
    Look up Love2D API docs. Returns signatures, descriptions, and method lists.
    You MUST use this
    query formats:
      love2d_docs("love.graphics")            - list module functions, types, enums
      love2d_docs("love.graphics.newCanvas")  - look up a specific function
      love2d_docs("Canvas")                   - look up a class/object and list its methods
      love2d_docs("Canvas:getFilter")         - look up a specific method on a type
    verbosity: 0 = signatures only (default), 1 = full descriptions + argument details."""
    parts = query.split(".")

    if parts[0] == "love" and len(parts) == 2:
        mod = _MODULES.get(parts[1])
        if mod:
            return mod.fmt(verbosity)
        return f"Module '{parts[1]}' not found"

    if parts[0] == "love" and len(parts) == 3:
        mod = _MODULES.get(parts[1])
        if not mod:
            return f"Module '{parts[1]}' not found"
        for fn in mod.functions:
            if fn.name == parts[2]:
                return fn.fmt(verbosity)
        return f"Function '{parts[2]}' not found in love.{parts[1]}"

    # Type or Type:method
    if ":" in query:
        type_name, method_name = query.split(":", 1)
        t = _TYPES.get(type_name)
        if not t:
            return f"Type '{type_name}' not found"
        for fn in t.functions:
            if fn.name == method_name:
                return fn.fmt(verbosity)
        return f"Method '{method_name}' not found on {type_name}"

    # Plain type name
    t = _TYPES.get(query)
    if t:
        return t.fmt(verbosity)

    return f"'{query}' not found"


# Quick smoke test when run directly
if __name__ == "__main__":
    print("=== love.graphics v0 ===")
    print(love2d_docs(None, "love.graphics")[:600])
    print()
    print("=== love.graphics.newCanvas v0 ===")
    print(love2d_docs(None, "love.graphics.newCanvas"))
    print()
    print("=== love.graphics.newCanvas v1 ===")
    print(love2d_docs(None, "love.graphics.newCanvas", 1))
    print()
    print("=== Canvas v0 ===")
    print(love2d_docs(None, "Canvas"))
    print()
    print("=== Canvas:getFilter v0 ===")
    print(love2d_docs(None, "Canvas:getFilter"))
    print()
    print("=== Canvas:getFilter v1 ===")
    print(love2d_docs(None, "Canvas:getFilter", 1))
