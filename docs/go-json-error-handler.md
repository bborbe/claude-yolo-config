# JSON Error Handler

Structured JSON error responses using `github.com/bborbe/http`.

## Response Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "columnGroup is required",
    "details": {"field": "columnGroup", "expected": "day|week|month|year"}
  }
}
```

## Error Codes

| Code | Status | Constant |
|------|--------|----------|
| `VALIDATION_ERROR` | 400 | `libhttp.ErrorCodeValidation` |
| `NOT_FOUND` | 404 | `libhttp.ErrorCodeNotFound` |
| `UNAUTHORIZED` | 401 | `libhttp.ErrorCodeUnauthorized` |
| `FORBIDDEN` | 403 | `libhttp.ErrorCodeForbidden` |
| `INTERNAL_ERROR` | 500 | `libhttp.ErrorCodeInternal` |

## Usage

```go
// Status only
return libhttp.WrapWithStatusCode(errors.New(ctx, "not found"), http.StatusNotFound)

// Code + status
return libhttp.WrapWithCode(errors.New(ctx, "required"), libhttp.ErrorCodeValidation, http.StatusBadRequest)

// Code + status + details
return libhttp.WrapWithDetails(
    errors.New(ctx, "invalid format"),
    libhttp.ErrorCodeValidation,
    http.StatusBadRequest,
    map[string]string{"field": "from", "expected": "YYYY-MM-DD"},
)

// Unexpected errors — just return, handler defaults to 500 INTERNAL_ERROR
return errors.Wrap(ctx, err, "external call failed")
```

## Handler Wrappers

```go
// Basic JSON error handler
handler := libhttp.NewJSONErrorHandler(myHandler)

// With update transaction (read-write)
handler := libhttp.NewJSONUpdateErrorHandlerTx(db, myHandler)

// With view transaction (read-only)
handler := libhttp.NewJSONViewErrorHandlerTx(db, myHandler)
```

## Factory Integration

```go
// pkg/factory/factory.go
func CreateSearchHandler(store SearchStore) http.Handler {
    return libhttp.NewJSONErrorHandler(handler.NewSearchHandler(store))
}
```

## Rules

1. **Default choice**: `NewJSONErrorHandler` for all new handlers
2. Match error code to HTTP status (NOT_FOUND → 404, not VALIDATION_ERROR → 404)
3. Never expose internal details (SQL queries, connection strings)
4. Use specific messages, not generic "error"
5. Details map keys: `field`, `reason`, `received`, `expected`, `resource`, `id`

## Checklist

- [ ] Using `NewJSONErrorHandler` (not `NewErrorHandler`) for APIs
- [ ] Error codes match HTTP status codes
- [ ] No internal details exposed
- [ ] Specific, actionable error messages
