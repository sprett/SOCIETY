import * as React from "react"
import { cn } from "@/lib/utils"

const Popover = ({
  open,
  onOpenChange,
  children,
  className,
}: {
  open: boolean
  onOpenChange: (open: boolean) => void
  children: React.ReactNode
  className?: string
}) => {
  const containerRef = React.useRef<HTMLDivElement>(null)
  React.useEffect(() => {
    if (!open) return
    const handleClick = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        onOpenChange(false)
      }
    }
    document.addEventListener("mousedown", handleClick)
    return () => document.removeEventListener("mousedown", handleClick)
  }, [open, onOpenChange])
  return <div ref={containerRef} className={cn("relative", className)}>{children}</div>
}

const PopoverTrigger = React.forwardRef<
  HTMLButtonElement,
  React.ButtonHTMLAttributes<HTMLButtonElement>
>(({ className, ...props }, ref) => (
  <button
    ref={ref}
    type="button"
    className={cn(className)}
    {...props}
  />
))

const PopoverContent = ({
  className,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) => (
  <div
    className={cn(
      "absolute left-0 top-full z-50 mt-2 rounded-xl border border-border/80 bg-card p-3 shadow-lg",
      className
    )}
    {...props}
  />
)

export { Popover, PopoverTrigger, PopoverContent }
