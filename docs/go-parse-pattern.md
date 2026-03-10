# Parse Pattern

Type conversion from `any` to typed values with fallback support.

## Core Pattern

```go
// Parse — returns pointer + error (nil pointer on error)
func ParseOrderStatus(ctx context.Context, value any) (*OrderStatus, error) {
    str, err := libparse.ParseString(ctx, value)
    if err != nil {
        return nil, errors.Wrapf(ctx, err, "parse string failed")
    }
    status := OrderStatus(str)
    if err := status.Validate(ctx); err != nil {
        return nil, errors.Wrapf(ctx, err, "invalid order status")
    }
    return status.Ptr(), nil
}

// ParseDefault — returns value, uses fallback on error
func ParseOrderStatusDefault(ctx context.Context, value any, defaultValue OrderStatus) OrderStatus {
    status, err := ParseOrderStatus(ctx, value)
    if err != nil {
        return defaultValue
    }
    return *status
}
```

## Signatures

```go
// Primitives — value + error
func ParseX(ctx context.Context, value any) (X, error)
func ParseXDefault(ctx context.Context, value any, defaultValue X) X

// Custom types — pointer + error (nil on failure)
func ParseX(ctx context.Context, value any) (*X, error)
func ParseXDefault(ctx context.Context, value any, defaultValue X) X
```

## Rules

1. Use `libparse.ParseString(ctx, value)` from `github.com/bborbe/parse` as first step
2. Custom types return **pointer** `(*Type, error)` — allows nil on error
3. Primitives return **value** `(Type, error)`
4. **Always validate** parsed value before returning
5. ParseDefault checks error explicitly — never `*status` without nil check
6. **Wrap errors** with context: `errors.Wrapf(ctx, err, "description")`

## Bad

```go
// Value return for custom type — can't distinguish error from zero
func ParseOrderStatus(ctx, value) (OrderStatus, error) {}

// Nil dereference in ParseDefault
func ParseXDefault(ctx, value, def) X {
    x, _ := ParseX(ctx, value)
    return *x // panics if nil!
}

// Missing validation
status := OrderStatus(str)
return status.Ptr(), nil // accepts invalid values!

// Missing error wrapping
return nil, err // loses context
```

## Checklist

- [ ] Parse returns pointer for custom types
- [ ] ParseDefault checks error before dereferencing
- [ ] Validation on parsed value before return
- [ ] Error wrapping with `errors.Wrapf`
- [ ] Uses `github.com/bborbe/parse` for primitives
