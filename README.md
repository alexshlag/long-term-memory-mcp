# Robust Long‑Term Memory MCP for LM Studio

A persistent, human‑like memory system for AI companions in [LM Studio](https://lmstudio.ai), powered by a hybrid of SQLite (structured storage) and ChromaDB (semantic search). It’s designed for decades‑long use, seamless recall across sessions, and automatic backups — making your AI companion feel like a continuous, living persona. Now with biological behavior: time‑based lazy decay and reinforcement by use.

---

## ✨ Features

- **Hybrid Memory System**
  - **SQLite** for structured metadata and fast queries
  - **ChromaDB** for semantic similarity and natural recall
  - **JSON backups** for portability
- **Cross‑chat continuity**: memories persist beyond a single chat
- **Cross‑model continuity**: swap models freely, the memory stays intact
- **Cross‑machine portability**: move the database to another system and continue seamlessly
- **Automatic backups**: daily backups and after every 100 memories, pruned to keep the last 10
- **Invisible memory integration**: tools are hidden from the user; conversations feel natural
- Human‑like dynamics
  - Lazy Decay: importance decreases only when a memory is accessed after idle time
  - Reinforcement: frequent recall strengthens memory importance
  - Adaptive Semantic Threshold: balances precision/recall with a safe top‑1 fallback

---

## 📦 Installation

1. Clone the repo:

   ```bash
   git clone https://github.com/Rotoslider/long-term-memory-mcp.git

   cd long-term-memory-mcp

   ```

2. Install requirements:

```
    pip install -r requirements.txt
```

Requirements include:

    chromadb
    sentence-transformers
    fastmcp
    (sqlite3 is built into Python; do not install separately)

3. (Optional) For faster HuggingFace model fetching:

```
    pip install "huggingface_hub[hf_xet]"
```

## Как подключить и активировать в NixOS

1. Добавьте этот репозиторий в ваш основной flake.nix операционной системы:

```nix
nixinputs.long-term-memory-mcp.url = "git+https://github.com";
```

2. Передайте его в аргументы (outputs) и подключите модуль в конфигурацию вашей машины внутри configuration.nix:

```nix
nix{ config, pkgs, inputs, ... }: {
  imports = [
    inputs.long-term-memory-mcp.nixosModules.default
  ];

  # Глобальная активация
  services.long-term-memory-mcp = {
    enable = true;
    dataDir = "/var/lib/long-term-memory-mcp"; # Путь к базам данных по умолчанию
  };
}
```

После пересборки системы (nixos-rebuild switch) команда long-term-memory-mcp станет доступна глобально из любой точки терминала, а systemd-демон будет автоматически управлять жизненным циклом и фоновыми процессами памяти вашего ИИ.

## 🚀 Running the Memory MCP

Edit your LM Studio mcp.json to include the correct path:

```
    {
  "mcpServers": {
    "long_term_memory": {
      "command": "C:\\Python313\\python.exe",
      "args": [
        "D:\\a.i. apps\\long_term_memory_mcp\\LongTermMemoryMCP.py"
      ],
      "env": {}
    }
  }
}
```

Then, in LM Studio:

- Open Server (MCP) Settings
- Load the MCP Tool: "long_term_memory"

## 🧠 How Memory Works

- **Cross‑Chats** → Start a new chat — memories are still there.
- **Cross‑Models** → Switch models — the same memory remains available.
- **Cross‑Machines** → Copy the database folder (memory_db/ and memory_backups/) and your system prompt, point to the path, and everything carries over.

### 💡 Think of it as your AI’s diary: chats are conversations, the database is the journal.

## Environment variable for custom data dir:

### Windows PowerShell

```
$env:AI_COMPANION_DATA_DIR="D:\a.i. apps\long_term_memory_mcp\data"
```

### Linux/macOS

```
export AI_COMPANION_DATA_DIR="/home/username/ai_companion_data"
```

## 📂 Backups

Backups are created automatically:

- Every 24 hours
- Or after 100 new memories (configurable)
- Stored in memory_backups/ with timestamped folders
- Only the last 10 backups are kept

Each backup includes:

- SQLite DB copy
- ChromaDB copy
- JSON export of all memories (portable and future‑proof)

## 📝 Recommended System Prompt

“You are an AI companion with long‑term memory. Store facts naturally (‘Got it, I’ll remember that.’). Recall them when asked in natural language. Never expose internal tool usage to the user. Use memory tools to remember, recall, and update information invisibly.”

## 🛠️ MCP Tools Overview

Your `RobustMemory` MCP exposes tools that allow your AI companion to interact with its long-term memory. These tools are designed to be called internally by the AI model based on its system prompt, making the memory system feel seamless and invisible to the user.

Here's a breakdown of each tool's purpose and parameters:

#### 1. `remember`

- **Purpose:** Stores a new memory (fact, conversation snippet, preference, event) into the system. It's indexed both semantically (for natural language search) and structurally (for filtered queries).
- **Parameters:**
  - `title` (string, required): A concise title for the memory.
  - `content` (string, required): The detailed content of the memory.
  - `tags` (string, optional, default: ""): Comma-separated keywords for categorization (e.g., "personal, preference, hobby").
  - `importance` (integer, optional, default: 5): A numerical value (1-10) indicating how important the memory is.
  - `memory_type` (string, optional, default: "conversation"): Categorizes the memory (e.g., "conversation", "fact", "preference", "event").
- **Example Use (internal):** `remember(title="User's Birthday", content="Donny's birthday is July 4th.", tags="personal, fact", importance=8)`

#### 2. `search_memories`

- **Purpose:** The primary tool for recalling memories. It performs a semantic search based on a natural language query, finding memories that are conceptually similar.
- **Parameters:**
  - `query` (string, required): The natural language query to search for.
  - `search_type` (string, optional, default: "semantic"): Currently only "semantic" is fully implemented for this tool.
  - `limit` (integer, optional, default: 10): The maximum number of relevant memories to return.
- **Example Use (internal):** `search_memories(query="What did Donny tell me about his favorite color?")`

#### 3. `search_by_type`

- **Purpose:** Retrieves memories that match a specific `memory_type` (e.g., all "facts" or all "preferences").
- **Parameters:**
  - `memory_type` (string, required): The type of memory to search for (e.g., "conversation", "fact", "preference").
  - `limit` (integer, optional, default: 20): The maximum number of memories to return.
- **Example Use (internal):** `search_by_type(memory_type="fact", limit=5)`

#### 4. `search_by_tags`

- **Purpose:** Finds memories associated with one or more specific tags.
- **Parameters:**
  - `tags` (string, required): Comma-separated tags to search for (e.g., "hobby, music").
  - `limit` (integer, optional, default: 20): The maximum number of memories to return.
- **Example Use (internal):** `search_by_tags(tags="personal, family")`

#### 5. `get_recent_memories`

- **Purpose:** Fetches the most recently stored memories, useful for recalling recent context or conversation flow.
- **Parameters:**
  - `limit` (integer, optional, default: 20): The maximum number of recent memories to retrieve.
- **Example Use (internal):** `get_recent_memories(limit=5)`

#### 6. `update_memory`

- **Purpose:** Modifies an existing memory identified by its unique `memory_id`. This allows for correcting or enriching stored information.
- **Parameters:**
  - `memory_id` (string, required): The unique identifier of the memory to update.
  - `title` (string, optional): New title for the memory.
  - `content` (string, optional): New content for the memory.
  - `tags` (string, optional): New comma-separated tags for the memory.
  - `importance` (integer, optional): New importance level for the memory.
- **Example Use (internal):** `update_memory(memory_id="mem_123abc", content="Donny's favorite color is now blue, not green.", importance=9)`

#### 7. `delete_memory`

- **Purpose:** Permanently removes a memory from the system using its unique `memory_id`.
- **Parameters:**
  - `memory_id` (string, required): The unique identifier of the memory to delete.
- **Example Use (internal):** `delete_memory(memory_id="mem_456def")`

#### 8. `get_memory_stats`

- **Purpose:** Retrieves basic statistics about the memory system, such as the total number of memories stored.
- **Parameters:** None.
- **Example Use (internal):** `get_memory_stats()`

#### 9. `create_backup`

- **Purpose:** Manually triggers a full backup of the memory system (SQLite DB, ChromaDB, and JSON export). This is in addition to the automatic backups.
- **Parameters:** None.
- **Example Use (internal):** `create_backup()`

#### 10. `search_by_date_range`

- **Purpose:** Searches for memories that fall within a specified date range.
- **Parameters:**
  - `date_from` (string, required): The start date (ISO format, e.g., "2025-01-01" or "2025-01-01T10:30:00Z").
  - `date_to` (string, optional, default: current UTC time): The end date (ISO format).
  - `limit` (integer, optional, default: 50): The maximum number of memories to return.
- **Example Use (internal):** `search_by_date_range(date_from="2025-09-01", date_to="2025-09-15")`

## 🧭 Tool Selection Logic

Your AI companion chooses memory tools automatically based on the conversation. The tools are never shown to the user — all results are expressed naturally in character — but it’s useful to know how the model decides which one to use.

### How Tools Are Chosen

- **remember** → Used when the user shares a new fact, preference, or event.  
  _Example:_ “My birthday is July 4th.” → AI silently stores this.
- **search_memories** → Used for natural free‑form recall.  
  _Example:_ “When’s my birthday?” → AI looks it up and replies.
- **search_by_type** → Used for category requests.  
  _Example:_ “Show me all my preferences.”
- **search_by_tags** → Used when tags are mentioned.  
  _Example:_ “Find everything tagged camping and truck.”
- **get_recent_memories** → Used for timeframe shorthand (“today,” “last night,” “yesterday”).  
  _Example:_ “What did we talk about yesterday?”
- **update_memory** → Used when correcting or modifying information.  
  _Example:_ “Update my favorite color to blue.”
- **delete_memory** → Used when the user wants the system to “forget” something.  
  _Example:_ “Forget my old phone number.”
- **search_by_date_range** → Used when a specific date window is mentioned.  
  _Example:_ “What did we discuss between Sept 10–15?”
- **get_memory_stats** → Used when asked about memory system size/status.  
  _Example:_ “How many memories do you have?”
- **create_backup** → Used when explicitly told to back up.  
  _Example:_ “Make a backup now.”

### Why This Matters

- The **system prompt** teaches the AI when each tool is appropriate.
- If the user never phrases things like categories, tags, or “forget this,” only `remember` and `search_memories` will appear in logs.
- To guide the AI toward other tools, phrase requests with keywords like:
  - “Update…” → `update_memory`
  - “Delete/forget…” → `delete_memory`
  - “Preferences/facts/events…” → `search_by_type`
  - “Tagged with…” → `search_by_tags`
  - “On Sept 28th…” → `search_by_date_range`

### Few Shot Examples

> _“Show me all my preferences so far.”_  
> → Uses `search_by_type(memory_type="preference")`

> _“Forget my old address.”_  
> → Uses `delete_memory(memory_id=…)`

> _“What did we talk about last night?”_  
> → Uses `get_recent_memories(limit=20)` or a date range

> _“How many memories do you have now?”_  
> → Uses `get_memory_stats()`

> _“Back everything up.”_  
> → Uses `create_backup()`

## 🔄 What’s New

**Semantic search improvements**

- Distance→similarity fix: relevance = 1.0 − distance
- Adaptive threshold: follows top match (clamped) to reduce noise when strong matches exist
- Top‑1 fallback: if nothing passes threshold, return the strongest candidate (optional guard at 0.08)

**Human‑like memory dynamics**

- Lazy Decay:
  - On access, compute decay based on time since last_accessed (fallback: timestamp)
  - Exponential half‑life per memory_type (conversation, fact, preference, task, ephemeral)
  - Never decays below type floors; protected tags (core, identity, pinned) skip decay
  - Writes are rate‑limited and only persisted for meaningful deltas (≥ 0.5)

**Reinforcement:**

- Each retrieval accumulates +0.1 in metadata
- When accumulation reaches +0.5, write back a +0.5 importance bump (rounded to halves)
- Capped at importance 10

**Logging and observability**

- Clear logs for decay checks, skip reasons (protected/floor/step/rate‑limit), and writes
- Logs for reinforcement accumulation and write‑backs
- Candidate similarities and adaptive threshold shown for semantic queries

## 🛠 Contributing

Pull requests welcome!

- Found a bug? Open an issue.
- Want to add features (custom backup schedule, encryption, etc.)? Let’s collaborate.

## 📜 License

### MIT

🔥 With this setup, your AI can build a persistent, evolving memory that feels natural across conversations, models, and even years.
