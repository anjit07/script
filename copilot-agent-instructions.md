# Copilot Agent Instructions
# Stack: Java · Spring Boot · GraphQL · WebClient · Lombok

## Agent Behavior Rules
- Always scan the full file tree before generating any file
- Always read the existing resolver, service, and WebClient before adding to them
- Never assume a class, constant, or exception doesn't exist — search first
- Generate files in dependency order: model → constant → exception → WebClient → service → resolver → schema → test
- After generating, self-check: does every import resolve? does every constant exist?

---

## Task Playbooks

### PLAYBOOK: Add a New GraphQL Field

**Trigger:** "add field", "expose field", "add query", "add mutation"

**Steps — execute in order:**
1. [ ] Read existing schema in `resources/schema/`
2. [ ] Read existing resolver for the type being extended
3. [ ] Add field to `.graphql` schema — minimal change only
4. [ ] Add/reuse model class in `model/` package
5. [ ] Add resolver method → delegates to service immediately, zero logic
6. [ ] Add service method → validate input → call WebClient → map response
7. [ ] Add WebClient method → load query from `resources/graphql-query/` → execute → return raw response
8. [ ] Add `.graphql` query file if external GraphQL call is needed
9. [ ] Add constants for any new string literals
10. [ ] Write unit test for the service method only
11. [ ] Self-check: no hardcoded strings, no raw exceptions, no field injection

**Output format:**
```
[SCHEMA]     resources/schema/<Type>.graphql         → added field
[MODEL]      model/<Name>Request.java / <Name>Response.java
[CONSTANT]   constant/<Domain>Constants.java         → added if new literals
[EXCEPTION]  exception/<Name>Exception.java          → added if new error case
[WEBCLIENT]  webclient/<Name>WebClient.java          → added method
[SERVICE]    service/<Name>Service.java              → added method
[RESOLVER]   resolver/<Name>Resolver.java            → added mapping
[QUERY]      resources/graphql-query/<name>.graphql  → added if needed
[TEST]       test/.../service/<Name>ServiceTest.java → added test
```

---

### PLAYBOOK: Add a New External API Call

**Trigger:** "call external API", "integrate", "fetch from", "new endpoint"

**Steps — execute in order:**
1. [ ] Read existing WebClient classes — reuse base URL, headers, error handling
2. [ ] Create/extend WebClient class only — no logic, no mapping
3. [ ] Load GraphQL query from file — never inline query strings
4. [ ] Add response model in `model/`
5. [ ] Add custom exception in `exception/` for this API's failure case
6. [ ] Add constants for endpoint path, header names, error messages
7. [ ] Log `log.error` on failure with context; `log.info` on success with key fields
8. [ ] Write unit test mocking the WebClient

**Rules:**
- Never put HTTP logic in service
- Never hardcode URLs, headers, or query strings
- Always throw custom exception on non-2xx response

---

### PLAYBOOK: Add a New Service Method

**Trigger:** "add business logic", "add service method", "implement logic"

**Steps — execute in order:**
1. [ ] Read the full service class first
2. [ ] Check if any existing private method can be reused
3. [ ] Validate all inputs at method entry (throw custom exception if invalid)
4. [ ] Keep method under 20 lines — extract private helpers if needed
5. [ ] Never call WebClient directly — inject via constructor and delegate
6. [ ] Log key business events with `log.info`
7. [ ] Write unit test: happy path + at least 2 edge cases

---

### PLAYBOOK: Fix a Bug

**Trigger:** "fix", "bug", "incorrect", "wrong output", "null pointer", "exception"

**Steps — execute in order:**
1. [ ] Read the full stack trace or error description
2. [ ] Identify the exact layer (resolver / service / WebClient)
3. [ ] Read the full method where the bug lives
4. [ ] Make the minimal change only — do NOT refactor unrelated code
5. [ ] Add null check or validation if root cause is missing guard
6. [ ] Add/update unit test that would have caught this bug
7. [ ] State explicitly: what was wrong, what was changed, what was NOT changed

---

### PLAYBOOK: Write Unit Tests

**Trigger:** "write test", "add test", "unit test", "test coverage"

**Steps — execute in order:**
1. [ ] Read the full method under test
2. [ ] Identify: inputs, dependencies, outputs, exceptions
3. [ ] Mock all dependencies — never use real WebClient or DB
4. [ ] Test cases required:
   - Happy path (valid input → expected output)
   - Null/empty input → exception thrown
   - WebClient failure → custom exception propagated
   - Edge case specific to business logic
5. [ ] Use `@ExtendWith(MockitoExtension.class)`
6. [ ] Assert both return value AND side effects (log, exception message)

---

## Self-Check Checklist (run before every output)
- [ ] All imports resolve to existing classes
- [ ] No hardcoded string literals (use constants)
- [ ] No raw `RuntimeException` or `Exception` throws
- [ ] No field injection (`@Autowired` on field)
- [ ] No logic in resolver
- [ ] No HTTP calls in service
- [ ] All new methods have a corresponding test
- [ ] No unrelated code modified
- [ ] No new framework or dependency introduced
