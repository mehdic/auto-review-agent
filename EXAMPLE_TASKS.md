# Example Tasks for Testing the Agent System

Here are some example tasks you can use to test the autonomous agent system:

## Simple Tasks (Quick to implement)

### 1. User Authentication API
```bash
./launch-agents.sh /path/to/project "Create a REST API for user authentication with JWT tokens"
```
Expected: Planner will propose JWT, sessions, OAuth. Reviewer will likely choose JWT. Implementation takes 1-2 hours.

### 2. Database Schema
```bash
./launch-agents.sh /path/to/project "Design a database schema for a blog platform with users, posts, and comments"
```
Expected: Planner will propose different database approaches (SQL, NoSQL). Reviewer will evaluate based on scale needs.

### 3. Error Handling
```bash
./launch-agents.sh /path/to/project "Add comprehensive error handling to all API endpoints"
```
Expected: Planner will propose centralized vs distributed error handling. Reviewer will choose based on project structure.

## Medium Complexity Tasks

### 4. Search Feature
```bash
./launch-agents.sh /path/to/project "Implement full-text search functionality with filtering and pagination"
```
Expected: Planner will propose Elasticsearch, PostgreSQL full-text, or in-memory search. Takes 3-4 hours.

### 5. File Upload System
```bash
./launch-agents.sh /path/to/project "Create a file upload system with image resizing and cloud storage"
```
Expected: Planner will propose local storage, S3, or Cloudinary. Multiple technical considerations.

### 6. Rate Limiting
```bash
./launch-agents.sh /path/to/project "Implement rate limiting middleware to prevent API abuse"
```
Expected: Planner will propose Redis-based, in-memory, or database-backed rate limiting.

## Complex Tasks (Long running)

### 7. Real-time Chat
```bash
./launch-agents.sh /path/to/project "Build a real-time chat system with WebSockets and message history"
```
Expected: Planner will propose WebSocket, Socket.io, or Server-Sent Events. Takes 6+ hours.

### 8. Payment Integration
```bash
./launch-agents.sh /path/to/project "Integrate Stripe payment processing with webhook handling"
```
Expected: Planner will propose different payment flows. Reviewer will emphasize security.

### 9. Microservices Architecture
```bash
./launch-agents.sh /path/to/project "Refactor monolith into microservices architecture"
```
Expected: Long analysis phase. Planner will propose different decomposition strategies.

## Testing & Quality Tasks

### 10. Test Coverage
```bash
./launch-agents.sh /path/to/project "Write unit tests to achieve 80% code coverage"
```
Expected: Planner will propose test frameworks and strategies. Systematic implementation.

### 11. Performance Optimization
```bash
./launch-agents.sh /path/to/project "Optimize database queries and add caching to improve API performance"
```
Expected: Planner will propose different caching strategies (Redis, in-memory, CDN).

### 12. Security Audit
```bash
./launch-agents.sh /path/to/project "Perform security audit and fix all vulnerabilities"
```
Expected: Planner will create checklist of security concerns. Systematic fixes.

## Documentation Tasks

### 13. API Documentation
```bash
./launch-agents.sh /path/to/project "Generate comprehensive API documentation with examples"
```
Expected: Planner will propose OpenAPI/Swagger, Postman, or custom docs. Quick implementation.

### 14. Onboarding Guide
```bash
./launch-agents.sh /path/to/project "Create developer onboarding documentation with setup instructions"
```
Expected: Planner will propose structure. Straightforward implementation.

## Good First Test

Start with this simple task to verify everything works:

```bash
./launch-agents.sh /path/to/project "Add input validation to the login endpoint"
```

This is simple enough to complete quickly but complex enough to see:
- Planner creating multiple approaches
- Reviewer evaluating and choosing
- Planner implementing autonomously
- Full workflow from start to finish

## Observing Agent Communication

During any of these tasks, you can watch the agents communicate:

```bash
# In a separate terminal
watch -n 2 "cat /path/to/project/coordination/task_proposals.json | jq ."

# Or watch the logs
tail -f /path/to/project/coordination/logs/notifications.log
```

You should see:
1. Planner analyzing and creating proposals
2. Status changing to "awaiting_review"
3. Reviewer evaluating (within 30 seconds)
4. Status changing to "approved" with chosen approach
5. Planner implementing (within 30 seconds of approval)
6. Status changing to "completed"

## Tips for Testing

1. **Start Small** - Begin with simple tasks to understand the flow
2. **Watch Logs** - Keep the logs window visible (Ctrl+b 3)
3. **Check Monitor** - The monitoring dashboard (Ctrl+b 2) shows everything
4. **Be Patient** - Agents check files every 30 seconds, so there may be brief pauses
5. **Intervene** - Try interrupting mid-task to see how agents respond
6. **Review Output** - Always check the actual code changes made

## Troubleshooting Common Issues

If agents seem stuck:
1. Check both agent windows (Ctrl+b 0 and Ctrl+b 1)
2. Look at the logs for errors
3. Manually check `coordination/task_proposals.json` for status
4. Try giving the agent a nudge: "Please continue"

If proposals are poor quality:
1. Give more detailed task descriptions
2. Add context about the project in the initial message
3. Modify the prompts to be more specific to your needs

Have fun testing! 🚀
