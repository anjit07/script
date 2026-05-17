# Copilot Prompt Templates
# Copy-paste these into GitHub Copilot Chat for consistent, high-quality output

---

## PT-01 · Add New GraphQL Query Field
```
Task: Add a new GraphQL query field.

Field name: [FIELD_NAME]
Return type: [TYPE]
Input args: [ARG_NAME: ARG_TYPE, ...]
Data source: [external API name / endpoint]
Business rule: [describe any validation or mapping logic]

Follow the agent playbook:
1. Extend schema in resources/schema/
2. Add model if needed
3. Resolver delegates to service — no logic in resolver
4. Service validates input, calls WebClient, maps response
5. WebClient loads query from resources/graphql-query/
6. Use constants for all literals
7. Throw custom exception on failure
8. Write service unit test

Output each file with its full path as a header.
```

---

## PT-02 · Add New GraphQL Mutation
```
Task: Add a new GraphQL mutation.

Mutation name: [MUTATION_NAME]
Input type: [InputType fields]
Return type: [TYPE]
Side effect: [what this mutation changes]
Validation rules: [list rules]

Follow the agent playbook:
1. Add mutation to schema
2. Create Input and Response models
3. Resolver maps args to Input model → calls service
4. Service validates → calls WebClient → returns mapped response
5. WebClient posts to external API using query from resources/graphql-query/
6. Custom exception on any failure
7. Unit test: happy path + invalid input + WebClient failure

Output each file with its full path as a header.
```

---

## PT-03 · Integrate New External API
```
Task: Integrate a new external API call.

API name: [NAME]
Base URL constant: [or tell me to add it to constants]
Endpoint: [PATH]
HTTP method: [GET/POST/PUT]
Request payload: [describe or paste schema]
Response payload: [describe or paste schema]
Error scenario: [what to do on failure]

Follow the agent playbook:
1. Create WebClient method only — no logic
2. Load query/payload from resources/graphql-query/ if GraphQL
3. Create request/response models in model/
4. Create custom exception in exception/
5. Add all literals to constants/
6. Log error on failure, log info on success
7. Unit test mocking WebClient

Output each file with its full path as a header.
```

---

## PT-04 · Fix a Bug
```
Task: Fix a bug.

Layer affected: [resolver / service / WebClient]
Class name: [CLASSNAME]
Method name: [METHOD_NAME]
Error: [paste stack trace or describe wrong behavior]
Expected behavior: [describe]

Rules:
- Minimal change only
- Do NOT refactor unrelated code
- Add a unit test that catches this bug
- State: what changed, what did NOT change

Output: fixed method only + test case.
```

---

## PT-05 · Write Unit Tests
```
Task: Write unit tests for an existing method.

Class: [SERVICE_CLASS_NAME]
Method: [METHOD_NAME]
Dependencies to mock: [list injected dependencies]

Required test cases:
1. Happy path
2. Null/invalid input → custom exception
3. WebClient/downstream failure → custom exception propagated
4. [Any domain-specific edge case]

Use: @ExtendWith(MockitoExtension.class)
Assert: return value + exception type + exception message where relevant.
```

---

## PT-06 · Code Review Checklist (ask Copilot to review)
```
Review this code against our standards:

[PASTE CODE]

Check for:
- [ ] Field injection (must use constructor injection + final fields)
- [ ] Hardcoded string literals (must use constants)
- [ ] Logic in resolver (must delegate only)
- [ ] HTTP calls in service (must be in WebClient only)
- [ ] Raw RuntimeException throws (must use custom exceptions)
- [ ] Deep nesting > 2 levels (extract methods)
- [ ] Missing null checks
- [ ] Missing logging on failures
- [ ] Duplicate code that could reuse existing utilities
- [ ] Missing unit test coverage

Output: list each violation with line number and suggested fix.
```

---

## PT-07 · Add Constants
```
Task: Extract all hardcoded literals from this class into the constants package.

[PASTE CLASS]

Rules:
- Group by domain in the correct constants class
- Use UPPER_SNAKE_CASE for constant names
- Replace all occurrences in the original class
- Output: updated constants class + updated original class
```

---

## PT-08 · Scaffold New Feature End-to-End
```
Task: Scaffold a complete new feature end-to-end.

Feature name: [NAME]
Description: [what it does]
GraphQL operation: [query / mutation]
Field/mutation name: [NAME]
Input: [fields and types]
Output: [fields and types]
External API: [name, endpoint, method]
Business rules: [validation, mapping, error cases]

Generate in this order:
1. resources/schema/ → schema addition
2. model/ → request + response models
3. constant/ → all new literals
4. exception/ → custom exception if new error case
5. resources/graphql-query/ → .graphql query file
6. webclient/ → WebClient method
7. service/ → service method with validation + mapping
8. resolver/ → resolver method delegating to service
9. test/ → service unit test

Output each file with full package path as header.
Self-check against the checklist before output.
```
