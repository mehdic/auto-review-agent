# Multi-Agent Orchestration Systems

This repository contains **two different multi-agent orchestration systems** for autonomous software development. Both use developer and tech lead agents collaborating, but with different implementation approaches.

## Quick Comparison

| Feature | Native Orchestrator | Script-Based Orchestrator |
|---------|-------------------|---------------------------|
| **Implementation** | Claude Code Task tool | Bash + tmux + state files |
| **Complexity** | Simple | Advanced |
| **Setup** | Copy-paste prompt | Run shell script |
| **Dependencies** | None | bash, tmux, python3 |
| **Best For** | Interactive development | Production automation |
| **Usage** | Paste prompt + task | `./launch-orchestrator.sh` |
| **State** | In-memory (conversation) | JSON files (persistent) |
| **Visibility** | Single conversation | Multiple tmux windows |
| **Documentation** | NATIVE_ORCHESTRATOR_GUIDE.md | ORCHESTRATION_GUIDE.md |

## System 1: Native Orchestrator (Recommended for Most Users)

### What It Is

Uses Claude Code's **built-in Task tool** to spawn sub-agents. The orchestrator coordinates developer and tech lead agents entirely through Claude's native capabilities.

### When to Use

- ✅ Interactive development sessions
- ✅ Prototyping features
- ✅ Learning multi-agent patterns
- ✅ Small to medium tasks (<50 tasks)
- ✅ Want simplicity and no setup

### How to Use

**Step 1**: Copy the orchestrator prompt
```bash
cat prompts/native_orchestrator.txt
```

**Step 2**: Paste in Claude Code + add your task
```
[Paste orchestrator prompt]

TASK: Implement JWT authentication for the REST API

Requirements:
- Token generation on login
- Token validation middleware
- Refresh token mechanism
- Rate limiting

Project: /path/to/project

START ORCHESTRATION NOW!
```

**Step 3**: Watch orchestrator spawn agents and coordinate!

### Files

```
prompts/
├── native_orchestrator.txt              # Main orchestrator
└── native-agents/
    ├── developer_task_prompt.txt        # Developer template
    └── techlead_task_prompt.txt         # Tech lead template

NATIVE_ORCHESTRATOR_GUIDE.md             # Complete guide
```

### Example Flow

```
YOU → ORCHESTRATOR
        ↓
    Spawns Developer (via Task tool)
        ↓
    Developer implements & reports
        ↓
    Spawns Tech Lead (via Task tool)
        ↓
    Tech Lead reviews & provides feedback
        ↓
    If changes needed: Spawns Developer with feedback
        ↓
    Repeats until approved
        ↓
    DONE!
```

### Documentation

📖 **[NATIVE_ORCHESTRATOR_GUIDE.md](NATIVE_ORCHESTRATOR_GUIDE.md)**

Complete guide with:
- Architecture overview
- Usage examples
- Customization options
- Advanced patterns
- Troubleshooting
- Best practices

## System 2: Script-Based Orchestrator (Production Grade)

### What It Is

Uses **bash scripts + tmux** to create persistent agent sessions. Orchestrator runs in background, managing state through JSON files and coordinating via file system.

### When to Use

- ✅ Long-running tasks (100+ tasks)
- ✅ Production automation
- ✅ Need persistent state
- ✅ Want real-time monitoring
- ✅ Background operation (detach and check later)

### How to Use

**Step 1**: Launch orchestrator
```bash
./launch-orchestrator.sh /path/to/project 001
```

**Step 2**: System creates tmux session with windows:
- Window 0: Developer agent (live Claude Code)
- Window 1: Tech lead agent (live Claude Code)
- Window 2: Orchestrator state monitor
- Window 3: Developer state monitor
- Window 4: Tech lead state monitor
- Window 5: Logs

**Step 3**: Detach and let it run
```bash
# Detach: Ctrl+b, then d
# Reattach: tmux attach -t orchestrator_001_xxxxx
```

**Step 4**: Stop when done
```bash
./stop-orchestrator.sh orchestrator_001_xxxxx
```

### Files

```
launch-orchestrator.sh                   # Start system
orchestrator-loop.sh                     # Main orchestration logic
stop-orchestrator.sh                     # Clean shutdown

prompts/
├── orchestrator_agent.txt               # Orchestrator instructions
└── sub-agents/
    ├── developer_agent.txt              # Developer instructions
    └── techlead_agent.txt               # Tech lead instructions

ORCHESTRATION_GUIDE.md                   # Complete guide
```

### Example Flow

```
USER → launch-orchestrator.sh
         ↓
     Creates tmux session
         ↓
     Starts orchestrator-loop.sh
         ↓
     Loop checks states every 30s
         ↓
     Decides: Who should act next?
         ↓
     Sends prompt to developer/tech lead window
         ↓
     Agents work, update state files
         ↓
     Loop detects state changes
         ↓
     Repeats until complete
```

### Documentation

📖 **[ORCHESTRATION_GUIDE.md](ORCHESTRATION_GUIDE.md)**

Complete guide with:
- Architecture diagrams
- State file schemas
- Workflow examples
- Monitoring instructions
- Troubleshooting
- Comparison with V1/V2

## Which Should I Use?

### Use Native Orchestrator If:

- 🎯 You're trying multi-agent for the first time
- 🎯 You want the simplest possible setup
- 🎯 You're working interactively with Claude Code
- 🎯 Your task takes <1 hour
- 🎯 You don't need to detach/reattach
- 🎯 You want everything in one conversation

**Example**: "I want to implement JWT auth and have Claude's developer and tech lead agents collaborate on it."

### Use Script-Based Orchestrator If:

- 🎯 You have a large task list (100+ items)
- 🎯 You need it to run in the background
- 🎯 You want to detach and check progress later
- 🎯 You need persistent state across sessions
- 🎯 You want real-time monitoring dashboards
- 🎯 You're running production automation

**Example**: "I have 75 failing tests I need fixed autonomously over several hours."

## Architecture Comparison

### Native Orchestrator Architecture

```
┌─────────────────────────────────────────┐
│  Main Claude Code Session (You)         │
└──────────────┬──────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│  Orchestrator Agent                      │
│  (In same conversation)                  │
│                                          │
│  Uses Task tool to spawn:                │
│    ├─→ Developer sub-agent               │
│    └─→ Tech Lead sub-agent               │
└──────────────────────────────────────────┘

Communication: Function call results in conversation
State: In-memory (conversation history)
Lifetime: Single Claude Code session
```

### Script-Based Architecture

```
┌─────────────────────────────────────────┐
│  User's Terminal                         │
└──────────────┬──────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│  orchestrator-loop.sh                    │
│  (Background process)                    │
│                                          │
│  Monitors state files every 30s          │
│  Decides who should act                  │
│  Sends prompts to tmux windows           │
└─────┬────────────────────────┬───────────┘
      │                        │
      ▼                        ▼
┌─────────────┐          ┌─────────────┐
│  Developer  │          │  Tech Lead  │
│  Window     │          │  Window     │
│  (Claude)   │          │  (Claude)   │
└─────────────┘          └─────────────┘
      │                        │
      └────────┬───────────────┘
               ▼
┌──────────────────────────────────────────┐
│  coordination/                           │
│    ├─ orchestrator_state.json            │
│    ├─ developer_state.json               │
│    ├─ techlead_state.json                │
│    └─ messages/*.json                    │
└──────────────────────────────────────────┘

Communication: JSON state files
State: Persistent on disk
Lifetime: Until stopped or completed
```

## Common Workflow Pattern

Both systems follow the same conceptual workflow:

```
1. ASSIGN TASK
   ↓
2. DEVELOPER IMPLEMENTS
   ├─ Writes code
   ├─ Runs tests
   └─ Reports completion
   ↓
3. TECH LEAD REVIEWS
   ├─ Reads code
   ├─ Evaluates quality
   └─ Decides: Approve or Request Changes
   ↓
4. DECISION POINT
   ├─ If APPROVED → Next task or complete
   └─ If CHANGES REQUESTED → Back to step 2 with feedback
```

The difference is in **how** agents communicate:
- **Native**: Via Task tool results in conversation
- **Script-based**: Via JSON files and tmux windows

## Getting Started

### Quickstart: Native Orchestrator

```bash
# 1. Copy the orchestrator prompt
cat prompts/native_orchestrator.txt | pbcopy

# 2. Open Claude Code and paste + add task
# 3. Watch it work!
```

### Quickstart: Script-Based Orchestrator

```bash
# 1. Launch orchestrator
./launch-orchestrator.sh /path/to/project 001

# 2. Watch in tmux windows
# 3. Detach: Ctrl+b, d
# 4. Reattach: tmux attach -t orchestrator_001_xxxxx
```

## Real-World Examples

### Example 1: Simple Feature (Native)

**Task**: Implement a REST API endpoint for user registration

**Approach**: Native Orchestrator
- Estimated time: 10-15 minutes
- Iterations: 2-3 (implement → review → fix → approve)
- Why: Quick, interactive, single feature

### Example 2: Large Refactoring (Script-Based)

**Task**: Fix 75 failing tests in Java project

**Approach**: Script-Based Orchestrator
- Estimated time: 2-4 hours
- Iterations: 100+ (one per test)
- Why: Long-running, need background operation

### Example 3: API Development (Native)

**Task**: Build complete CRUD API (5 endpoints)

**Approach**: Native Orchestrator
- Estimated time: 30-60 minutes
- Iterations: 10-15 (2-3 per endpoint)
- Why: Interactive, watching progress, moderate size

### Example 4: System Migration (Script-Based)

**Task**: Migrate 50 components from old framework to new

**Approach**: Script-Based Orchestrator
- Estimated time: 4-6 hours
- Iterations: 150+ (multiple per component)
- Why: Very long-running, want to detach and check later

## Combining Both Systems

You can use both! For example:

**Phase 1**: Use Native to prototype
```
Use native orchestrator to quickly implement proof-of-concept
of a complex feature, iterating with developer and tech lead
```

**Phase 2**: Use Script-Based for production
```
Once approach validated, use script-based orchestrator to
implement across entire codebase (50+ files) in background
```

## Evolution: V1 → V2 → V3-Native → V3-Script

### V1: Planner/Reviewer (Async File Polling)
- Simple async file-based coordination
- One-shot execution
- No persistence
- Limited to small tasks

### V2: Implementer/Watchdog (Persistent + Monitor)
- Persistent Claude session in tmux
- Watchdog monitors and nudges
- Better for long tasks
- No formal review cycle

### V3-Native: Orchestrator (Task Tool)
- **Uses Claude Code's native Task tool**
- Formal developer/tech lead collaboration
- Simple and accessible
- Interactive workflow

### V3-Script: Orchestrator (tmux + State Files)
- Same concepts as V3-Native
- Production-grade infrastructure
- Background operation
- Persistent state

**V3 (both variants) combines the best of V1 and V2:**
- ✅ Formal review cycle (from V1)
- ✅ Persistent operation (from V2)
- ✅ Clear role separation
- ✅ Quality enforcement
- ✅ Autonomous operation

## FAQs

**Q: Can I use both systems in the same project?**
A: Yes! They're independent. Use native for quick features, script-based for large automation.

**Q: Which is more "production-ready"?**
A: Script-based has more infrastructure (monitoring, recovery, persistence). But native can be production-ready for the right use cases.

**Q: Can I customize the prompts?**
A: Absolutely! Edit the prompt files to match your project's standards and requirements.

**Q: What if I want three agents (developer, tech lead, security)?**
A: With native: Modify orchestrator to spawn security agent. With script-based: Add security window and state file.

**Q: Can agents work in parallel?**
A: Native: Sequential (one at a time). Script-based: Could be extended for parallel developers. Currently sequential.

**Q: What about token usage?**
A: Native uses more tokens per task (spawning agents). Script-based uses tokens over longer time. Both are efficient in their contexts.

**Q: Can I see what agents are doing?**
A: Native: All in conversation. Script-based: Real-time in tmux windows.

**Q: What if an agent crashes?**
A: Native: Retry in conversation. Script-based: Automatic restart (up to 3 attempts).

## Contributing

To improve these systems:

1. **Enhance prompts** - Add better instructions, examples, edge cases
2. **Add agents** - Create specialized agents (security, performance, etc.)
3. **Improve orchestration** - Better decision logic, smarter coordination
4. **Add features** - Parallel execution, learning, metrics
5. **Write examples** - Document real-world usage patterns

## Support

- 📖 **Native**: See [NATIVE_ORCHESTRATOR_GUIDE.md](NATIVE_ORCHESTRATOR_GUIDE.md)
- 📖 **Script-Based**: See [ORCHESTRATION_GUIDE.md](ORCHESTRATION_GUIDE.md)
- 🐛 **Issues**: Open GitHub issue with details
- 💡 **Ideas**: PRs welcome!

## License

[Your project license]

---

**Ready to start multi-agent orchestration?**

Try the **Native Orchestrator** for your next feature! 🚀
