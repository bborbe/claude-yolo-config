# GoDoc Comments

Standard Go documentation comment conventions.

## Core Rules

1. **Start with name**: `// Add adds two integers and returns the result.`
2. **Complete sentences**: Full sentence, period at end
3. **Third person**: "Returns" not "Return", "Creates" not "Create"
4. **Behavior, not implementation**: What it does, not how
5. **No signature duplication**: Don't repeat params/returns from the signature

## Per Construct

### Package
```go
// Package calculator provides basic mathematical operations.
package calculator
```
Put in `doc.go` file.

### Function/Method
```go
// Multiply returns the product of two integers.
func Multiply(a, b int) int

// Merge combines two sorted slices into a single sorted slice.
// It assumes both inputs are sorted in ascending order.
func Merge(a, b []int) []int
```

### Struct/Interface
```go
// User represents a user in the system.
type User struct {
    ID    int
    Email string
}
```

### Constants
```go
// MaxRetries defines the maximum number of retry attempts.
const MaxRetries = 3
```

## Rules

1. All **exported** items must have doc comments
2. Package comment in `doc.go`
3. Mention purpose, inputs/outputs (brief), side effects
4. Don't document unexported items unless complex

## Checklist

- [ ] Every exported type, func, method, const has doc comment
- [ ] Comments start with the item name
- [ ] Full sentences with periods
- [ ] Package comment exists in doc.go
