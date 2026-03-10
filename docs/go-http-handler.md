# HTTP Handler Organization

Handlers in `pkg/handler/`, factories in `pkg/factory/`, no inline handlers in `main.go`.

## Directory Structure

```
service/
├── main.go                        # Only factory calls
├── pkg/
│   ├── factory/
│   │   └── factory.go             # Create* functions
│   └── handler/
│       ├── handler_suite_test.go
│       ├── exists.go              # One file per handler
│       └── forward-invoice.go     # Kebab-case filenames
```

## Handler Types

```go
// HTTP error handler (most common)
func NewExistsHandler(db libkv.DB) libhttp.WithError {
    return libhttp.WithErrorFunc(func(ctx context.Context, resp http.ResponseWriter, req *http.Request) error {
        return nil
    })
}

// Background task handler
func NewProcessAllHandler(processor Processor) run.Func {
    return func(ctx context.Context) error {
        return processor.ProcessAll(ctx)
    }
}

// JSON API handler
func NewDataHandler(fetcher Fetcher) libhttp.WithError {
    return libhttp.NewJsonHandler(libhttp.JsonHandlerFunc(func(ctx context.Context, req *http.Request) (interface{}, error) {
        return fetcher.Fetch(ctx)
    }))
}
```

## Factory Pattern

```go
// pkg/factory/factory.go
func CreateExistsHandler(db libkv.DB) http.Handler {
    return libhttp.NewErrorHandler(handler.NewExistsHandler(db))
}
```

## main.go

```go
// Before (BAD): inline handler
router.Path("/exists").Handler(libhttp.NewErrorHandler(libhttp.WithErrorFunc(func(...) error { ... })))

// After (GOOD): factory call
router.Path("/exists").Handler(factory.CreateExistsHandler(db))
```

## Naming

- Files: kebab-case (`forward-invoice.go`)
- Handler funcs: `New[Purpose]Handler`
- Factory funcs: `Create[Purpose]Handler`

## Rules

1. **Never** inline handlers in `main.go`
2. One handler per file in `pkg/handler/`
3. Factory wraps handler with appropriate wrapper (`NewErrorHandler`, `NewBackgroundRunHandler`)
4. Dependencies injected as constructor params, not closures
5. Handler returns `libhttp.WithError` or `run.Func`, not `http.Handler`

## Checklist

- [ ] No inline handlers in main.go
- [ ] Handlers in `pkg/handler/` with kebab-case filenames
- [ ] Factory methods in `pkg/factory/factory.go`
- [ ] Handler functions follow `New[Purpose]Handler` naming
- [ ] Factory functions follow `Create[Purpose]Handler` naming
