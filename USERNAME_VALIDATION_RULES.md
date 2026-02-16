# Username Validation Rules

## Requirements

1. **Minimum Length**: 3 characters
2. **Case**: Lowercase only (automatically converted)
3. **Allowed Characters**: 
   - Lowercase letters: `a-z`
   - Numbers: `0-9`
   - Special characters: `_` (underscore), `-` (hyphen), `.` (period)
4. **Start/End**: Must begin and end with a letter or number (not special characters)
5. **Uniqueness**: Must be unique across all users

## Examples

### ✅ Valid Usernames
- `john`
- `john_doe`
- `john.smith`
- `john-123`
- `user123`
- `abc`
- `a.b.c`
- `test_user_2024`

### ❌ Invalid Usernames
- `Jo` (too short - min 3 chars)
- `John` (uppercase - auto-converted to `john`)
- `_john` (starts with special character)
- `john_` (ends with special character)
- `.john` (starts with period)
- `john.` (ends with period)
- `john doe` (contains space)
- `john@smith` (@ not allowed)
- `john#123` (# not allowed)

## Implementation

### Frontend Validation
- **File**: `SOCIETY/Core/Utils/UsernameValidator.swift`
- Real-time character filtering
- Automatic lowercase conversion
- Comprehensive validation with specific error messages

### Backend Validation
- **File**: `supabase_profile_extended_schema.sql`
- Database constraint: `profiles_username_valid`
- Regex pattern: `^[a-z0-9][a-z0-9._-]*[a-z0-9]$`
- Uniqueness constraint: `profiles_username_unique`

### User Experience
1. As users type, input is automatically converted to lowercase
2. Invalid characters are filtered out in real-time
3. Clear error messages guide users to fix issues
4. Validation occurs before submission to prevent server errors

## Migration

To apply these rules to existing usernames, run:
```bash
# Located at: username_validation_migration.sql
```

This script will:
1. Convert all usernames to lowercase
2. Remove invalid characters
3. Ensure minimum length
4. Fix usernames that start/end with special characters
5. Apply database constraints

## Regex Pattern Explanation

```regex
^[a-z0-9][a-z0-9._-]*[a-z0-9]$
```

- `^` - Start of string
- `[a-z0-9]` - First character must be lowercase letter or number
- `[a-z0-9._-]*` - Middle characters (zero or more) can be letter, number, or special char
- `[a-z0-9]` - Last character must be lowercase letter or number
- `$` - End of string

Combined with `length(trim(username)) >= 3` ensures minimum 3 characters.
