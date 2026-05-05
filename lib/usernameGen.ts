// Port of ProfileSetupViewModel.generateUsername — keep behavior identical:
// lowercase the full name, strip non-alphanumeric, pad to >= 3 chars with
// random digits, fall back to user### if nothing usable remains.
export function generateUsername(fullName: string): string {
  const cleaned = fullName
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "")
    .replace(/[^a-z0-9]/g, "");

  if (cleaned.length === 0) {
    return `user${Math.floor(Math.random() * 900) + 100}`;
  }
  if (cleaned.length < 3) {
    const suffix = Math.floor(Math.random() * 90) + 10;
    return `${cleaned}${suffix}`;
  }
  return cleaned;
}
