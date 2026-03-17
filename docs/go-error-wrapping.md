# Error Wrapping

All errors use `github.com/bborbe/errors`. Never `fmt.Errorf`. Never bare `return err`.

## Why ctx Matters

`errors.Wrapf(ctx, err, ...)` calls `AddContextDataToError(ctx, ...)` — extracts structured data from ctx and attaches to error. `context.Background()` loses all data. Never fabricate context — add `ctx` parameter instead.

## Core Pattern

```go
// Wrap existing error
return errors.Wrapf(ctx, err, "fetch account %s", accountID)

// New error (no cause)
return errors.Errorf(ctx, "unsupported period type: %s", periodType)

// Sentinel error — stdlib with alias
import stderrors "errors"
var ErrNotFound = stderrors.New("not found")

// Enrich context with data (carried into all wrapped errors downstream)
ctx = errors.AddToContext(ctx, "accountID", accountID)
```

## API

| Function | Use | Returns nil when err=nil |
|----------|-----|--------------------------|
| `Wrapf(ctx, err, fmt, args...)` | Wrap with format | Yes |
| `Wrap(ctx, err, msg)` | Wrap with message | Yes |
| `New(ctx, msg)` | New error | N/A |
| `Errorf(ctx, fmt, args...)` | New formatted error | N/A |
| `AddToContext(ctx, key, val)` | Enrich ctx for errors | N/A |

## Rules

1. **Never bare `return err`** — always `errors.Wrapf(ctx, err, "description")`
2. **Never `fmt.Errorf`** — use `errors.Wrapf` (wrapping) or `errors.Errorf` (new error)
3. **Never `context.Background()` in business logic** — add `ctx context.Context` parameter, update all callers
4. **Multi-return** — `return nil, errors.Wrapf(ctx, err, "...")`
5. **Inner closures** — do NOT wrap inside callbacks (`db.Update`, `filepath.WalkDir`) when outer scope wraps
6. **Remove unused imports** — drop `"fmt"` after replacing `fmt.Errorf`
7. **Sentinel errors** — `var ErrXxx = stderrors.New("...")` with `stderrors "errors"` alias

## context.Background() — Allowed Only In

- `main.go`, test files, top-level goroutine spawners in main
- **Never** in `pkg/`, `pkg/handler/`, `pkg/factory/`, service methods

## Fix: Missing ctx

```go
// ❌ fabricating context
func (s *svc) validate(input string) error {
    return errors.Errorf(context.Background(), "invalid: %s", input)
}

// ✅ add ctx, update callers
func (s *svc) validate(ctx context.Context, input string) error {
    return errors.Errorf(ctx, "invalid: %s", input)
}
```

## Good / Bad

```go
// ❌ bare return
return err

// ❌ fmt.Errorf
return fmt.Errorf("fetch failed: %w", err)

// ❌ context.Background in pkg/
return errors.Wrapf(context.Background(), err, "fetch failed")

// ❌ double-wrap inner closure
err := db.Update(func(tx *bolt.Tx) error {
    return errors.Wrapf(ctx, putErr, "put") // redundant
})
return errors.Wrapf(ctx, err, "update")

// ✅ wrap with context
return errors.Wrapf(ctx, err, "fetch account %s", id)

// ✅ new error
return errors.Errorf(ctx, "unknown type: %s", t)

// ✅ sentinel
var ErrNotFound = stderrors.New("item not found")

// ✅ inner closure bare return (outer wraps)
err := db.Update(func(tx *bolt.Tx) error { return tx.Put(k, v) })
return errors.Wrapf(ctx, err, "update")
```

## Checklist

- [ ] No bare `return err`
- [ ] No `fmt.Errorf`
- [ ] No `context.Background()` outside main.go/tests
- [ ] Every wrapping function has `ctx context.Context` parameter
- [ ] Inner closure returns not double-wrapped
- [ ] Unused `"fmt"` imports removed
- [ ] Sentinel errors use `stderrors "errors"` alias
