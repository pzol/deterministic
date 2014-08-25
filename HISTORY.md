## v0.10.0
** breaking changes **

- Remove `Either#<<`
- Rename `Either` to `Result`

## v0.9.0
** breaking changes **

- Remove `Either.attempt_all` in favor of `Either#>>` and `Either#>=`
  This greatly reduces the complexity and the code necessary.

## 0.8.0 - v0.8.1

- Introduce `Either#>>` and `Either#>=`
