# Anti-Goodhart Pattern Catalog

## Pattern 1: Property Testing Over Value Testing

**Instead of:**
```python
def test_sort_specific():
    assert sort_list([3, 1, 2]) == [1, 2, 3]
```

**Use:**
```python
@pytest.mark.parametrize("input_list", [
    [3, 1, 2], [5, 5, 5], [], [1], [9, 8, 7, 6, 5, 4, 3, 2, 1]
])
def test_sort_is_ordered(input_list):
    result = sort_list(input_list)
    assert len(result) == len(input_list)
    assert all(result[i] <= result[i+1] for i in range(len(result)-1))
    assert sorted(input_list) == result
```

Agent cannot hardcode `[1, 2, 3]` when multiple inputs are tested. Must implement actual sorting.

## Pattern 2: Round-Trip Testing

For serialization, encoding, transformation:

```python
def test_encode_decode_roundtrip():
    original = {"key": "value", "nested": {"a": 1}}
    encoded = encode(original)
    decoded = decode(encoded)
    assert decoded == original
```

Agent must implement both directions correctly. Hardcoding either side breaks the round-trip.

## Pattern 3: Invariant Testing

For operations that preserve properties:

```python
def test_transfer_preserves_total():
    a, b = Account(100), Account(50)
    total_before = a.balance + b.balance
    transfer(a, b, 30)
    assert a.balance + b.balance == total_before
```

Tests a mathematical property. Cannot be faked without implementing actual logic.

## Pattern 4: Error Taxonomy Testing

Comprehensive error handling:

```python
@pytest.mark.parametrize("bad_input,error_type", [
    (None, TypeError),
    ("", ValueError),
    (-1, ValueError),
    (float('inf'), OverflowError),
])
def test_rejects_invalid_with_correct_error(bad_input, error_type):
    with pytest.raises(error_type):
        process(bad_input)
```

Each error type requires distinct validation logic. Agent cannot use a generic error.

## Pattern 5: Behavioral Snapshot Testing

Testing transformation between formats:

```python
def test_upgrade_migration():
    old_format = load_v1_data("fixtures/v1_sample.json")
    migrated = migrate_to_v2(old_format)
    assert "new_field" in migrated
    assert "deprecated_field" not in migrated
    assert migrated["version"] == 2
```

Agent must understand both formats.

## Pattern 6: Concurrency Safety Testing

Thread-safe operations:

```python
def test_concurrent_deposits():
    account = Account(0)
    threads = [Thread(target=account.deposit, args=(1,)) for _ in range(100)]
    for t in threads: t.start()
    for t in threads: t.join()
    assert account.balance == 100
```

Naive implementation fails intermittently. Forces proper synchronization.

## Pattern 7: Fixture-Based Contract Testing

Testing against a specification:

```python
@pytest.fixture
def valid_response():
    return create_handler().handle(valid_request())

def test_response_has_required_fields(valid_response):
    assert "id" in valid_response
    assert "timestamp" in valid_response
    assert "status" in valid_response

def test_response_id_is_uuid(valid_response):
    uuid.UUID(valid_response["id"])

def test_response_timestamp_is_iso(valid_response):
    datetime.fromisoformat(valid_response["timestamp"])
```

Tests the contract without specifying how the response is built.

## Anti-Pattern: Information-Leaking Test Names

**Bad (leak implementation):**
- `test_uses_redis_cache` -- tells agent to use Redis
- `test_sql_query_format` -- tells agent about SQL
- `test_calls_validate_before_save` -- prescribes call order

**Good (describe behavior):**
- `test_second_request_is_faster` -- tests caching effect
- `test_persists_across_restart` -- tests durability
- `test_rejects_invalid_before_side_effects` -- tests validation ordering by outcome
