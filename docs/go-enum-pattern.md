# Go Enum Type Pattern

String-based enums with validation. Used 50+ times across projects.

## Complete Pattern

```go
// 1. Constants with explicit type
const (
    PendingStatus  Status = "pending"
    ActiveStatus   Status = "active"
    ClosedStatus   Status = "closed"
)

// 2. Available* collection (ALL valid values)
var AvailableStatuses = Statuses{PendingStatus, ActiveStatus, ClosedStatus}

// 3. Singular type
type Status string

func (s Status) String() string { return string(s) }

func (s Status) Validate(ctx context.Context) error {
    if !AvailableStatuses.Contains(s) {
        return errors.Wrapf(ctx, validation.Error, "unknown status '%s'", s)
    }
    return nil
}

func (s Status) Ptr() *Status { return &s }

// 4. Plural collection type
type Statuses []Status

func (s Statuses) Contains(status Status) bool {
    return collection.Contains(s, status)  // github.com/bborbe/collection
}
```

## Checklist

- Constants with explicit type annotation
- `var Available*` collection with ALL valid values
- `String()` method
- `Validate(ctx)` checking against `Available*`
- `Ptr()` method returning pointer
- Plural collection type with `Contains()`
- Uses `github.com/bborbe/collection` for Contains
- Uses `github.com/bborbe/validation` for error sentinel
