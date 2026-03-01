# Go Factory Pattern

Factories compose objects by wiring dependencies. They contain **zero business logic** — only constructor calls.

## Rules

1. **`Create*` prefix** for factory functions, `New*` for constructors
2. **Zero logic** — no loops, conditionals, error handling, or business logic
3. **Return interfaces**, not concrete types
4. **All factories in one file**: `pkg/factory/factory.go`
5. **Only call constructors** — `New*()` or other `Create*()` functions

## Constructor Pattern (What Factories Create)

Every component follows: **public interface + private struct + `New*` constructor**.

```go
// Public interface — ideally single method (SRP)
type ConfigGenerator interface {
    GenerateConfig(ctx context.Context, alerts Alerts) (string, error)
}

// Private struct — lowercase, unexported
type configGenerator struct {
    db DB
}

// Public constructor — returns interface, not struct
func NewConfigGenerator(db DB) ConfigGenerator {
    return &configGenerator{db: db}
}
```

### Rules

1. **Single-method interfaces** preferred (Single Responsibility Principle)
2. **Private struct** — lowercase name, no exported fields
3. **`New*` constructor** — returns the interface type, never `*struct`
4. **Dependency injection** — all dependencies via constructor params, never setters
5. **No getters/setters** — interface methods do real work, not expose state

## Good Factory

```go
// pkg/factory/factory.go
func CreateUserService(db DB, validator Validator) UserService {
    return NewUserService(db, validator)
}

func CreateProxyHandler(db DB, secret Secret) http.Handler {
    return NewAuthHandler(
        NewProxy(CreateRoundTripper(db)),
        secret,
    )
}
```

## Bad Factory (DON'T)

```go
// ❌ Business logic in factory
func CreateService(db DB) Service {
    service := NewService(db)
    service.Initialize()  // execution!
    return service
}

// ❌ Loops, conditionals
func CreateHandler(items []Item) Handler {
    for _, item := range items {
        // ...
    }
}

// ❌ Named "New" instead of "Create"
func New(exec Executor) Factory {
    return &factory{executor: exec}
}
```

## Factory vs Runner

A factory **assembles** objects. A runner **executes** logic.

```go
// ❌ BAD: "Factory" that runs business logic
type Factory interface {
    Run(ctx context.Context) error
}

func New(exec Executor) Factory {
    return &factory{executor: exec}
}

// ✅ GOOD: Factory creates, Runner runs
// pkg/factory/factory.go
func CreateRunner(exec Executor) Runner {
    return NewRunner(exec, NewPromptScanner("prompts"))
}

// pkg/runner/runner.go
type Runner interface {
    Run(ctx context.Context) error
}
```

## Composition Patterns

```go
// Nested decorators
func CreateMessageHandler(db DB) MessageHandler {
    return NewBatchHandler(db,
        NewSkipErrorsHandler(
            NewMetricsHandler(NewCoreHandler()),
        ),
    )
}

// List composition
func CreateFilters() []Filter {
    return []Filter{
        NewAgeFilter(),
        NewStatusFilter(),
    }
}

// Run function wrapper (only acceptable anonymous func)
func CreateWorkerRun(db DB) run.Func {
    return func(ctx context.Context) error {
        return NewWorker(db).Run(ctx)
    }
}
```

## Checklist

- ✅ All factories in `pkg/factory/factory.go`
- ✅ `Create*` prefix (not `New*`)
- ✅ Zero business logic — only constructor calls
- ✅ Returns interface types
- ✅ Complex logic in separate implementation files
