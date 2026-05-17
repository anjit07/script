# Copilot Instructions

## Prime Directive
Read and understand existing code before generating anything. Match existing style, structure, and patterns exactly.

## Architecture (strict layer boundaries)
| Layer | Responsibility |
|---|---|
| `resolver` | GraphQL mapping only — no logic |
| `service` | Business logic only — no HTTP |
| `WebClient` | All external API calls only |
| `model` | Request/response POJOs only |
| `constant` | String/literal constants only |
| `exception` | Custom exceptions only |

## File Locations
- GraphQL schema → `resources/schema/`
- GraphQL queries → `resources/graphql-query/` (`.graphql` files)

## Mandatory Coding Rules
- Constructor injection only — no `@Autowired` on fields
- All injected fields must be `final`
- Use Lombok: `@RequiredArgsConstructor`, `@Slf4j`, `@Builder`, `@Data` where applicable
- Never hardcode literals — use constants
- Reuse existing classes, utilities, and constants before creating new ones
- Methods: single responsibility, small, named by intent
- Validate all inputs at service entry points
- Handle nulls defensively throughout
- Throw custom exceptions only — never raw `RuntimeException`
- Log: all failures (`log.error`) + key business events (`log.info`)
- Write unit tests for every new service method

## Hard Constraints
- Do NOT duplicate existing code
- Do NOT modify unrelated code
- Do NOT introduce new frameworks or dependencies
- Do NOT break existing behavior
- Do NOT use deep nesting (max 2 levels — extract methods instead)
- Do NOT create unnecessary classes

## Documentation Rules
 
### Class-level Javadoc (required on every class)
```java
/**
 * [One-line summary of what this class does.]
 *
 * <p>Layer: [Resolver | Service | WebClient | Model | Exception | Constant]
 * <p>Responsibility: [Single responsibility this class owns]
 *
 * @author [team/squad name if present, else omit]
 */
```
 
### Method-level Javadoc (required on every public method)
```java
/**
 * [One-line summary — what this method does, not how.]
 *
 * @param [paramName] [what it represents, valid range/format if constrained]
 * @return [what is returned and when]
 * @throws [ExceptionType] [exact condition that triggers it]
 */
```
### Documentation Standards
- Do NOT document `private` helper methods unless logic is non-obvious
- Do NOT write Javadoc that just restates the method name (e.g. `/** Gets the user. */` on `getUser()`)
- `@param` required for every parameter — describe meaning, not type
- `@return` required unless return type is `void`
- `@throws` required for every checked and custom exception thrown
- No `@author` on methods — class level only
- No inline comments except for non-obvious business rule explanations
- Inline comments must explain **why**, never **what**
### Layer-specific doc conventions
| Layer | Required tags |
|---|---|
| `resolver` | `@param`, `@return` — note which GraphQL field it maps |
| `service` | `@param`, `@return`, `@throws` — note business rule enforced |
| `WebClient` | `@param`, `@return`, `@throws` — note external API called |
| `model` | Field-level `/** [what this field represents] */` on non-obvious fields |
| `exception` | Class Javadoc only — describe the error condition it represents |
| `constant` | Inline `/** [what this constant is used for] */` on each constant |
 
## Output Expectations
- Generate only the minimum code needed
- Every generated class must compile and be immediately usable
- Follow existing package naming conventions exactly
- Every generated class and public method must include Javadoc — no exceptions
