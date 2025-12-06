---
title: "Fish for Bash Users - Authoritative Reference"
category: documentation
component: shell
status: stable
version: 1.0.0
last_updated: 2025-11-21
tags: [fish, bash, shell, reference, migration, syntax]
priority: high
source: https://fishshell.com/docs/current/fish_for_bash_users.html
---

# Fish for Bash Users - Authoritative Reference

> **Source**: Official Fish Shell Documentation
> **Purpose**: Quick reference for bash users transitioning to fish
> **Note**: Fish is intentionally NOT POSIX-compatible

## Overview

Fish and bash share fundamental concepts (command expansion, pipes, redirections, variables, globs) but differ significantly in syntax and behavior. This document provides authoritative mappings between the two shells.

---

## Quick Reference Table

| Feature | Bash | Fish | Notes |
|---------|------|------|-------|
| **Command Substitution** | `` `cmd` `` or `$(cmd)` | `$(cmd)` or `(cmd)` | Fish only splits on newlines |
| **Variable Assignment** | `VAR=value` | `set VAR value` | Fish uses `set` builtin |
| **Export Variable** | `export VAR=value` | `set -gx VAR value` | `-g` = global, `-x` = export |
| **Local Variable** | `local var=value` | `set -l var value` | `-l` = local scope |
| **Unset Variable** | `unset VAR` | `set -e VAR` | `-e` = erase |
| **Word Splitting** | By `$IFS` (default: space/tab/newline) | Only on newlines | Fish never does word splitting on variables |
| **Globbing** | `*, ?, **, [...]` | `*, **` | Fish: `?` deprecated, `**` follows symlinks |
| **Quotes** | `"..."`, `'...'`, `$'...'` | `"..."`, `'...'` | No `$'...'` in fish |
| **String Manipulation** | `${var#pattern}`, `${var%pattern}`, `${var/find/replace}` | `string` builtin | `string replace`, `string split`, etc. |
| **Arithmetic** | `$((expr))` | `math expr` | Fish supports floats |
| **Test** | `[[ ... ]]`, `[ ... ]`, `test` | `test`, `[ ... ]` | No `[[` in fish, `=` not `==` |
| **Variable Check** | `[[ -v var ]]` | `set -q var` | `-q` = query |
| **Heredoc** | `<< EOF` | Use pipes or `printf`/`echo` | Fish has no heredocs |
| **Process Substitution** | `<(cmd)`, `>(cmd)` | `(cmd \| psub)` | Only input, no output |
| **Subshells** | `(commands)` | `fish -c 'commands'` | Fish rarely needs subshells |
| **Grouping** | `{ commands; }` | `begin; commands; end` | No subshell created |
| **Prompt** | `$PS1`, `$PS2`, etc. | `fish_prompt` function | Prompt is function output |
| **Debug Trace** | `set -x` | `set fish_trace 1` | Variable, not shell option |

---

## 1. Command Substitutions

### Syntax Differences

**Bash:**
```bash
# Three forms
output=`command`
output=$(command)
output="$(command)"
```

**Fish:**
```fish
# Two forms (backticks NOT supported)
set output $(command)
set output (command)
```

### Splitting Behavior

**Bash** (splits on `$IFS`, default: space/tab/newline):
```bash
IFS=","
output=$(echo "a,b,c")
for item in $output; do
    echo "$item"
done
# Prints: a, b, c (three iterations)
```

**Fish** (splits ONLY on newlines):
```fish
set output (echo "a,b,c")
for item in $output
    echo $item
end
# Prints: a,b,c (one iteration)

# To split on commas, use string split:
for item in (echo "a,b,c" | string split ",")
    echo $item
end
# Prints: a, b, c (three iterations)
```

### Null-Separated Data

**Best Practice** (handles filenames with spaces/newlines):
```fish
# Correct way to handle find output
for file in (find . -print0 | string split0)
    echo $file
end
```

### Related Repository Files
- Implementation: `06-templates/chezmoi/dot_config/fish/conf.d/*.fish.tmpl`

---

## 2. Variables

### Setting Variables

| Operation | Bash | Fish |
|-----------|------|------|
| **Set local** | `local var=value` | `set -l var value` |
| **Set global** | `var=value` (or `declare -g`) | `set -g var value` |
| **Export** | `export VAR=value` | `set -gx VAR value` |
| **Set universal** | N/A | `set -U VAR value` |
| **Unset** | `unset VAR` | `set -e VAR` |
| **Append** | `var+=" more"` | `set -a var more` |
| **Prepend** | `var="more $var"` | `set -p var more` |

### Scope Flags

Fish `set` flags:
- `-l` / `--local` - Local to current block
- `-g` / `--global` - Global to shell session
- `-U` / `--universal` - Persists across sessions
- `-x` / `--export` - Exported to child processes
- `-u` / `--unexport` - Not exported
- `-e` / `--erase` - Remove variable
- `-a` / `--append` - Append to list
- `-p` / `--prepend` - Prepend to list
- `-q` / `--query` - Test if variable exists (exit status)

### Examples

**Bash:**
```bash
# Export global variable
export PAGER=less

# Local variable in function
function myfunc() {
    local temp="value"
    echo "$temp"
}

# Unset variable
unset PAGER
```

**Fish:**
```fish
# Export global variable (equivalent to bash's export)
set -gx PAGER less

# Local variable in function
function myfunc
    set -l temp "value"
    echo $temp
end

# Unset (erase) variable
set -e PAGER
```

### Environment Overrides

Both shells support temporary environment variables:

**Bash & Fish (identical syntax):**
```bash
PAGER=cat git log
```

### Word Splitting - CRITICAL DIFFERENCE

**Bash** (requires quoting to prevent splitting):
```bash
foo="bar baz"
printf '"%s"\n' $foo
# Output (WRONG):
# "bar"
# "baz"

printf '"%s"\n' "$foo"
# Output (CORRECT):
# "bar baz"
```

**Fish** (no word splitting, quotes not needed):
```fish
set foo "bar baz"
printf '"%s"\n' $foo
# Output (ALWAYS correct):
# "bar baz"
```

### Lists (Arrays)

**Bash:**
```bash
array=(foo bar baz)
echo "${array[0]}"      # foo
echo "${array[@]}"      # foo bar baz
echo "${#array[@]}"     # 3
```

**Fish:**
```fish
set list foo bar baz
echo $list[1]           # foo (1-indexed!)
echo $list              # foo bar baz
count $list             # 3
```

### Variable Expansion

**Fish treats all variables as lists:**
```fish
set var "foo bar" banana
printf '%s\n' $var
# Output:
# foo bar
# banana

# Select specific elements
set numbers 1 2 3 4 5
echo $numbers[2..4]     # 2 3 4
echo $numbers[-1]       # 5 (last element)
```

### Set from Command Output

**Bash:**
```bash
lines=$(cat file)
# May lose trailing newlines, subject to word splitting
```

**Fish:**
```fish
set lines (cat file)
# Each line becomes a list element, preserves structure
```

### Common Mistake

**DON'T DO THIS:**
```fish
set foo=bar        # ERROR: sets $foo to "=bar"
set foo = bar      # Sets $foo to two values: "=" and "bar"
```

**DO THIS:**
```fish
set foo bar        # Correct: sets $foo to "bar"
```

### Related Repository Files
- Path configuration: `06-templates/chezmoi/dot_config/fish/conf.d/04-paths.fish.tmpl`
- All tool configs: `06-templates/chezmoi/dot_config/fish/conf.d/10-*.fish.tmpl`

---

## 3. Wildcards (Globs)

### Supported Patterns

| Pattern | Bash | Fish | Behavior |
|---------|------|------|----------|
| `*` | ✅ | ✅ | Match any characters |
| `?` | ✅ | ⚠️ Deprecated | Match single character |
| `**` | ✅ (with `shopt -s globstar`) | ✅ (default) | Recursive subdirectories |
| `[abc]` | ✅ | ❌ | Character class |
| `{a,b}` | ✅ | ✅ | Brace expansion |

### No-Match Behavior

**Bash** (default):
```bash
echo *.foo
# If no match: prints literal "*.foo"

# With failglob:
shopt -s failglob
echo *.foo
# If no match: error
```

**Fish** (always fails unless in specific contexts):
```fish
echo *.foo
# If no match: ERROR (like bash's failglob)

# Exception: for loops expand to nothing
for file in *.foo
    echo $file
end
# If no match: loop body never runs (like bash's nullglob)

# Exception: set command
set files *.foo
# If no match: $files is empty

# Exception: environment override
VAR=*.foo command
# If no match: expands to nothing
```

### Variable Expansion

**CRITICAL DIFFERENCE:**

**Bash:**
```bash
pattern="*.txt"
echo $pattern
# Expands to matching files!
```

**Fish:**
```fish
set pattern "*.txt"
echo $pattern
# Prints literal: *.txt (NO globbing)
```

### Recursive Globs

**Bash:**
```bash
# Requires option
shopt -s globstar
echo **/*.fish
```

**Fish:**
```fish
# Always enabled
echo **/*.fish
# Follows symlinks and uses natural sort
```

### Sorting Differences

**Bash:** Lexicographic (ASCII order)
```bash
# track1.mp3, track10.mp3, track2.mp3
```

**Fish:** Natural sort (numbers as numbers)
```fish
# track1.mp3, track2.mp3, track10.mp3
```

### Related Repository Files
- Examples in: `scripts/*.sh`, `scripts/*.fish`

---

## 4. Quoting

### Quote Types

| Type | Bash | Fish | Expands Variables | Expands Commands | Escape Sequences |
|------|------|------|-------------------|------------------|------------------|
| **Double** | `"..."` | `"..."` | ✅ | ✅ | ❌ |
| **Single** | `'...'` | `'...'` | ❌ | ❌ | ❌ |
| **ANSI-C** | `$'...'` | ❌ | ❌ | ❌ | ✅ (bash only) |
| **Unquoted** | Varies | Escape sequences work | ✅ | ✅ | ✅ |

### Escape Sequences

**Bash needs `$'...'` for escapes:**
```bash
echo $'line1\nline2'
# Output:
# line1
# line2

echo 'line1\nline2'
# Output: line1\nline2 (literal)
```

**Fish processes escapes when unquoted or in double-quotes:**
```fish
echo "line1\nline2"
# Output:
# line1
# line2

echo 'line1\nline2'
# Output: line1\nline2 (literal)

echo line1\nline2
# Output:
# line1
# line2
```

### Supported Escape Sequences

Fish supports in unquoted/double-quoted strings:
- `\n` - newline
- `\t` - tab
- `\r` - carriage return
- `\e` - escape (ESC)
- `\x7f` - hex byte
- `\u0040` - Unicode character
- `\\` - literal backslash

### Variable Expansion in Quotes

**Both shells expand variables in double quotes:**
```bash
# Bash and Fish (identical)
name="World"
echo "Hello $name"    # Hello World
echo 'Hello $name'    # Hello $name (literal)
```

---

## 5. String Manipulation

### Bash Parameter Expansion vs Fish `string` builtin

| Operation | Bash | Fish |
|-----------|------|------|
| **Remove prefix** | `${var#prefix}` | `string replace -r '^prefix' '' $var` |
| **Remove suffix** | `${var%suffix}` | `string replace -r 'suffix$' '' $var` |
| **Replace first** | `${var/find/replace}` | `string replace find replace $var` |
| **Replace all** | `${var//find/replace}` | `string replace -a find replace $var` |
| **Substring** | `${var:offset:length}` | `string sub -s offset -l length $var` |
| **Length** | `${#var}` | `string length $var` |
| **Uppercase** | `${var^^}` | `string upper $var` |
| **Lowercase** | `${var,,}` | `string lower $var` |
| **Split** | `IFS=, read -ra arr <<< "$var"` | `string split , $var` |
| **Join** | `IFS=,; echo "${arr[*]}"` | `string join , $var` |
| **Trim** | `echo "$var" \| xargs` | `string trim $var` |
| **Match regex** | `[[ $var =~ pattern ]]` | `string match -r pattern $var` |

### Common String Operations

#### Replace
```fish
string replace bar baz "bar luhrmann"
# Output: baz luhrmann
```

#### Split
```fish
string split "," "foo,bar,baz"
# Output (3 lines):
# foo
# bar
# baz

# Store in variable
set parts (string split "," "foo,bar,baz")
```

#### Match (grep replacement)
```fish
echo "abababa" | string match -r 'aba'
# Output: aba

echo "test@example.com" | string match -r '(.+)@(.+)'
# Captures available in $matches
```

#### Pad
```fish
string pad -c x -w 20 "foo"
# Output: xxxxxxxxxxxxxxxxxfoo
```

#### Case Conversion
```fish
string lower "FOO"    # foo
string upper "bar"    # BAR
```

#### Repeat
```fish
string repeat -n 3 "abc"
# Output: abcabcabc
```

#### Trim Whitespace
```fish
string trim "  foo  "
# Output: foo
```

#### Length
```fish
string length "hello"
# Output: 5

# Width in terminal cells (important for multi-byte characters)
string length --width "hello世界"
```

#### Escape
```fish
string escape "foo bar"
# Output: foo\ bar
```

### Related Repository Files
- String operations used in: All `*.fish.tmpl` files for path/variable manipulation

---

## 6. Special Variables

### Variable Mapping

| Bash | Fish | Description |
|------|------|-------------|
| `$0` | `status filename` | Script name |
| `$1`, `$2`, ... | `$argv[1]`, `$argv[2]`, ... | Positional arguments (1-indexed) |
| `$*`, `$@` | `$argv` | All arguments as list |
| `$#` | `count $argv` | Number of arguments |
| `$?` | `$status` | Exit status of last command |
| `$$` | `$fish_pid` | Current process ID |
| `$!` | `$last_pid` | PID of last background job |
| `$-` | `status is-interactive`, `status is-login` | Shell flags |
| `$BASHPID` | `$fish_pid` | Current shell PID (subshell-aware in bash) |
| `$BASH_VERSION` | `$FISH_VERSION` | Shell version |
| `$RANDOM` | `random` | Random number (function in fish) |
| `$LINENO` | `status line-number` | Current line number |
| `$PWD` | `$PWD` | Current directory (same) |
| `$OLDPWD` | `$OLDPWD` | Previous directory (same) |
| `$HOME` | `$HOME` | Home directory (same) |
| `$USER` | `$USER` | Current user (same) |
| `$HOSTNAME` | `$hostname` | Hostname |
| `$PATH` | `$PATH` or `$fish_user_paths` | Executable search path |

### Fish-Specific Variables

- `$fish_pid` - Current fish process ID
- `$fish_user_paths` - User-defined paths (persistent)
- `$fish_trace` - Enable command tracing (like `set -x`)
- `$fish_greeting` - Message shown on shell start
- `$fish_color_*` - Color customization variables
- `$FISH_VERSION` - Fish version string
- `$pipestatus` - Exit status of all commands in pipe

### Argument Handling

**Bash:**
```bash
#!/bin/bash
echo "Script: $0"
echo "First arg: $1"
echo "All args: $@"
echo "Arg count: $#"
```

**Fish:**
```fish
#!/usr/bin/env fish
echo "Script: "(status filename)
echo "First arg: $argv[1]"
echo "All args: $argv"
echo "Arg count: "(count $argv)
```

### Exit Status

**Bash:**
```bash
false
echo $?    # 1

true
echo $?    # 0
```

**Fish:**
```fish
false
echo $status    # 1

true
echo $status    # 0
```

### Process IDs

**Bash:**
```bash
echo $$        # Current shell PID
sleep 10 &
echo $!        # Background job PID
```

**Fish:**
```fish
echo $fish_pid    # Current shell PID
sleep 10 &
echo $last_pid    # Background job PID
```

### Shell Status Checks

**Bash:**
```bash
if [[ $- == *i* ]]; then
    echo "Interactive shell"
fi

if shopt -q login_shell; then
    echo "Login shell"
fi
```

**Fish:**
```fish
if status is-interactive
    echo "Interactive shell"
end

if status is-login
    echo "Login shell"
end
```

### Related Repository Files
- `06-templates/chezmoi/dot_config/fish/conf.d/05-keybindings.fish.tmpl` - Uses `$argv`
- All function definitions use `$argv` and `$status`

---

## 7. Process Substitution

### Input Process Substitution

**Bash:**
```bash
# Read command output as file
diff <(ls dir1) <(ls dir2)

# Source from command
source <(command)
```

**Fish:**
```fish
# Use psub for file-like access
diff (ls dir1 | psub) (ls dir2 | psub)

# Better: pipe directly to source
command | source
```

### Output Process Substitution

**Bash:**
```bash
# Write to command stdin (bash only)
echo "data" > >(command)
```

**Fish:**
```fish
# No equivalent - use pipes instead
echo "data" | command
```

### Best Practices

Most process substitution cases are better handled with pipes:

**Instead of:**
```fish
source (command | psub)
```

**Do:**
```fish
command | source
```

Fish's `source` (and many other commands) can read from stdin, making process substitution rarely necessary.

---

## 8. Heredocs

### Bash Heredoc

**Bash:**
```bash
cat <<EOF
some string
some more string
EOF

# With variable expansion disabled
cat <<'EOF'
$HOME is not expanded
EOF

# With leading tab stripping
cat <<-EOF
	indented line
EOF
```

### Fish Alternative

**Fish has NO heredocs. Use alternatives:**

#### Multi-line String with echo
```fish
echo "some string
some more string"

# With quotes on separate lines
echo "\
some string
some more string\
"
```

#### Printf (more precise)
```fish
printf %s\n "some string" "some more string"
```

#### Pipe from Echo
```fish
echo "foo
bar
baz" | command
```

#### Read from Variable
```fish
set content "line1
line2
line3"
echo $content | command
```

### Heredoc Equivalence

What heredocs actually do:
1. Read/interpret string up to terminator (with substitution rules)
2. Write to temporary file
3. Pass file as stdin to command

This is essentially the same as piping:

**Bash heredoc:**
```bash
cat <<EOF
foo
bar
EOF
```

**Equivalent pipe:**
```bash
echo "foo
bar" | cat
```

### Commands Reading from Stdin

Some commands need explicit `-` to read from stdin:

```fish
# pacman example
echo "xterm
rxvt-unicode" | pacman --remove -

# Same as bash heredoc:
# pacman --remove - <<EOF
# xterm
# rxvt-unicode
# EOF
```

---

## 9. Test and Conditionals

### Test Syntax

| Bash | Fish | Notes |
|------|------|-------|
| `test` | `test` | POSIX-compatible, same |
| `[ ... ]` | `[ ... ]` | Alias for `test`, same |
| `[[ ... ]]` | ❌ Not available | Use `test` or `[` |
| `==` | `=` | Fish uses `=` only (POSIX) |

### String Comparison

**Bash:**
```bash
[[ "$foo" == "bar" ]]    # bash extension
[ "$foo" = "bar" ]       # POSIX
```

**Fish:**
```fish
test "$foo" = "bar"      # Must use =, not ==
[ "$foo" = "bar" ]       # Same ([ is alias for test)
```

### Numeric Comparison

**Both shells:**
```fish
test $num -eq 10
test $num -gt 5
test $num -lt 20
test $num -ge 5
test $num -le 20
test $num -ne 10
```

**Fish can also compare floats:**
```fish
test 5.5 -gt 3.2    # Works in fish!
```

### File Tests

**Identical in both shells:**
```fish
test -f file.txt     # Is regular file
test -d /path        # Is directory
test -e file         # Exists
test -r file         # Readable
test -w file         # Writable
test -x file         # Executable
test -s file         # Non-empty
test -L link         # Is symlink
```

### Variable Existence

**Bash:**
```bash
[[ -v varname ]]           # Variable exists
[[ -n "$varname" ]]        # Variable non-empty
[[ -z "$varname" ]]        # Variable empty
```

**Fish:**
```fish
set -q varname             # Variable exists (any value)
set -q varname[1]          # Variable has at least 1 element
set -q varname[2]          # Variable has at least 2 elements
test -n "$varname"         # Variable non-empty (same)
test -z "$varname"         # Variable empty (same)
```

### Logical Operations

**Bash:**
```bash
[[ condition1 && condition2 ]]
[[ condition1 || condition2 ]]
[[ ! condition ]]
```

**Fish:**
```fish
test condition1 -a condition2    # AND
test condition1 -o condition2    # OR
test ! condition                 # NOT

# Or separate test calls
test condition1; and test condition2
test condition1; or test condition2
not test condition
```

### Combining Conditions

**Bash:**
```bash
if [[ -f file && -r file ]]; then
    echo "Regular readable file"
fi
```

**Fish:**
```fish
if test -f file -a -r file
    echo "Regular readable file"
end

# Or more readable:
if test -f file; and test -r file
    echo "Regular readable file"
end
```

### Related Repository Files
- Conditional logic in all `run_once_*.sh.tmpl` installer scripts
- `scripts/repair-shell-env.sh` - Uses various test conditions

---

## 10. Arithmetic Expansion

### Syntax

**Bash:**
```bash
result=$((5 + 3))
echo $((i++))
((i += 1))
```

**Fish:**
```fish
set result (math 5 + 3)
set i (math $i + 1)
```

### Integer vs Float

**Bash** (integers only in `$(())`):
```bash
echo $((5 / 2))    # 2 (integer division)
echo "scale=2; 5 / 2" | bc    # 2.50 (needs bc for floats)
```

**Fish** (floats by default):
```fish
math 5 / 2         # 2.5
math -s0 5 / 2     # 2 (scale 0 = integers)
```

### Functions

**Fish `math` includes trigonometry and more:**
```fish
math "cos(2 * pi)"        # -1
math "sin(pi / 2)"        # 1
math "sqrt(16)"           # 4
math "abs(-5)"            # 5
math "round(3.7)"         # 4
math "floor(3.7)"         # 3
math "ceil(3.2)"          # 4
math "log(10)"            # Natural log
math "log2(8)"            # 3
math "pow(2, 8)"          # 256
math "max(5, 10, 3)"      # 10
math "min(5, 10, 3)"      # 3
```

### Quoting

**Fish uses `()` for command substitution, so quote complex expressions:**

```fish
# WRONG (parentheses interpreted as command substitution)
math (5 + 2) * 4          # ERROR

# CORRECT (quoted)
math "(5 + 2) * 4"        # 28
```

### Multiplication

**Both `*` and `x` work, but `*` needs quoting (glob character):**

```fish
math 5 x 3            # 15
math "5 * 3"          # 15
math 5 * 3            # ERROR (glob expansion)
```

### Multiple Arguments vs String

**Both work:**
```fish
math 5 + 3            # 8
math "5 + 3"          # 8
math $i + 1           # Variable
math "$i + 1"         # Variable in string
```

### Scale (Precision)

```fish
math 5 / 2            # 2.5
math -s0 5 / 2        # 2
math -s3 1 / 3        # 0.333
math -s6 1 / 3        # 0.333333
```

### Related Repository Files
- Used in various setup scripts for version comparisons

---

## 11. Prompts

### Prompt Variables

**Bash:**
```bash
PS1='prompt string'      # Primary prompt
PS2='> '                 # Continuation prompt
PS3='select> '           # Select prompt
PS4='+ '                 # Trace prompt
```

**Fish:**
```fish
# Prompts are FUNCTIONS, not variables
function fish_prompt
    # Return prompt string
end

function fish_right_prompt
    # Right-side prompt
end

function fish_mode_prompt
    # Vi mode indicator
end
```

### Prompt Example

**Bash:**
```bash
# <hostname> <path in blue> <$ in yellow>
PS1='\h\[\e[1;34m\]\w\[\e[m\] \[\e[1;32m\]\$\[\e[m\] '
```

**Fish:**
```fish
function fish_prompt
    set -l prompt_symbol '$'
    fish_is_root_user; and set prompt_symbol '#'

    echo -s (prompt_hostname) \
        (set_color blue) (prompt_pwd) \
        (set_color yellow) $prompt_symbol (set_color normal) ' '
end
```

### Color Functions

**Fish provides helper functions:**
- `set_color` - Set text color
  - Named colors: `red`, `blue`, `green`, `yellow`, `cyan`, `magenta`, `white`, `black`
  - Attributes: `bold`, `underline`, `dim`
  - RGB: `set_color 5555FF`
  - Reset: `set_color normal`

### Prompt Helper Functions

**Fish provides:**
- `prompt_hostname` - Shortened hostname
- `prompt_pwd` - Shortened working directory (~ for home)
- `fish_is_root_user` - Returns true if root
- `fish_vcs_prompt` - Git/Mercurial/SVN status (requires fish_vcs_prompt)
- `fish_git_prompt` - Git-specific status

### Example Full-Featured Prompt

```fish
function fish_prompt
    set -l last_status $status
    set -l prompt_symbol '$'
    fish_is_root_user; and set prompt_symbol '#'

    # Show username@hostname for SSH
    if set -q SSH_CONNECTION
        echo -n (set_color brblue)(whoami)(set_color normal)'@'(set_color blue)(prompt_hostname)(set_color normal)' '
    end

    # Current directory
    echo -n (set_color $fish_color_cwd)(prompt_pwd)(set_color normal)

    # Git status
    echo -n (fish_vcs_prompt)

    # Prompt symbol (red if last command failed)
    if test $last_status -ne 0
        echo -n (set_color red)$prompt_symbol(set_color normal)
    else
        echo -n (set_color green)$prompt_symbol(set_color normal)
    end

    echo -n ' '
end
```

### Viewing Default Prompt

```fish
type fish_prompt
# Shows the default prompt function code
```

### Continuation Lines

**Bash:** Uses `$PS2`

**Fish:** Automatically indents continuation lines (no variable)

```fish
echo "This is \
    a continued line"
# Fish indents the second line visually
```

### Related Repository Files
- Starship prompt config: `06-templates/chezmoi/dot_config/starship.toml.tmpl`
- Prompt init: `06-templates/chezmoi/dot_config/fish/conf.d/03-starship.fish.tmpl`

---

## 12. Blocks and Loops

### Syntax Comparison

| Bash | Fish |
|------|------|
| `for x in ...; do ... done` | `for x in ... ... end` |
| `while ...; do ... done` | `while ... ... end` |
| `until ...; do ... done` | `while not ... ... end` |
| `if ...; then ... fi` | `if ... ... end` |
| `case ... esac` | `switch ... end` |
| `{ ... }` | `begin ... end` |
| `function name() { ... }` | `function name ... end` |

### For Loops

**Bash:**
```bash
for i in 1 2 3; do
    echo $i
done

# C-style
for ((i=0; i<10; i++)); do
    echo $i
done
```

**Fish:**
```fish
for i in 1 2 3
    echo $i
end

# No C-style, use seq
for i in (seq 0 9)
    echo $i
end
```

### While Loops

**Bash:**
```bash
while true; do
    echo "Running"
done

until false; do
    echo "Running"
done
```

**Fish:**
```fish
while true
    echo "Running"
end

# No until, use "while not"
while not false
    echo "Running"
end
```

### If Statements

**Bash:**
```bash
if [[ condition ]]; then
    echo "Yes"
elif [[ other ]]; then
    echo "Maybe"
else
    echo "No"
fi
```

**Fish:**
```fish
if condition
    echo "Yes"
else if other
    echo "Maybe"
else
    echo "No"
end
```

### Switch/Case

**Bash:**
```bash
case "$var" in
    pattern1)
        echo "Match 1"
        ;;
    pattern2|pattern3)
        echo "Match 2 or 3"
        ;;
    *)
        echo "Default"
        ;;
esac
```

**Fish:**
```fish
switch $var
    case pattern1
        echo "Match 1"
    case pattern2 pattern3
        echo "Match 2 or 3"
    case '*'
        echo "Default"
end
```

### Begin Blocks

**Bash:**
```bash
{
    echo "Grouped"
    echo "Commands"
}
```

**Fish:**
```fish
begin
    echo "Grouped"
    echo "Commands"
end
```

### Functions

**Bash:**
```bash
# Multiple syntaxes
function myfunc {
    echo "Args: $@"
}

myfunc() {
    echo "Args: $@"
}
```

**Fish:**
```fish
function myfunc
    echo "Args: $argv"
end

# With description
function myfunc --description "My function"
    echo "Args: $argv"
end
```

### Breaking and Continuing

**Both shells use same keywords:**
```fish
while true
    if condition
        break      # Exit loop
    end
    if other
        continue   # Skip to next iteration
    end
end
```

### Related Repository Files
- Loop examples in: `scripts/*.fish`, `06-templates/chezmoi/run_once_*.sh.tmpl`

---

## 13. Subshells and Grouping

### Subshells

**Bash:**
```bash
# Create subshell (separate process)
(
    cd /tmp
    VAR=value
    export OTHER=thing
)
# Changes don't affect parent
```

**Fish:**
```fish
# NO automatic subshells
# To explicitly run in new shell:
fish -c 'cd /tmp; set VAR value'
# Changes don't affect parent
```

### Variable Scoping Instead

**Fish uses scoping instead of subshells:**
```fish
begin
    set -l VAR value    # Local to block
    cd /tmp             # Still affects parent!
end
# $VAR is gone, but pwd changed
```

### Grouping Commands

**Bash:**
```bash
# Subshell (isolated)
(foo; bar) | baz

# Grouping (NOT isolated)
{ foo; bar; } | baz
```

**Fish:**
```fish
# Grouping (no isolation)
begin; foo; bar; end | baz
```

### Pipes and Scoping

**CRITICAL DIFFERENCE:**

**Bash** (creates subshell for right side of pipe):
```bash
foo | while read -r bar; do
    VAR=val    # Lost after loop!
    baz &      # Background job lost!
done
echo $VAR      # Empty
```

**Fish** (no subshell, same process):
```fish
foo | while read bar
    set -g VAR val    # Persists!
    baz &             # Job visible!
end
echo $VAR      # Prints "val"
jobs           # Shows baz
```

### Command Substitutions vs Subshells

**Often confused - they're different:**

**Bash:**
```bash
# Command substitution (captures output)
result=$(command)

# Subshell (separate process, output not captured)
(command)
```

Both bash and fish use subshells/processes to implement command substitutions, but fish doesn't expose explicit subshell syntax for other purposes.

---

## 14. Builtins and Commands

### Fish-Specific Builtins

| Builtin | Purpose | Bash Equivalent |
|---------|---------|-----------------|
| `string` | String manipulation | `${var#...}`, `sed`, `awk`, `grep` |
| `math` | Arithmetic | `$((...))`, `bc` |
| `argparse` | Option parsing | `getopt`, `getopts` |
| `count` | Count arguments/lines | `$#`, `wc -l` |
| `status` | Shell status | `$?`, `$-`, `$LINENO` |
| `contains` | List membership | `[[ " ${arr[@]} " =~ " $item " ]]` |
| `path` | Path manipulation | `dirname`, `basename`, `realpath` |
| `fish_add_path` | Add to PATH | `PATH=$PATH:...` |

### string - String Operations

**Replace bash parameter expansion:**
```fish
# Instead of ${var#prefix}
string replace -r '^prefix' '' $var

# Instead of ${var%suffix}
string replace -r 'suffix$' '' $var

# Instead of ${var//find/replace}
string replace -a find replace $var
```

**Replace sed/awk:**
```fish
# Instead of sed 's/foo/bar/g'
string replace -a foo bar

# Instead of awk -F, '{print $2}'
string split ',' | string trim
```

**Replace grep:**
```fish
# Instead of grep pattern file
string match -r pattern < file

# Instead of grep -v (invert)
string match -v pattern
```

### math - Arithmetic

```fish
# Instead of $((i + 1))
math $i + 1

# Float support
math 5 / 2              # 2.5

# Functions
math "sin(3.14159)"
```

### argparse - Option Parsing

```fish
function my_function
    argparse 'h/help' 'v/verbose' 'f/file=' -- $argv
    or return

    if set -q _flag_help
        echo "Usage: ..."
        return
    end

    if set -q _flag_verbose
        echo "Verbose mode"
    end

    if set -q _flag_file
        echo "File: $_flag_file"
    end
end
```

### count - Counting

```fish
# Instead of $#
count $argv

# Count lines
count (cat file)

# Count files
count *.txt
```

### status - Shell Status

```fish
# Instead of $?
echo $status
# or
status

# Instead of $LINENO
status line-number

# Instead of $0
status filename

# Check if interactive
status is-interactive

# Check if login shell
status is-login

# Check if command exists
status is-command-substitution
```

### contains - List Membership

```fish
set -l list foo bar baz

if contains foo $list
    echo "Found foo"
end

# Bash equivalent:
# if [[ " ${list[@]} " =~ " foo " ]]; then
```

### path - Path Manipulation

```fish
# Basename
path basename /foo/bar/file.txt    # file.txt

# Dirname
path dirname /foo/bar/file.txt     # /foo/bar

# Extension
path extension file.txt            # .txt

# Change extension
path change-extension .md file.txt # file.md

# Normalize
path normalize /foo//bar/../baz    # /foo/baz

# Resolve
path resolve ../file               # /absolute/path/file

# Filter paths
path filter -f *.txt               # Only regular files
```

### fish_add_path - PATH Management

```fish
# Add to PATH (persistent, no duplicates)
fish_add_path /opt/bin

# Prepend
fish_add_path --prepend ~/.local/bin

# Append
fish_add_path --append ~/bin

# Global
fish_add_path --global /usr/local/bin
```

### seq - Range Generation

```fish
# Bash: {1..10}
# Fish:
seq 10              # 1 to 10
seq 5 15            # 5 to 15
seq 0 2 10          # 0, 2, 4, 6, 8, 10
```

If your OS lacks `seq`, fish provides a fallback function.

### Related Repository Files
- `string` usage: Throughout all `.fish.tmpl` files
- `path` usage: `06-templates/chezmoi/dot_config/fish/conf.d/04-paths.fish.tmpl`
- `fish_add_path`: Path configuration files

---

## 15. Other Facilities

### Command Tracing

**Bash:**
```bash
set -x              # Enable trace
set -o xtrace       # Same
# Shows commands with PS4 prompt (default: + )
```

**Fish:**
```fish
set fish_trace 1    # Enable trace
# Shows commands being executed
```

**Example:**
```fish
# Enable tracing
set fish_trace 1

echo "test"
# Output:
# set fish_trace 1
# echo test
# test

# Disable
set fish_trace 0
```

### Error Handling

**Bash:**
```bash
set -e              # Exit on error
set -o errexit      # Same

set -u              # Error on undefined variable
set -o nounset      # Same

set -o pipefail     # Pipe fails if any command fails
```

**Fish:**
```fish
# No set -e equivalent
# Use explicit error checking:
if not command
    echo "Command failed"
    return 1
end

# Undefined variables are always errors (no set -u needed)

# Pipefail is default behavior
```

### Directory Stack

**Bash:**
```bash
pushd /path
popd
dirs
```

**Fish:**
```fish
pushd /path
popd
dirs

# Also:
prevd    # Go back in directory history
nextd    # Go forward
dirh     # Show directory history
cdh      # Select from history interactively
```

### Aliases vs Functions

**Bash:**
```bash
alias ll='ls -lh'
```

**Fish:**
```fish
# Aliases are discouraged, use functions:
function ll
    ls -lh $argv
end

# Or abbreviations (expand on space):
abbr -a ll 'ls -lh'
```

### Abbreviations (Fish-Specific)

**Interactive expansion:**
```fish
abbr -a gs 'git status'
# Type: gs<space>
# Expands to: git status

abbr -a gco 'git checkout'
abbr -a gp 'git push'
```

### Event Handlers

**Fish can run functions on events:**
```fish
function on_pwd_change --on-variable PWD
    echo "Changed directory to $PWD"
end

function on_fish_start --on-event fish_start
    echo "Fish started"
end
```

### Job Control

**Both shells support job control similarly:**
```fish
command &           # Background
jobs                # List jobs
fg                  # Foreground last job
fg %1               # Foreground job 1
bg                  # Continue job in background
disown              # Remove from job table
```

---

## 16. Migration Checklist

When converting bash scripts to fish:

- [ ] Replace `VAR=value` with `set VAR value`
- [ ] Replace `export VAR=value` with `set -gx VAR value`
- [ ] Replace `local VAR=value` with `set -l VAR value`
- [ ] Replace `unset VAR` with `set -e VAR`
- [ ] Replace `` `cmd` `` with `(cmd)` or `$(cmd)`
- [ ] Replace `$*` and `$@` with `$argv`
- [ ] Replace `$#` with `count $argv`
- [ ] Replace `$?` with `$status`
- [ ] Replace `$$` with `$fish_pid`
- [ ] Replace `$!` with `$last_pid`
- [ ] Replace `${var#pattern}` with `string replace`
- [ ] Replace `${var%pattern}` with `string replace`
- [ ] Replace `${var/find/replace}` with `string replace`
- [ ] Replace `$((expr))` with `math expr`
- [ ] Replace `[[ ... ]]` with `test ...` or `[ ... ]`
- [ ] Change `==` to `=` in test
- [ ] Replace `if ...; then ... fi` with `if ... ... end`
- [ ] Replace `for ...; do ... done` with `for ... ... end`
- [ ] Replace `while ...; do ... done` with `while ... ... end`
- [ ] Replace `until ...` with `while not ...`
- [ ] Replace `case ... esac` with `switch ... end`
- [ ] Replace `{ ...; }` with `begin ... end`
- [ ] Replace `function name() { ... }` with `function name ... end`
- [ ] Replace heredocs with `echo` or `printf` piped to command
- [ ] Replace process substitution `<(cmd)` with `(cmd | psub)` or pipes
- [ ] Remove `source <(cmd)`, use `cmd | source`
- [ ] Add `-l` to `set` for local variables in functions
- [ ] Check `set -q` for variable existence instead of `[[ -v var ]]`
- [ ] Replace `$PS1` with `fish_prompt` function
- [ ] Replace `set -x` debugging with `set fish_trace 1`
- [ ] Replace subshells `(...)` with explicit `fish -c '...'` if isolation needed
- [ ] Ensure scripts start with `#!/usr/bin/env fish`

---

## 17. Common Gotchas

### 1. No Word Splitting

**Bash:**
```bash
var="a b c"
echo $var         # Three words: a b c (split on spaces)
```

**Fish:**
```fish
set var "a b c"
echo $var         # One word: "a b c" (no splitting)

# To split, use string split:
echo (string split ' ' $var)
```

### 2. Globs in Variables Don't Expand

**Bash:**
```bash
pattern="*.txt"
echo $pattern     # Expands to matching files
```

**Fish:**
```fish
set pattern "*.txt"
echo $pattern     # Prints: *.txt (no expansion)
```

### 3. No `==` in test

**Bash accepts both:**
```bash
[[ $var == "value" ]]    # OK
[ $var = "value" ]       # OK
```

**Fish only accepts `=`:**
```fish
test $var = "value"      # OK
test $var == "value"     # ERROR
```

### 4. 1-Indexed Arrays

**Bash (0-indexed):**
```bash
arr=(a b c)
echo ${arr[0]}     # a
```

**Fish (1-indexed):**
```fish
set arr a b c
echo $arr[1]       # a
echo $arr[0]       # ERROR (out of bounds)
```

### 5. No `[[  ]]`

**Bash:**
```bash
[[ -f file && -r file ]]    # OK
```

**Fish:**
```fish
test -f file -a -r file     # OK
# or
test -f file; and test -r file
```

### 6. No `$((  ))`

**Bash:**
```bash
i=$((i + 1))
```

**Fish:**
```fish
set i (math $i + 1)
```

### 7. No Heredocs

**Must use alternatives like echo or printf with pipes.**

### 8. Function Arguments are `$argv`

**Bash:**
```bash
function foo() {
    echo $1 $2
}
```

**Fish:**
```fish
function foo
    echo $argv[1] $argv[2]
end
```

### 9. Quoting in `math`

**Parentheses have special meaning:**
```fish
math (5 + 2)       # ERROR (command substitution)
math "(5 + 2)"     # OK
math 5 + 2         # OK (no parens needed)
```

### 10. `set VAR=value` is Wrong

**Fish interprets `=` as a value:**
```fish
set foo=bar        # Sets $foo to "=bar" (WRONG)
set foo bar        # Sets $foo to "bar" (CORRECT)
```

---

## 18. Performance Considerations

### Fish is Typically Faster for Interactive Use

- Syntax highlighting is built-in and fast
- Autosuggestions from history
- Tab completions are comprehensive and lazy-loaded

### Startup Time

- Fish can be slower to start than bash
- Most noticeable in scripts that are run frequently
- For long-running interactive sessions, this is negligible

### When to Use Bash vs Fish

**Use Bash when:**
- POSIX compliance required
- Scripting for portability (servers, CI/CD)
- Working in restricted environments
- Embedding in other tools

**Use Fish when:**
- Interactive shell (development machines)
- Personal scripting
- Modern features needed (better string handling, floats)
- Prefer cleaner syntax

**Use Both:**
- Fish for interactive shell
- Bash for portable scripts (starting with `#!/bin/bash`)

---

## 19. Related Repository Files

### Fish Configuration Templates
```
06-templates/chezmoi/dot_config/fish/conf.d/
├── 00-homebrew.fish.tmpl       # Homebrew environment
├── 01-mise.fish.tmpl           # mise activation
├── 02-direnv.fish.tmpl         # direnv integration
├── 03-starship.fish.tmpl       # Prompt
├── 04-paths.fish.tmpl          # PATH management
├── 05-keybindings.fish.tmpl    # Key bindings
├── 10-claude.fish.tmpl         # Claude CLI
├── 12-codex.fish.tmpl          # Codex CLI
└── [13-19]-*.fish.tmpl         # Other tools
```

### Documentation
```
docs/
├── direnv-setup.md             # direnv guide
└── fish-vs-bash-reference.md   # This file

01-setup/
└── 03-iterm2.md                # Terminal setup

02-configuration/terminals/
├── iterm2-config.md
└── ITERM2-SETUP-STATUS.md
```

### Scripts
```
scripts/
├── deploy-shell-config.sh      # Deploy configurations
├── repair-shell-env.sh         # Fix shell environment
└── iterm2-setup.sh             # iTerm2 setup
```

### Reports
```
07-reports/status/
└── shell-env-audit-2025-09-30.md
```

---

## 20. Additional Resources

### Official Documentation
- Fish Shell: https://fishshell.com/docs/current/
- Fish Tutorial: https://fishshell.com/docs/current/tutorial.html
- Fish for Bash Users: https://fishshell.com/docs/current/fish_for_bash_users.html

### Repository Documentation
- Setup Guide: `01-setup/03-iterm2.md`
- direnv Setup: `docs/direnv-setup.md`
- Shell Environment Audit: `07-reports/status/shell-env-audit-2025-09-30.md`

### Community Resources
- r/fishshell - Reddit community
- GitHub Discussions: https://github.com/fish-shell/fish-shell/discussions
- Awesome Fish: https://github.com/jorgebucaran/awsm.fish

---

## Document Metadata

**Created**: 2025-11-21
**Source**: Official Fish Shell documentation (fish_for_bash_users.html)
**Authority**: Definitive reference
**Maintenance**: Update when Fish version changes or new features added
**Related Standards**: See `04-policies/version-policy.md` for tool versioning
