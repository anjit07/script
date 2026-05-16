# Copilot Instructions

Understand existing implementation before generating code.
Follow existing package structure, naming, and coding style.

Architecture:
resolver -> service -> processor -> client

Rules:
- resolver: GraphQL mapping only
- service: orchestration only
- processor: business logic only
- client: downstream calls only

Standards:
- use constructor injection
- use final fields
- use lombok where applicable
- reuse existing classes/utilities/constants
- keep methods small and single responsibility
- validate all inputs
- handle null safely
- use custom exceptions only
- log failures and key business events
- never hardcode literals
- keep graphql schema in resources/schema
- keep graphql queries in resources/graphql-query
- write unit tests for new business logic

Avoid:
- duplicate code
- deep nesting
- unnecessary classes
- changing unrelated code
- breaking existing behavior
- introducing new frameworks

Always generate production-ready, readable, testable code.
Prefer minimal safe changes.
