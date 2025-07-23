# Property-Based Tests for Topics Display

## Invariants (Properties that must always hold)

### 1. Format Invariants
- **P1**: Every topic name must match pattern `[a-z][a-z0-9-]*`
- **P2**: Every count must be a positive integer (1-999)
- **P3**: Topics must be separated by exactly " · " (space-middot-space)
- **P4**: Org format uses `^{count}` notation
- **P5**: HTML format uses `<sup>count</sup>` notation

### 2. Ordering Invariants
- **P6**: Topics must be ordered by count (descending)
- **P7**: Topics with equal counts maintain stable order
- **P8**: Maximum 20 topics displayed

### 3. Consistency Invariants
- **P9**: topics.org and README.md must have identical topic lists
- **P10**: Count values must match between formats
- **P11**: Topic order must match between formats

### 4. Transformation Invariants
- **P12**: org -> markdown conversion preserves all data
- **P13**: Regeneration produces identical output (idempotent)
- **P14**: No data loss during format conversion

## Property Test Implementations

### QuickCheck-style Properties (Pseudocode)
```haskell
prop_validTopicName :: Topic -> Bool
prop_validTopicName t = matches "[a-z][a-z0-9-]*" (topicName t)

prop_validCount :: Topic -> Bool
prop_validCount t = topicCount t >= 1 && topicCount t <= 999

prop_ordered :: [Topic] -> Bool
prop_ordered ts = all (\(a,b) -> count a >= count b) (zip ts (tail ts))

prop_roundTrip :: [Topic] -> Bool
prop_roundTrip ts = parseOrg (renderOrg ts) == ts 
                 && parseHtml (renderHtml ts) == ts
```

### Contract Assertions
```python
assert all(re.match(r'^[a-z][a-z0-9-]*$', t.name) for t in topics)
assert all(1 <= t.count <= 999 for t in topics)
assert all(topics[i].count >= topics[i+1].count for i in range(len(topics)-1))
assert len(topics) <= 20
```

## Test Generators

### Valid Input Generators
- Generate valid topic names: lowercase, alphanumeric with hyphens
- Generate valid counts: integers 1-999
- Generate ordered topic lists: sorted by count descending

### Edge Cases to Test
1. Single topic
2. Maximum topics (20)
3. Topics with same count
4. Topics with counts 1, 99, 999
5. Topic names with hyphens
6. Empty input handling

## Regression Tests
Document specific cases that broke in the past:
1. Loss of superscript counts after regeneration
2. Format inconsistency between org and markdown