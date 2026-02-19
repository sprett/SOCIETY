import { useEffect, useMemo, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Dialog, DialogContent, DialogFooter } from "@/components/ui/dialog";
import { adminUpdateUserProfile, getAdminUserProfile } from "@/lib/users/api";
import type { AdminUserRow } from "@/lib/users/types";
import { isValidUsername, normalizeUsername } from "@/lib/users/username";
import { BirthdayPicker } from "@/components/users/BirthdayPicker";
import type { CountryPhoneCode } from "@/lib/phone/countryPhoneCodes";
import {
  DEFAULT_COUNTRY_PHONE_CODE,
  COUNTRY_PHONE_CODES,
} from "@/lib/phone/countryPhoneCodes";
import { CountryCodeSelect } from "@/components/users/CountryCodeSelect";
import { Camera } from "lucide-react";

interface EditUserModalProps {
  open: boolean;
  user: AdminUserRow | null;
  onOpenChange: (open: boolean) => void;
  onSaved: () => Promise<void> | void;
}

function splitFullName(full: string | null | undefined): {
  firstName: string;
  lastName: string;
} {
  const s = (full ?? "").trim();
  if (!s) return { firstName: "", lastName: "" };
  const i = s.indexOf(" ");
  if (i < 0) return { firstName: s, lastName: "" };
  return { firstName: s.slice(0, i).trim(), lastName: s.slice(i).trim() };
}

function joinFullName(first: string, last: string): string {
  return [first.trim(), last.trim()].filter(Boolean).join(" ").trim();
}

interface FormState {
  firstName: string;
  lastName: string;
  username: string;
  email: string;
  phoneCountry: CountryPhoneCode;
  phoneNational: string;
  birthday: string;
  avatarUrl: string;
  instagramHandle: string;
  twitterHandle: string;
  youtubeHandle: string;
  tiktokHandle: string;
  linkedinHandle: string;
  websiteUrl: string;
}

function emptyForm(): FormState {
  return {
    firstName: "",
    lastName: "",
    username: "",
    email: "",
    phoneCountry: DEFAULT_COUNTRY_PHONE_CODE,
    phoneNational: "",
    birthday: "",
    avatarUrl: "",
    instagramHandle: "",
    twitterHandle: "",
    youtubeHandle: "",
    tiktokHandle: "",
    linkedinHandle: "",
    websiteUrl: "",
  };
}

function normalizeDialing(s: string): string {
  return s.replace(/\s+/g, "").trim();
}

function parsePhoneNumber(raw: string | null | undefined): {
  country: CountryPhoneCode;
  national: string;
} {
  const value = (raw ?? "").trim();
  if (!value) return { country: DEFAULT_COUNTRY_PHONE_CODE, national: "" };

  const compact = normalizeDialing(value);
  if (compact.startsWith("+")) {
    // Longest-prefix match on dialing codes (e.g. +1684 before +1)
    const candidates = COUNTRY_PHONE_CODES.filter((c) =>
      compact.startsWith(c.dialingCode),
    ).sort((a, b) => b.dialingCode.length - a.dialingCode.length);
    const match = candidates[0];
    if (!match) return { country: DEFAULT_COUNTRY_PHONE_CODE, national: value };
    const national = value
      .replace(new RegExp("^" + match.dialingCode.replace("+", "\\\\+")), "")
      .trim();
    return { country: match, national };
  }

  // Value has no "+": try matching leading digits as country code (e.g. "47" -> Norway, national "")
  const digitsOnly = value.replace(/\D/g, "");
  const candidates = COUNTRY_PHONE_CODES.filter((c) => {
    const codeDigits = c.dialingCode.replace("+", "");
    return digitsOnly === codeDigits || digitsOnly.startsWith(codeDigits);
  }).sort((a, b) => b.dialingCode.length - a.dialingCode.length);
  const match = candidates[0];
  if (!match) return { country: DEFAULT_COUNTRY_PHONE_CODE, national: value };
  const codeDigits = match.dialingCode.replace("+", "");
  const national = digitsOnly.startsWith(codeDigits)
    ? digitsOnly.slice(codeDigits.length)
    : digitsOnly;
  return { country: match, national };
}

export function EditUserModal({
  open,
  user,
  onOpenChange,
  onSaved,
}: EditUserModalProps) {
  const [form, setForm] = useState<FormState>(emptyForm);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open || !user) return;
    let active = true;
    const { firstName, lastName } = splitFullName(user.full_name);
    setForm({
      firstName,
      lastName,
      username: user.username ?? "",
      email: user.email ?? "",
      ...(() => {
        const parsed = parsePhoneNumber(user.phone_number);
        return { phoneCountry: parsed.country, phoneNational: parsed.national };
      })(),
      birthday: user.birthday ?? "",
      avatarUrl: user.avatar_url ?? "",
      instagramHandle: "",
      twitterHandle: "",
      youtubeHandle: "",
      tiktokHandle: "",
      linkedinHandle: "",
      websiteUrl: "",
    });
    setError(null);
    if (!user.username)
      return () => {
        active = false;
      };
    getAdminUserProfile(user.username, "90")
      .then((payload) => {
        if (!active || !payload) return;
        const profileFull = splitFullName(payload.profile.full_name ?? null);
        setForm((current) => ({
          ...current,
          firstName: profileFull.firstName,
          lastName: profileFull.lastName,
          ...(() => {
            const parsed = parsePhoneNumber(
              payload.profile.phone_number ?? null,
            );
            return {
              phoneCountry: parsed.country,
              phoneNational: parsed.national,
            };
          })(),
          birthday: payload.profile.birthday ?? "",
          avatarUrl: payload.profile.avatar_url ?? "",
          instagramHandle: payload.profile.instagram_handle ?? "",
          twitterHandle: payload.profile.twitter_handle ?? "",
          youtubeHandle: payload.profile.youtube_handle ?? "",
          tiktokHandle: payload.profile.tiktok_handle ?? "",
          linkedinHandle: payload.profile.linkedin_handle ?? "",
          websiteUrl: payload.profile.website_url ?? "",
        }));
      })
      .catch(() => {
        // Keep basic row data fallback if detail call fails.
      });
    return () => {
      active = false;
    };
  }, [open, user]);

  const normalizedUsername = useMemo(
    () => normalizeUsername(form.username),
    [form.username],
  );
  const hasUsername = normalizedUsername.length > 0;
  const usernameValid = !hasUsername || isValidUsername(normalizedUsername);

  const canSave = !!user && !saving && usernameValid;

  async function handleSave() {
    if (!user || !canSave) return;
    setSaving(true);
    setError(null);
    try {
      await adminUpdateUserProfile({
        user_id: user.id,
        full_name: joinFullName(form.firstName, form.lastName) || null,
        username: normalizedUsername || null,
        phone_number: (() => {
          const national = form.phoneNational.trim();
          if (!national) return null;
          return `${form.phoneCountry.dialingCode} ${national}`.trim();
        })(),
        birthday: form.birthday || null,
        avatar_url: form.avatarUrl.trim() || null,
        instagram_handle: form.instagramHandle.trim() || null,
        twitter_handle: form.twitterHandle.trim() || null,
        youtube_handle: form.youtubeHandle.trim() || null,
        tiktok_handle: form.tiktokHandle.trim() || null,
        linkedin_handle: form.linkedinHandle.trim() || null,
        website_url: form.websiteUrl.trim() || null,
      });
      await onSaved();
      onOpenChange(false);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to save user profile");
    } finally {
      setSaving(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
        {/* Basic Information */}
        <div className="space-y-4">
          <div>
            <h3 className="text-sm font-semibold">Basic Information</h3>
            <p className="text-sm text-muted-foreground">
              Public profile information.
            </p>
          </div>

          <div className="flex flex-col gap-6 sm:flex-row sm:items-start">
            {/* Profile photo block */}
            <div className="flex shrink-0 flex-col items-center gap-2 sm:items-start">
              <div className="relative">
                <div className="flex h-24 w-24 items-center justify-center overflow-hidden rounded-full border border-input bg-muted">
                  {form.avatarUrl ? (
                    <img
                      src={form.avatarUrl}
                      alt=""
                      className="h-full w-full object-cover"
                      onError={(e) => {
                        (e.target as HTMLImageElement).style.display = "none";
                      }}
                    />
                  ) : (
                    <span className="text-3xl text-muted-foreground">?</span>
                  )}
                </div>
                <span className="absolute bottom-0 right-0 flex h-7 w-7 items-center justify-center rounded-full border border-background bg-muted-foreground/80 text-background">
                  <Camera className="h-3.5 w-3.5" />
                </span>
              </div>
              <div className="text-center sm:text-left">
                <p className="text-sm font-medium">Profile Photo</p>
                <p className="text-xs text-muted-foreground">
                  URL to image. JPG, PNG or GIF.
                </p>
              </div>
              <Input
                value={form.avatarUrl}
                onChange={(e) =>
                  setForm((s) => ({ ...s, avatarUrl: e.target.value }))
                }
                placeholder="https://..."
                className="h-9 w-full sm:w-56"
              />
              <Button
                type="button"
                variant="ghost"
                size="sm"
                className="h-8 text-muted-foreground"
                onClick={() => setForm((s) => ({ ...s, avatarUrl: "" }))}
              >
                Remove
              </Button>
            </div>

            {/* First name, Last name, Username, Birthday, Email, Phone */}
            <div className="grid flex-1 gap-4 sm:grid-cols-2">
              <div className="space-y-1.5 sm:col-span-2">
                <label className="text-sm font-medium">First name</label>
                <Input
                  value={form.firstName}
                  onChange={(e) =>
                    setForm((s) => ({ ...s, firstName: e.target.value }))
                  }
                  placeholder="First name"
                />
              </div>
              <div className="space-y-1.5 sm:col-span-2">
                <label className="text-sm font-medium">Last name</label>
                <Input
                  value={form.lastName}
                  onChange={(e) =>
                    setForm((s) => ({ ...s, lastName: e.target.value }))
                  }
                  placeholder="Last name"
                />
              </div>
              <div className="space-y-1.5 max-w-[11rem]">
                <label className="text-sm font-medium">Username</label>
                <Input
                  value={form.username}
                  onChange={(e) =>
                    setForm((s) => ({ ...s, username: e.target.value }))
                  }
                  placeholder="username"
                />
                {!usernameValid && (
                  <p className="text-xs text-destructive">
                    Username must be at least 3 chars, lowercase, and may use .
                    _ -
                  </p>
                )}
              </div>
              <div className="space-y-1.5 min-w-0">
                <label className="text-sm font-medium">Birthday</label>
                <BirthdayPicker
                  value={form.birthday}
                  onChange={(value) =>
                    setForm((s) => ({ ...s, birthday: value }))
                  }
                  showClearButton={false}
                />
              </div>
              <div className="space-y-1.5 sm:col-span-2">
                <label className="text-sm font-medium">Email (read-only)</label>
                <Input
                  value={form.email}
                  readOnly
                  disabled
                  className="bg-muted/50"
                />
              </div>
              <div className="space-y-1.5 sm:col-span-2">
                <label className="text-sm font-medium">Phone</label>
                <div className="flex min-w-0 items-center gap-2">
                  <div className="shrink-0">
                    <CountryCodeSelect
                      value={form.phoneCountry}
                      onChange={(country) =>
                        setForm((s) => ({ ...s, phoneCountry: country }))
                      }
                      className="w-[7.5rem]"
                      compact
                    />
                  </div>
                  <div className="min-w-0 flex-1">
                    <Input
                      value={form.phoneNational}
                      onChange={(e) => {
                        const next = e.target.value;
                        if (next.trim().startsWith("+")) {
                          const parsed = parsePhoneNumber(next);
                          setForm((s) => ({
                            ...s,
                            phoneCountry: parsed.country,
                            phoneNational: parsed.national,
                          }));
                          return;
                        }
                        setForm((s) => ({
                          ...s,
                          phoneNational: next.replace(/^\+/, ""),
                        }));
                      }}
                      placeholder="Phone number"
                      className="min-w-0"
                    />
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Links */}
        <div className="space-y-4 border-t pt-6">
          <div>
            <h3 className="text-sm font-semibold">Links</h3>
            <p className="text-sm text-muted-foreground">
              Website and social links.
            </p>
          </div>
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-1.5 sm:col-span-2">
              <label className="text-sm font-medium">Website</label>
              <Input
                value={form.websiteUrl}
                onChange={(e) =>
                  setForm((s) => ({ ...s, websiteUrl: e.target.value }))
                }
                placeholder="https://example.com"
              />
            </div>
            <div className="space-y-1.5">
              <label className="text-sm font-medium">Instagram</label>
              <Input
                value={form.instagramHandle}
                onChange={(e) =>
                  setForm((s) => ({ ...s, instagramHandle: e.target.value }))
                }
                placeholder="handle"
              />
            </div>
            <div className="space-y-1.5">
              <label className="text-sm font-medium">Twitter / X</label>
              <Input
                value={form.twitterHandle}
                onChange={(e) =>
                  setForm((s) => ({ ...s, twitterHandle: e.target.value }))
                }
                placeholder="handle"
              />
            </div>
            <div className="space-y-1.5">
              <label className="text-sm font-medium">YouTube</label>
              <Input
                value={form.youtubeHandle}
                onChange={(e) =>
                  setForm((s) => ({ ...s, youtubeHandle: e.target.value }))
                }
                placeholder="channel"
              />
            </div>
            <div className="space-y-1.5">
              <label className="text-sm font-medium">TikTok</label>
              <Input
                value={form.tiktokHandle}
                onChange={(e) =>
                  setForm((s) => ({ ...s, tiktokHandle: e.target.value }))
                }
                placeholder="handle"
              />
            </div>
            <div className="space-y-1.5">
              <label className="text-sm font-medium">LinkedIn</label>
              <Input
                value={form.linkedinHandle}
                onChange={(e) =>
                  setForm((s) => ({ ...s, linkedinHandle: e.target.value }))
                }
                placeholder="profile"
              />
            </div>
          </div>
        </div>

        {error && (
          <p className="text-sm text-destructive" role="alert">
            {error}
          </p>
        )}

        <DialogFooter className="gap-2 sm:gap-4">
          <Button
            type="button"
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={saving}
          >
            Cancel
          </Button>
          <Button type="button" onClick={handleSave} disabled={!canSave}>
            {saving ? "Saving..." : "Save changes"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
