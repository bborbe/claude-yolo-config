# Test Types

Unit vs Integration vs E2E — distinguished by dependency patterns, not files or tags.

## Overview

| Type | Scope | Dependencies | Speed | `make test`? |
|------|-------|-------------|-------|-------------|
| Unit | Single file | All mocked (Counterfeiter) | ms | Yes |
| Integration | Multiple files | In-memory/in-process only | seconds | Yes |
| E2E | Full system | External resources (DB servers, APIs) | minutes | No |

## Unit Tests

All deps mocked. Test business logic, validation, algorithms.

```go
var _ = Describe("UserServiceRetry", func() {
    var mockUserService *mocks.UserService
    BeforeEach(func() {
        mockUserService = &mocks.UserService{}
    })
    // ...
})
```

## Integration Tests

Real in-memory resources. Test persistence, transactions, message parsing.

```go
var _ = Describe("UserStore", func() {
    var db libkv.DB
    BeforeEach(func() {
        db, err = libbadgerkv.OpenMemory(ctx) // in-process, no network
        Expect(err).To(BeNil())
    })
    AfterEach(func() { _ = db.Close() })
    // ...
})
```

**In-memory** (integration): `libbadgerkv.OpenMemory()`, `libmemorykv.OpenMemory()`, `libboltkv.OpenTemp()`, real Kafka message types, real HTTP response types.

**External** (E2E only): PostgreSQL/MySQL servers, HTTP calls to external APIs, Kubernetes clusters, Docker containers.

## Decision Tree

1. Testing single file/component? → **Unit** (all mocked)
2. Testing multiple files together, in-process? → **Integration** (in-memory DB)
3. Needs external resource (DB server, external API)? → **E2E** (explicit run only)

## Rules

1. **Most tests = unit tests** (testing pyramid)
2. No build tags or Ginkgo labels to separate types
3. Unit + integration run together with `make test`
4. E2E never runs automatically — explicit trigger only
5. Don't mock everything in integration tests (that's a unit test)
6. Don't use real DBs for business logic (that's wasted integration test)

## Bad

```go
// "Integration" with all mocks — this is a unit test
var mockDB *mocks.DB // wrong for integration

// Unit test with real DB — unnecessary overhead
db, _ = libbadgerkv.OpenMemory(ctx)
result := CalculateDiscount(100.0, 0.1) // pure function!

// Tests depend on each other
var globalOrder Order // shared state across tests
```

## Checklist

- [ ] Business logic tested with unit tests (mocked deps)
- [ ] Persistence tested with integration tests (in-memory DB)
- [ ] No external network calls in unit/integration tests
- [ ] Each test independent (no shared mutable state)
