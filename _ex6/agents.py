


from _ex6.models import M
from _ex6.code_mode import make_code_mode_system_prompt
from _ex6.tools import read_headers, read_body, glob, search, write_file, edit_file, read_file, edit_file_lines, escalate, bash, explore_agent, CLAUDE_MD, ENV_PROMPT, git_working_tree
from _ex6.tools_checkpoints import checkpoint_list, checkpoint, condense
from _ex6.skills import load_skill
from _ex6.lua_coding_style import SYSTEM_PROMPT_CODING_STYLE
from _ex6.tasks import plan_add_log, plan_done, plan_list, plan_read, plan_write
from _ex6.web.web_tools import web_search, websearch_agent
from _ex6.love2d_docs.love2d_docs import love2d_docs
from _ex6.provider import cache_manually
import ex6
from ex6 import Context, Message



MAIN_SYSTEM_PROMPT = ex6.Message(
role ="system",
overview="main-system",
content="""\
You are a coding agent working alongside an experienced engineer in a terminal UI.

<goal>
Solve user request with minimal bloat.
Prefer direct implementation path.
</goal>

<agent_strategy>
- Understand request, constraints, user intent first.
- Map out problem + solution, and discover more about the codebase. Prioritize read_headers.
- Complete changes: write code, edit files.

Always check changes afterwards. (Check git diff, run tests, or read file(s).)
</agent_strategy>

<agent_tactics>
- Try the simplest approach first. Don't overthink.
- Tool call(s) to verify, then act. Don't read the whole codebase before a 2-line edit.
- If a search returns what you need, stop searching. Don't keep exploring "just in case."
- If your approach is blocked, don't brute force. Step back, try a different angle, or ask.
- Avoid backwards-compatibility hacks. If something is unused, delete it.
</agent_tactics>

<output_rules>
Plain text only. No markdown headers, no tables, no emojis. Short lines.
DO NOT explain your reasoning or thinking process. DO NOT narrate what you are about to do or what you just did.
When you have tool calls to make, make them IMMEDIATELY — no preamble, no "Let me look at...", no "I'll now...".
After tool calls, say nothing unless there's a result to report or a question to ask.
The ONLY acceptable text output is: a direct answer, a clarifying question, or a blocker.
</output_rules>

<code_editing_rules>
- Don't add features, refactor, docstrings, comments, beyond what was asked.
- Don't add error handling for scenarios that can't happen.
- You MUST add type annotations to variables/APIs that are exposed. For functions that are local, and the meaning is clear, no need to annotate; best not to bloat the code.
- Three similar lines > premature abstraction.
</code_editing_rules>

<working_style>
- Read code before modifying it. Never propose changes to code you haven't seen.
- Before using an API or module, look up the actual definition first.
- Write the simplest code that works. Avoid over-engineering, unnecessary abstractions, and speculative features.
- Prefer editing existing files over creating new ones.
- You MUST use explore_agent for broad codebase questions; it's a lot cheaper than exploring yourself.
</working_style>
"""
)




# SMART_MODEL = "openai/gpt-5.2-codex"
# SMART_MODEL = "openai/gpt-5.1-codex-mini"
# SMART_MODEL = M.SONNET_46.id



CODING_STYLE_PROMPT = ex6.Message(role="system", overview="coding-style", content=SYSTEM_PROMPT_CODING_STYLE)



CODE_MODE_SYS_PROMPT = make_code_mode_system_prompt([
    read_file, glob, search, read_headers, read_body,
    write_file, edit_file, edit_file_lines,
    explore_agent, web_search, websearch_agent,
    plan_done, plan_read, plan_write,
    git_working_tree,
    love2d_docs,
    load_skill
])


EX6_MD = ex6.Message(role="system", content=open("EX6.md","r").read(), overview="EX6.md")


coder = Context("c_opus", yolo=False, model=M.OPUS_LATEST.id, reasoning="high", messages=[
    MAIN_SYSTEM_PROMPT,
    CODE_MODE_SYS_PROMPT,
    ENV_PROMPT,
    # CODING_STYLE_PROMPT,
    EX6_MD,
])
cache_manually(coder)



coder = Context("c_codex", yolo=False, model=M.CODEX_LATEST.id, reasoning="high", messages=[
    MAIN_SYSTEM_PROMPT,
    CODE_MODE_SYS_PROMPT,
    ENV_PROMPT,
    # CODING_STYLE_PROMPT,
    EX6_MD,
])


coder = Context("c_gem", yolo=False, model=M.GEMINI_LATEST.id, reasoning="high", messages=[
    MAIN_SYSTEM_PROMPT,
    CODE_MODE_SYS_PROMPT,
    ENV_PROMPT,
    # CODING_STYLE_PROMPT,
    EX6_MD,
])




OMNI_PROMPT = ex6.Message(role = "system", 
tools = [read_file, read_headers, search, glob,],
content="""
You have a specialized skill, on top of your existing coding abilities:
*You can see other codebases*.

As such, your main tasks will involve bringing code over from other codebases,
or learning about other codebases in order to write better code in this codebase.
""")

# TODO: it makes a LOT of sense to extract OMNI-AGENT into core ex6.
# Then we can reuse it for other stuff
# IDEA:
# . 
# new_omni_agent({
#     core_project = "army_game",
#     projects = {
#         "army_game": ("C:\\path...", "Army-game is a .... blah blah"),
#         "ex6": ("C:\\path...", "ex6 is ... blah blah"),
#         ...
#     }
# })
# With this, we can reuse the idea of omni-agent across multiple projects.


# coder = Context("c_omni", yolo=False, model=M.GPT53_CODEX.id, reasoning="medium", messages=[
#     MAIN_SYSTEM_PROMPT,
#     OMNI_PROMPT,
#     ENV_PROMPT,
# ])




ex6.state.current = coder


