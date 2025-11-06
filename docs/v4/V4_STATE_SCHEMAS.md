# V4 State File Schemas

This document defines the JSON schemas for all state files used in the V4 orchestration system.

## Overview

State files provide "memory" to stateless Task-spawned agents. Each time an agent is spawned, it receives the current state, processes it, updates it, and writes it back before dying.

## State Files Location

```
coordination/
├── pm_state.json               # Project Manager memory
├── group_status.json           # Per-group tracking
├── orchestrator_state.json     # Orchestration decisions
└── messages/
    ├── dev_to_qa.json          # Developer → QA handoffs
    ├── qa_to_techlead.json     # QA → Tech Lead handoffs
    └── techlead_to_dev.json    # Tech Lead → Developer feedback
```

---

## pm_state.json

**Purpose**: Maintains Project Manager's memory across spawns

**Schema**:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "session_id": {
      "type": "string",
      "description": "Unique session identifier (e.g., v4_20250106_100000)"
    },
    "mode": {
      "type": "string",
      "enum": ["simple", "parallel"],
      "description": "Execution mode decided by PM"
    },
    "mode_reasoning": {
      "type": "string",
      "description": "Why PM chose this mode"
    },
    "original_requirements": {
      "type": "string",
      "description": "Full user requirements text"
    },
    "all_tasks": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": {"type": "string"},
          "description": {"type": "string"},
          "group_id": {"type": "string"},
          "status": {
            "type": "string",
            "enum": ["pending", "in_progress", "complete"]
          }
        }
      }
    },
    "task_groups": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": {"type": "string"},
          "name": {"type": "string"},
          "tasks": {
            "type": "array",
            "items": {"type": "string"}
          },
          "files_affected": {
            "type": "array",
            "items": {"type": "string"}
          },
          "branch_name": {"type": "string"},
          "status": {
            "type": "string",
            "enum": ["pending", "assigned", "in_progress", "complete"]
          },
          "can_parallel": {"type": "boolean"},
          "depends_on": {
            "type": "array",
            "items": {"type": "string"}
          },
          "complexity": {
            "type": "string",
            "enum": ["low", "medium", "high"]
          },
          "estimated_effort_minutes": {"type": "number"}
        }
      }
    },
    "execution_phases": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "phase_number": {"type": "integer"},
          "group_ids": {
            "type": "array",
            "items": {"type": "string"}
          },
          "parallel_count": {"type": "integer"},
          "status": {
            "type": "string",
            "enum": ["pending", "in_progress", "complete"]
          }
        }
      }
    },
    "completed_groups": {
      "type": "array",
      "items": {"type": "string"}
    },
    "in_progress_groups": {
      "type": "array",
      "items": {"type": "string"}
    },
    "pending_groups": {
      "type": "array",
      "items": {"type": "string"}
    },
    "iteration": {"type": "integer"},
    "last_update": {
      "type": "string",
      "format": "date-time"
    },
    "completion_percentage": {"type": "number"},
    "estimated_time_remaining_minutes": {"type": "number"}
  },
  "required": [
    "session_id",
    "mode",
    "original_requirements",
    "task_groups",
    "iteration",
    "last_update"
  ]
}
```

**Example**:

```json
{
  "session_id": "v4_20250106_100000",
  "mode": "parallel",
  "mode_reasoning": "3 independent features affecting different file areas, suitable for parallel execution",
  "original_requirements": "Implement JWT authentication, user registration, and password reset functionality",
  "all_tasks": [
    {
      "id": "T1",
      "description": "Implement JWT token generation",
      "group_id": "A",
      "status": "complete"
    },
    {
      "id": "T2",
      "description": "Implement JWT validation middleware",
      "group_id": "A",
      "status": "complete"
    },
    {
      "id": "T3",
      "description": "Implement user registration endpoint",
      "group_id": "B",
      "status": "complete"
    },
    {
      "id": "T4",
      "description": "Implement password reset flow",
      "group_id": "C",
      "status": "in_progress"
    }
  ],
  "task_groups": [
    {
      "id": "A",
      "name": "JWT Authentication System",
      "tasks": ["T1", "T2"],
      "files_affected": ["auth.py", "middleware.py", "test_auth.py"],
      "branch_name": "feature/group-A-jwt-auth",
      "status": "complete",
      "can_parallel": true,
      "depends_on": [],
      "complexity": "medium",
      "estimated_effort_minutes": 15
    },
    {
      "id": "B",
      "name": "User Registration",
      "tasks": ["T3"],
      "files_affected": ["users.py", "test_users.py"],
      "branch_name": "feature/group-B-user-reg",
      "status": "complete",
      "can_parallel": true,
      "depends_on": [],
      "complexity": "low",
      "estimated_effort_minutes": 10
    },
    {
      "id": "C",
      "name": "Password Reset",
      "tasks": ["T4"],
      "files_affected": ["password_reset.py", "test_reset.py"],
      "branch_name": "feature/group-C-pwd-reset",
      "status": "in_progress",
      "can_parallel": true,
      "depends_on": ["A"],
      "complexity": "medium",
      "estimated_effort_minutes": 12
    }
  ],
  "execution_phases": [
    {
      "phase_number": 1,
      "group_ids": ["A", "B"],
      "parallel_count": 2,
      "status": "complete"
    },
    {
      "phase_number": 2,
      "group_ids": ["C"],
      "parallel_count": 1,
      "status": "in_progress"
    }
  ],
  "completed_groups": ["A", "B"],
  "in_progress_groups": ["C"],
  "pending_groups": [],
  "iteration": 12,
  "last_update": "2025-01-06T10:30:00Z",
  "completion_percentage": 66.7,
  "estimated_time_remaining_minutes": 5
}
```

---

## group_status.json

**Purpose**: Detailed tracking for each task group

**Schema**:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "additionalProperties": {
    "type": "object",
    "properties": {
      "group_id": {"type": "string"},
      "group_name": {"type": "string"},
      "status": {
        "type": "string",
        "enum": [
          "pending",
          "dev_working",
          "dev_blocked",
          "waiting_qa",
          "qa_testing",
          "qa_failed",
          "waiting_review",
          "tech_review",
          "changes_requested",
          "complete"
        ]
      },
      "current_agent": {
        "type": "string",
        "enum": ["developer", "qa_expert", "tech_lead", "none"]
      },
      "iterations": {
        "type": "object",
        "properties": {
          "developer": {"type": "integer"},
          "qa": {"type": "integer"},
          "tech_lead": {"type": "integer"}
        }
      },
      "start_time": {"type": "string", "format": "date-time"},
      "end_time": {"type": "string", "format": "date-time"},
      "duration_minutes": {"type": "number"},
      "branch_name": {"type": "string"},
      "files_modified": {
        "type": "array",
        "items": {"type": "string"}
      },
      "commits": {
        "type": "array",
        "items": {"type": "string"}
      },
      "test_results": {
        "type": "object",
        "properties": {
          "unit_tests": {
            "type": "object",
            "properties": {
              "total": {"type": "integer"},
              "passed": {"type": "integer"},
              "failed": {"type": "integer"}
            }
          },
          "integration_tests": {
            "type": "object",
            "properties": {
              "total": {"type": "integer"},
              "passed": {"type": "integer"},
              "failed": {"type": "integer"}
            }
          },
          "contract_tests": {
            "type": "object",
            "properties": {
              "total": {"type": "integer"},
              "passed": {"type": "integer"},
              "failed": {"type": "integer"}
            }
          },
          "e2e_tests": {
            "type": "object",
            "properties": {
              "total": {"type": "integer"},
              "passed": {"type": "integer"},
              "failed": {"type": "integer"}
            }
          }
        }
      },
      "tech_lead_feedback": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "iteration": {"type": "integer"},
            "decision": {
              "type": "string",
              "enum": ["approved", "changes_requested", "unblocked"]
            },
            "feedback": {"type": "string"},
            "timestamp": {"type": "string", "format": "date-time"}
          }
        }
      },
      "blockers": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "description": {"type": "string"},
            "resolved": {"type": "boolean"},
            "resolution": {"type": "string"}
          }
        }
      },
      "quality_metrics": {
        "type": "object",
        "properties": {
          "code_quality_score": {"type": "number"},
          "security_issues_count": {"type": "integer"},
          "first_pass_approval": {"type": "boolean"}
        }
      },
      "last_update": {"type": "string", "format": "date-time"}
    }
  }
}
```

**Example**:

```json
{
  "A": {
    "group_id": "A",
    "group_name": "JWT Authentication System",
    "status": "complete",
    "current_agent": "none",
    "iterations": {
      "developer": 2,
      "qa": 1,
      "tech_lead": 1
    },
    "start_time": "2025-01-06T10:00:00Z",
    "end_time": "2025-01-06T10:15:00Z",
    "duration_minutes": 15,
    "branch_name": "feature/group-A-jwt-auth",
    "files_modified": [
      "auth.py",
      "middleware.py",
      "test_auth.py"
    ],
    "commits": [
      "abc123 - Implement JWT generation",
      "def456 - Add validation middleware",
      "ghi789 - Fix rate limiting"
    ],
    "test_results": {
      "unit_tests": {
        "total": 12,
        "passed": 12,
        "failed": 0
      },
      "integration_tests": {
        "total": 8,
        "passed": 8,
        "failed": 0
      },
      "contract_tests": {
        "total": 5,
        "passed": 5,
        "failed": 0
      },
      "e2e_tests": {
        "total": 3,
        "passed": 3,
        "failed": 0
      }
    },
    "tech_lead_feedback": [
      {
        "iteration": 1,
        "decision": "changes_requested",
        "feedback": "Missing rate limiting on auth endpoints",
        "timestamp": "2025-01-06T10:10:00Z"
      },
      {
        "iteration": 2,
        "decision": "approved",
        "feedback": "Excellent implementation with proper rate limiting",
        "timestamp": "2025-01-06T10:15:00Z"
      }
    ],
    "blockers": [],
    "quality_metrics": {
      "code_quality_score": 8.5,
      "security_issues_count": 0,
      "first_pass_approval": false
    },
    "last_update": "2025-01-06T10:15:00Z"
  },
  "B": {
    "group_id": "B",
    "group_name": "User Registration",
    "status": "complete",
    "current_agent": "none",
    "iterations": {
      "developer": 1,
      "qa": 1,
      "tech_lead": 1
    },
    "start_time": "2025-01-06T10:00:00Z",
    "end_time": "2025-01-06T10:12:00Z",
    "duration_minutes": 12,
    "branch_name": "feature/group-B-user-reg",
    "files_modified": [
      "users.py",
      "test_users.py"
    ],
    "commits": [
      "jkl012 - Implement user registration"
    ],
    "test_results": {
      "unit_tests": {
        "total": 8,
        "passed": 8,
        "failed": 0
      },
      "integration_tests": {
        "total": 5,
        "passed": 5,
        "failed": 0
      },
      "contract_tests": {
        "total": 3,
        "passed": 3,
        "failed": 0
      },
      "e2e_tests": {
        "total": 2,
        "passed": 2,
        "failed": 0
      }
    },
    "tech_lead_feedback": [
      {
        "iteration": 1,
        "decision": "approved",
        "feedback": "Clean implementation, well tested",
        "timestamp": "2025-01-06T10:12:00Z"
      }
    ],
    "blockers": [],
    "quality_metrics": {
      "code_quality_score": 9.0,
      "security_issues_count": 0,
      "first_pass_approval": true
    },
    "last_update": "2025-01-06T10:12:00Z"
  }
}
```

---

## orchestrator_state.json

**Purpose**: Track orchestrator's decisions and workflow state

**Schema**:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "session_id": {"type": "string"},
    "current_phase": {
      "type": "string",
      "enum": [
        "initialization",
        "pm_planning",
        "developer_working",
        "qa_testing",
        "tech_review",
        "pm_final_check",
        "completed"
      ]
    },
    "active_agents": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "agent_type": {"type": "string"},
          "group_id": {"type": "string"},
          "spawned_at": {"type": "string", "format": "date-time"}
        }
      }
    },
    "iteration": {"type": "integer"},
    "total_spawns": {"type": "integer"},
    "decisions_log": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "iteration": {"type": "integer"},
          "decision": {"type": "string"},
          "reasoning": {"type": "string"},
          "timestamp": {"type": "string", "format": "date-time"}
        }
      }
    },
    "status": {
      "type": "string",
      "enum": ["running", "completed", "error"]
    },
    "start_time": {"type": "string", "format": "date-time"},
    "end_time": {"type": "string", "format": "date-time"},
    "last_update": {"type": "string", "format": "date-time"}
  },
  "required": ["session_id", "current_phase", "iteration", "status", "start_time"]
}
```

**Example**:

```json
{
  "session_id": "v4_20250106_100000",
  "current_phase": "tech_review",
  "active_agents": [
    {
      "agent_type": "tech_lead",
      "group_id": "C",
      "spawned_at": "2025-01-06T10:28:00Z"
    }
  ],
  "iteration": 15,
  "total_spawns": 15,
  "decisions_log": [
    {
      "iteration": 1,
      "decision": "spawn_pm_for_planning",
      "reasoning": "Initial planning phase",
      "timestamp": "2025-01-06T10:00:00Z"
    },
    {
      "iteration": 2,
      "decision": "spawn_3_developers_parallel",
      "reasoning": "PM decided parallel mode with 3 groups",
      "timestamp": "2025-01-06T10:02:00Z"
    },
    {
      "iteration": 5,
      "decision": "spawn_qa_expert_group_A",
      "reasoning": "Developer A ready for QA",
      "timestamp": "2025-01-06T10:08:00Z"
    }
  ],
  "status": "running",
  "start_time": "2025-01-06T10:00:00Z",
  "end_time": null,
  "last_update": "2025-01-06T10:28:00Z"
}
```

---

## messages/dev_to_qa.json

**Purpose**: Handoff messages from Developer to QA Expert

**Schema**:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "messages": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": {"type": "string"},
          "group_id": {"type": "string"},
          "from": {"type": "string", "const": "developer"},
          "to": {"type": "string", "const": "qa_expert"},
          "timestamp": {"type": "string", "format": "date-time"},
          "subject": {"type": "string"},
          "status": {"type": "string"},
          "context": {
            "type": "object",
            "properties": {
              "branch_name": {"type": "string"},
              "files_modified": {"type": "array", "items": {"type": "string"}},
              "commits": {"type": "array", "items": {"type": "string"}},
              "unit_tests_status": {"type": "string"},
              "notes": {"type": "string"}
            }
          },
          "read": {"type": "boolean"}
        }
      }
    }
  }
}
```

**Example**:

```json
{
  "messages": [
    {
      "id": "msg_20250106_100800",
      "group_id": "A",
      "from": "developer",
      "to": "qa_expert",
      "timestamp": "2025-01-06T10:08:00Z",
      "subject": "JWT Authentication Implementation Ready for QA",
      "status": "READY_FOR_QA",
      "context": {
        "branch_name": "feature/group-A-jwt-auth",
        "files_modified": ["auth.py", "middleware.py", "test_auth.py"],
        "commits": ["abc123", "def456"],
        "unit_tests_status": "12/12 passing",
        "notes": "Implemented JWT generation, validation, and refresh. All unit tests passing."
      },
      "read": true
    }
  ]
}
```

---

## messages/qa_to_techlead.json

**Purpose**: Handoff messages from QA Expert to Tech Lead

**Schema**:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "messages": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": {"type": "string"},
          "group_id": {"type": "string"},
          "from": {"type": "string", "const": "qa_expert"},
          "to": {"type": "string", "const": "tech_lead"},
          "timestamp": {"type": "string", "format": "date-time"},
          "subject": {"type": "string"},
          "result": {"type": "string", "enum": ["PASS", "FAIL"]},
          "test_results": {
            "type": "object",
            "properties": {
              "integration_tests": {"type": "string"},
              "contract_tests": {"type": "string"},
              "e2e_tests": {"type": "string"},
              "total_time": {"type": "string"}
            }
          },
          "developer_context": {
            "type": "object",
            "properties": {
              "files_modified": {"type": "array", "items": {"type": "string"}},
              "implementation_summary": {"type": "string"}
            }
          },
          "read": {"type": "boolean"}
        }
      }
    }
  }
}
```

**Example**:

```json
{
  "messages": [
    {
      "id": "msg_20250106_101200",
      "group_id": "A",
      "from": "qa_expert",
      "to": "tech_lead",
      "timestamp": "2025-01-06T10:12:00Z",
      "subject": "JWT Authentication QA Results - All Tests Passed",
      "result": "PASS",
      "test_results": {
        "integration_tests": "8/8 passed",
        "contract_tests": "5/5 passed",
        "e2e_tests": "3/3 passed",
        "total_time": "2m 15s"
      },
      "developer_context": {
        "files_modified": ["auth.py", "middleware.py", "test_auth.py"],
        "implementation_summary": "JWT authentication with generation, validation, refresh, and rate limiting"
      },
      "read": false
    }
  ]
}
```

---

## messages/techlead_to_dev.json

**Purpose**: Feedback from Tech Lead to Developer

**Schema**:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "properties": {
    "messages": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": {"type": "string"},
          "group_id": {"type": "string"},
          "from": {"type": "string", "const": "tech_lead"},
          "to": {"type": "string", "const": "developer"},
          "timestamp": {"type": "string", "format": "date-time"},
          "subject": {"type": "string"},
          "decision": {
            "type": "string",
            "enum": ["approved", "changes_requested", "unblocked"]
          },
          "feedback": {"type": "string"},
          "issues": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "priority": {
                  "type": "string",
                  "enum": ["critical", "high", "medium", "low"]
                },
                "title": {"type": "string"},
                "location": {"type": "string"},
                "description": {"type": "string"},
                "fix_suggestion": {"type": "string"}
              }
            }
          },
          "actionable_items": {
            "type": "array",
            "items": {"type": "string"}
          },
          "read": {"type": "boolean"}
        }
      }
    }
  }
}
```

**Example**:

```json
{
  "messages": [
    {
      "id": "msg_20250106_101000",
      "group_id": "A",
      "from": "tech_lead",
      "to": "developer",
      "timestamp": "2025-01-06T10:10:00Z",
      "subject": "JWT Authentication Review - Changes Requested",
      "decision": "changes_requested",
      "feedback": "Good implementation overall, but missing rate limiting on auth endpoints. This is critical for preventing brute force attacks.",
      "issues": [
        {
          "priority": "high",
          "title": "Missing rate limiting",
          "location": "auth.py:45",
          "description": "Auth endpoints don't have rate limiting",
          "fix_suggestion": "Add @limiter.limit('10 per minute') decorator to auth endpoints"
        }
      ],
      "actionable_items": [
        "Add rate limiting to auth endpoints",
        "Test rate limiting with multiple rapid requests",
        "Resubmit for review"
      ],
      "read": false
    }
  ]
}
```

---

## State File Lifecycle

### 1. Initialization

```
Orchestrator on first /orchestrate:
1. Create coordination/ folder
2. Initialize all state files with empty/default values
3. Generate unique session_id
4. Set timestamps
```

### 2. Agent Spawn Pattern

```
Before spawning any agent:
1. Orchestrator reads relevant state file(s)
2. Orchestrator includes state in agent prompt
3. Agent receives state as context

Agent processing:
4. Agent parses state
5. Agent performs its work
6. Agent updates state
7. Agent writes updated state back to file
8. Agent returns result
9. Agent instance dies

After agent returns:
10. Orchestrator logs the interaction
11. Orchestrator reads updated state
12. Orchestrator makes next decision
```

### 3. State Updates

```
Every agent that touches state files should:
1. Read current state
2. Validate state structure
3. Update relevant fields
4. Increment iteration counter
5. Set last_update timestamp
6. Write atomically (overwrite entire file)
```

### 4. State Persistence

```
State files persist across:
✅ Agent spawns and deaths
✅ Orchestrator decisions
✅ Multiple workflow phases
✅ Errors and retries
✅ Session interruptions

This enables:
✅ Resume capability
✅ Full audit trail
✅ Debugging
✅ Metrics collection
```

---

## Best Practices

### 1. Always Validate State

Agents should validate state structure before using:

```javascript
if (!state.session_id || !state.task_groups) {
  throw new Error("Invalid PM state structure");
}
```

### 2. Atomic Writes

Always write complete state file (don't try partial updates):

```javascript
// Good: Write entire state
write_file("pm_state.json", JSON.stringify(state, null, 2));

// Bad: Don't try to update in place
// (not possible with JSON files)
```

### 3. Timestamps

Always update timestamp on state changes:

```javascript
state.last_update = new Date().toISOString();
```

### 4. Defensive Reading

Handle missing or corrupted state gracefully:

```javascript
try {
  state = JSON.parse(read_file("pm_state.json"));
} catch (error) {
  // Initialize with defaults
  state = get_default_pm_state();
}
```

### 5. Iteration Tracking

Increment iteration on every update:

```javascript
state.iteration += 1;
```

This helps with:
- Progress tracking
- Stuck detection
- Performance metrics

---

## State File Monitoring

Users can monitor state at any time:

```bash
# Check PM state
cat coordination/pm_state.json | jq .

# Check specific group
cat coordination/group_status.json | jq '.A'

# Watch orchestrator decisions
watch -n 1 'cat coordination/orchestrator_state.json | jq .current_phase'

# Count total iterations
cat coordination/pm_state.json | jq .iteration
```

This visibility helps with:
- Understanding current status
- Debugging issues
- Learning from patterns
- Optimizing workflows

---

## Conclusion

These state schemas enable stateless Task-spawned agents to maintain persistent memory across spawns, providing the foundation for complex multi-agent orchestration while remaining fully observable and debuggable.
