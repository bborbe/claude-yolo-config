# Go Validation Framework

Declarative validation using `github.com/bborbe/validation`.

## Core API

```go
// AND — all must pass
validation.All{
    validation.Name("username", validation.NotEmptyString(u.Username)),
    validation.Name("email", validation.NotEmptyString(u.Email)),
    validation.Name("status", u.Status),  // uses Status.Validate()
}.Validate(ctx)

// OR — at least one must pass
validation.Any{
    validation.Name("email", validation.NotEmptyString(r.Email)),
    validation.Name("phone", validation.NotEmptyString(r.Phone)),
}.Validate(ctx)
```

## Key Rules

1. **Domain types implement `Validate(ctx) error`** — pass directly to `validation.Name()`
2. **`validation.Name("field", v)`** — wraps errors with field name
3. **`validation.All{}`** for required fields, **`validation.Any{}`** for at-least-one
4. **Custom logic** via `validation.HasValidationFunc(func(ctx) error { ... })`
5. **Error sentinel**: `errors.Wrapf(ctx, validation.Error, "msg")` for validation errors

## Struct Validate Pattern

```go
func (o Order) Validate(ctx context.Context) error {
    return validation.All{
        validation.Name("orderID", o.OrderID),       // domain type
        validation.Name("status", o.Status),          // enum with Validate()
        validation.Name("amount", validation.HasValidationFunc(func(ctx context.Context) error {
            if o.Amount <= 0 {
                return errors.Errorf(ctx, "amount must be positive")
            }
            return nil
        })),
    }.Validate(ctx)
}
```
