# LLDB Copilot


Copilot-powered debugging assistant for LLDB. Ask questions about your debug session and get intelligent analysis.

## Requirements

- LLDB development headers/libraries (auto-fetched on Windows by default)
- CMake 3.20+
- C++20 compiler
- Claude Code or GitHub Copilot configured

### Platform-specific requirements

**Linux:**
```bash
sudo apt install liblldb-dev lldb
```

**macOS:**
```bash
xcode-select --install
```

**Windows:**
No manual LLVM install is required by default. CMake auto-fetches a pinned LLVM/LLDB SDK on first configure (`LLDB_PINNED_VERSION`, currently `18.1.8`).

Optional manual setup still works via `winget install LLVM.LLVM` and `LLVM_DIR` if you want to bypass auto-fetch.

## Build

**Linux/macOS:**
```bash
cmake --preset default
cmake --build --preset default
```

**Windows:**
```cmd
cmake --preset windows
cmake --build --preset windows
```

Output:
- Linux: `build/lldb_copilot.so`
- macOS: `build/lldb_copilot.dylib`
- Windows: `build-windows/Release/lldb_copilot.dll`

## Usage

```bash
# Start LLDB with your program
lldb ./myprogram

# Load the plugin
(lldb) plugin load /path/to/lldb_copilot.so

# Ask questions
(lldb) copilot what is the call stack?
(lldb) copilot explain this crash

# Run commands directly - AI executes and explains
(lldb) copilot bt all
(lldb) copilot register read

# Decompilation
(lldb) copilot decompile main

# Provider and settings
(lldb) agent help
(lldb) agent provider claude
(lldb) agent clear
```

## Features

- **Direct command execution**: Pass commands directly (`copilot bt`) - AI runs and explains
- **Expression evaluation**: Uses `p`, `expression` for calculations instead of guessing
- **Decompilation**: Ask to decompile functions - AI uses disassemble, frame variable, type info
- **Automatic tool execution**: AI runs debugger commands to gather information
- **Conversation continuity**: Follow-up questions remember context
- **Multiple providers**: Switch between Claude and Copilot

**Common commands:**
```
(lldb) agent help
(lldb) agent version
(lldb) run
(lldb) copilot what function am I in?
(lldb) copilot show me the local variables

# Test with a crash
(lldb) run crash
(lldb) copilot explain this crash
```

## Commands

| Command | Description |
|---------|-------------|
| `copilot <question>` | Ask Copilot a question |
| `agent help` | Show help |
| `agent version` | Show version and current provider |
| `agent provider` | Show current provider |
| `agent provider <name>` | Switch provider (claude, copilot) |
| `agent clear` | Clear conversation history |
| `agent prompt` | Show custom prompt |
| `agent prompt <text>` | Set custom prompt |
| `agent prompt clear` | Clear custom prompt |

## Providers

- **Claude** - Uses Claude Code CLI
- **Copilot** - Uses GitHub Copilot

Switch providers with:
```
(lldb) agent provider claude
(lldb) agent provider copilot
```

## Configuration

Settings are stored in `~/.lldb_copilot/settings.json`:

```json
{
  "default_provider": "copilot",
  "custom_prompt": ""
}
```

## Windows Setup

### Default (recommended): CMake auto-fetch

On Windows, if LLDB is not found locally, configure downloads a pinned LLVM/LLDB SDK automatically.

You can control this behavior with:

- `LLDB_AUTO_FETCH=ON|OFF` (default: `ON`)
- `LLDB_PINNED_VERSION` (default: `18.1.8`)
- `LLDB_WINDOWS_SDK_URL` (override download source)
- `LLDB_WINDOWS_SDK_SHA256` (optional integrity pin)

Example:

```cmd
cmake --preset windows -DLLDB_AUTO_FETCH=ON
cmake --build --preset windows
```

### Optional manual setup (winget + embedded Python)

The LLVM package from winget may require Python 3.10 to run LLDB. Download and extract to the project `bin` folder:

```powershell
# Download and extract embedded Python 3.10 to project bin folder
Invoke-WebRequest -Uri "https://www.python.org/ftp/python/3.10.11/python-3.10.11-embed-amd64.zip" -OutFile "$env:TEMP\python310.zip"
Expand-Archive -Path "$env:TEMP\python310.zip" -DestinationPath "..\bin\python310" -Force
```

Then use the `test_lldb.cmd` wrapper script which sets up the environment:

```cmd
cd lldb_copilot
test_lldb.cmd
```

### Quick Test

```cmd
test_lldb.cmd
(lldb) target create "C:\Windows\System32\notepad.exe"
(lldb) run
```

Press Ctrl+C to break, then:
```
(lldb) bt
(lldb) copilot what is the call stack?
```

## Author

Elias Bachaalany ([@0xeb](https://github.com/0xeb))

Pair-programmed with Claude Code and Codex.

## License

MIT
