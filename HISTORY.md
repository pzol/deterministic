## v0.13.0

- Add `Option#value_to_a`
- Add `Option#+`
- Make `None` a real monad (little impact on the real world)
- Add `Either`
- Add `Option#value_or`
- `None#value` is now private

## v0.12.1

- Fix backwards compatibility with Ruby < 2.0.0

## v0.12.0

- Add Option
- Nest `Success` and `Failure` under `Result`

## v0.10.0
** breaking changes **

- Remove `Either#<<`
- Rename `Either` to `Result`
- Add `Result#pipe` aka `Result#**`
- Add `Result#map` and `Result#map_err`

## v0.9.0
** breaking changes **

- Remove `Either.attempt_all` in favor of `Either#>>` and `Either#>=`
  This greatly reduces the complexity and the code necessary.

## 0.8.0 - v0.8.1

- Introduce `Either#>>` and `Either#>=`
