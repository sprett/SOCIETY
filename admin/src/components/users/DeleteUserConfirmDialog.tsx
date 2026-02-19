import { useEffect, useMemo, useState } from "react"
import { AlertTriangle } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { adminDeleteUser } from "@/lib/users/api"
import { useToast } from "@/contexts/ToastContext"
import type { AdminUserRow } from "@/lib/users/types"

interface DeleteUserConfirmDialogProps {
  open: boolean
  user: AdminUserRow | null
  onOpenChange: (open: boolean) => void
  onDeleted: () => Promise<void> | void
}

export function DeleteUserConfirmDialog({
  open,
  user,
  onOpenChange,
  onDeleted,
}: DeleteUserConfirmDialogProps) {
  const { success } = useToast()
  const [confirmInput, setConfirmInput] = useState("")
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!open) {
      setConfirmInput("")
      setLoading(false)
      setError(null)
    }
  }, [open])

  const username = user?.username ?? ""
  const canDelete = useMemo(
    () => !!user && username.length > 0 && confirmInput === username && !loading,
    [confirmInput, loading, user, username]
  )

  function formatDeleteError(message: string): string {
    switch (message) {
      case "missing_username":
        return "This user can’t be deleted until they have a valid username."
      case "username_mismatch":
        return "Username mismatch. Refresh and try again."
      case "forbidden":
        return "You don’t have permission to delete users."
      case "unauthorized":
        return "Your session expired. Please sign in again."
      case "target_not_found":
        return "User not found."
      default:
        return message || "Failed to delete user"
    }
  }

  async function handleDelete() {
    if (!user || !canDelete) return
    setLoading(true)
    setError(null)
    try {
      const result = await adminDeleteUser(user.id, username)
      if (!result.success) {
        throw new Error(result.error ?? "Delete failed")
      }
      success(
        <span>
          Successfully deleted <span className="font-semibold">{username}</span>.
        </span>
      )
      await onDeleted()
      onOpenChange(false)
    } catch (e) {
      const msg = e instanceof Error ? e.message : "Failed to delete user"
      setError(formatDeleteError(msg))
      setLoading(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent
        className="max-w-md rounded-xl border border-border/80 bg-card p-4 data-[state=open]:animate-none data-[state=closed]:animate-none data-[state=open]:zoom-in-100 data-[state=closed]:zoom-out-100"
        showCloseButton={false}
      >
        <DialogHeader className="space-y-4">
          <div className="inline-flex h-10 w-10 items-center justify-center rounded-full bg-destructive/10">
            <AlertTriangle className="h-4 w-4 text-destructive" />
          </div>
          <DialogTitle className="text-xl leading-tight tracking-tight">Delete User Permanently</DialogTitle>
          <p className="max-w-md text-sm leading-snug text-muted-foreground">
            This is a permanent action. All user account data will be deleted and cannot be recovered.
          </p>
        </DialogHeader>

        <div className="rounded-lg border border-border p-3">
          <p className="text-xs font-medium">
            Type <span className="font-semibold">{username || "(missing username)"}</span> to confirm deletion.
          </p>
          <Input
            value={confirmInput}
            onChange={(e) => setConfirmInput(e.target.value)}
            placeholder="Enter username"
            className="mt-2 h-9 text-xs"
            disabled={!user || !username}
          />
          {!username && (
            <p className="mt-2 text-sm text-destructive">
              This user cannot be deleted until they have a valid username.
            </p>
          )}
        </div>

        {error && (
          <p className="text-sm text-destructive" role="alert">
            {error}
          </p>
        )}

        <DialogFooter className="mt-1 flex-row justify-end gap-2">
          <Button type="button" variant="outline" className="h-8 px-4 text-sm" onClick={() => onOpenChange(false)} disabled={loading}>
            Cancel
          </Button>
          <Button
            type="button"
            variant="destructive"
            className="h-8 px-4 text-sm"
            onClick={handleDelete}
            disabled={!canDelete}
          >
            {loading ? "Deleting..." : "Delete Account"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
