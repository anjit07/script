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

## Output Expectations
- Generate only the minimum code needed
- Every generated class must compile and be immediately usable
- Follow existing package naming conventions exactly
