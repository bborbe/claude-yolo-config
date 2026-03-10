# Filter Pattern

Functional filters with preprocessing and no-op optimization.

## Core Pattern

```go
// Interface: true = exclude, false = include
type ItemFilter interface {
    Filtered(ctx context.Context, tx Tx, item Item) (bool, error)
}

// Constructor with no-op early return
func NewItemFilter(allowedTypes []Type) ItemFilter {
    if len(allowedTypes) == 0 {
        return ItemFilterNone() // checked ONCE
    }
    allowedTypeSet := collection.NewSet[Type](allowedTypes...) // converted ONCE
    return ItemFilterFunc(func(ctx context.Context, tx Tx, item Item) (bool, error) {
        return !allowedTypeSet.Contains(item.Type), nil // O(1) per call
    })
}

func ItemFilterNone() ItemFilter {
    return ItemFilterFunc(func(ctx context.Context, tx Tx, item Item) (bool, error) {
        return false, nil
    })
}
```

## Rules

1. **Document semantics**: `true` = filter out (exclude), `false` = pass through (include)
2. **No-op for empty input**: Return `FilterNone()` when no filter criteria — check once at creation, not every call
3. **Preprocess outside closure**: Convert slices to sets before returning the closure, not inside it
4. **Use `collection.Set`** for O(1) contains, not slice linear search
5. **Naming alignment**: Parameter name must match behavior — `allowedTypes` not `excludedTypes` if filter includes

## Bad

```go
// Empty check on EVERY call
func (f *filter) Filtered(ctx, tx, item) (bool, error) {
    if f.allowedTypes.Length() == 0 { return false, nil }
    ...
}

// Set conversion on EVERY call
return FilterFunc(func(...) (bool, error) {
    set := collection.NewSet(allowedTypes...) // O(n) per call!
    return !set.Contains(item.Type), nil
})

// Inverted semantics
func CreateFilters(excludedTypes []Type) { // name says "exclude"
    NewIncludeTypeFilter(excludedTypes)     // but filter includes!
}
```

## Checklist

- [ ] Interface semantics documented (true = exclude)
- [ ] Empty input → no-op filter (checked once)
- [ ] Preprocessing done outside closure
- [ ] Set-based O(1) lookups
- [ ] Parameter names match filter behavior
