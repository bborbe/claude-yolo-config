# Go Enum Type Pattern

String-based enums with validation. Used 50+ times across projects.

## Naming Convention

Constants follow `<Value><Type>` pattern. The type name is always suffixed:

- Type: `OrderStatus` (not `Status` — avoids collisions when package has multiple enum types)
- Constants: `PendingOrderStatus`, `ActiveOrderStatus` (not `StatusPending`, not `PendingStatus`)
- Collection: `AvailableOrderStatuses`, `OrderStatuses`

## Complete Pattern

```go
// 1. Constants with explicit type — <Value><Type> naming
const (
    PendingOrderStatus    OrderStatus = "pending"
    ProcessingOrderStatus OrderStatus = "processing"
    CompletedOrderStatus  OrderStatus = "completed"
    FailedOrderStatus     OrderStatus = "failed"
)

// 2. Available* collection (ALL valid values)
var AvailableOrderStatuses = OrderStatuses{
    PendingOrderStatus,
    ProcessingOrderStatus,
    CompletedOrderStatus,
    FailedOrderStatus,
}

// 3. Singular type
type OrderStatus string

func (o OrderStatus) String() string { return string(o) }

func (o OrderStatus) Validate(ctx context.Context) error {
    if !AvailableOrderStatuses.Contains(o) {
        return errors.Wrapf(ctx, validation.Error, "unknown order status '%s'", o)
    }
    return nil
}

func (o OrderStatus) Ptr() *OrderStatus { return &o }

// 4. Plural collection type
type OrderStatuses []OrderStatus

func (o OrderStatuses) Contains(status OrderStatus) bool {
    return collection.Contains(o, status)  // github.com/bborbe/collection
}
```

## Checklist

- Type name is specific (e.g. `OrderStatus`, not `Status`)
- Constants follow `<Value><Type>` naming (e.g. `PendingOrderStatus`)
- `var Available<Type>s` collection with ALL valid values
- `String()` method
- `Validate(ctx)` checking against `Available*`
- `Ptr()` method returning pointer
- Plural collection type with `Contains()`
- Uses `github.com/bborbe/collection` for Contains
- Uses `github.com/bborbe/validation` for error sentinel
