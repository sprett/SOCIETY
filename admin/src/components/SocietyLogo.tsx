import { cn } from "@/lib/utils"

interface SocietyLogoProps {
  className?: string
  /** Width and height in pixels; default 32 */
  size?: number
}

/**
 * SOCIETY logo: Tabler Circles icon. Black in light mode, white in dark mode.
 */
export function SocietyLogo({ className, size = 32 }: SocietyLogoProps) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 24 24"
      width={size}
      height={size}
      fill="currentColor"
      className={cn("text-black dark:text-white", className)}
      aria-hidden
    >
      <path stroke="none" d="M0 0h24v24H0z" fill="none" />
      <path d="M6.5 12a5 5 0 1 1 -4.995 5.217l-.005 -.217l.005 -.217a5 5 0 0 1 4.995 -4.783z" />
      <path d="M17.5 12a5 5 0 1 1 -4.995 5.217l-.005 -.217l.005 -.217a5 5 0 0 1 4.995 -4.783z" />
      <path d="M12 2a5 5 0 1 1 -4.995 5.217l-.005 -.217l.005 -.217a5 5 0 0 1 4.995 -4.783z" />
    </svg>
  )
}
