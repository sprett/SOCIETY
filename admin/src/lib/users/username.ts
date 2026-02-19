const USERNAME_REGEX = /^[a-z0-9][a-z0-9._-]*[a-z0-9]$/

export function normalizeUsername(value: string | null | undefined): string {
  return (value ?? "").trim().toLowerCase()
}

export function isValidUsername(value: string | null | undefined): boolean {
  const username = normalizeUsername(value)
  return username.length >= 3 && USERNAME_REGEX.test(username)
}
