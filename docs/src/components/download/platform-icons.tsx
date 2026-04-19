import {
  Apple,
  Container,
  AppWindow,
  Terminal,
  Package,
  Home,
  Code2,
  Moon,
  FileJson,
} from "lucide-react"

// VSCode icon as a custom SVG component
export function VSCodeIcon({ className = "h-6 w-6" }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      className={className}
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M17.583 1.608L10.38 8.811l-5.67-4.29L2.37 6.88v10.24l2.34 1.36 5.67-4.29 7.203 7.203L21.63 19.44V4.56l-4.047-2.952zM4.71 15.84V8.16l4.29 3.84-4.29 3.84zm12.87 0l-4.29-3.84 4.29-3.84v7.68z"
        fill="currentColor"
      />
    </svg>
  )
}

// MoonBit icon - custom SVG
export function MoonBitIcon({ className = "h-6 w-6" }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      className={className}
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="2" fill="none" />
      <path
        d="M12 2a10 10 0 0 1 0 20 10 10 0 0 1 0-20"
        fill="currentColor"
        opacity="0.3"
      />
    </svg>
  )
}

// pnpm icon - custom SVG
export function PnpmIcon({ className = "h-6 w-6" }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      className={className}
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path d="M4 4h4v4H4V4zm6 0h4v4h-4V4zm6 0h4v4h-4V4zM4 10h4v4H4v-4zm6 0h4v4h-4v-4zm6 0h4v4h-4v-4zM4 16h4v4H4v-4zm6 0h4v4h-4v-4zm6 0h4v4h-4v-4z" fill="currentColor"/>
    </svg>
  )
}

// Bun icon - custom SVG
export function BunIcon({ className = "h-6 w-6" }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      className={className}
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8z"
        fill="currentColor"
      />
      <path d="M12 6c-3.31 0-6 2.69-6 6s2.69 6 6 6 6-2.69 6-6-2.69-6-6-6z" fill="currentColor" opacity="0.5"/>
    </svg>
  )
}

// Yarn icon - custom SVG
export function YarnIcon({ className = "h-6 w-6" }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      className={className}
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z"
        fill="currentColor"
      />
    </svg>
  )
}

// npm icon - custom SVG
export function NpmIcon({ className = "h-6 w-6" }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      className={className}
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M20 4H4v16h8V8h4v12h4V4z"
        fill="currentColor"
      />
    </svg>
  )
}

// Node.js icon - custom SVG
export function NodeJsIcon({ className = "h-6 w-6" }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      className={className}
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="M12 2L3 7v10l9 5 9-5V7l-9-5zm0 2.8L18.2 8 12 11.2 5.8 8 12 4.8zM5 9.5l6 3.4v6.8l-6-3.3V9.5zm8 10.2v-6.8l6-3.4v6.7l-6 3.5z"
        fill="currentColor"
      />
    </svg>
  )
}

// Apple icon (from lucide, but exported here for consistency)
export { Apple, Container, AppWindow, Terminal, Package, Home, Code2, Moon, FileJson }

// Platform icons mapping for easy access
export const platformIcons = {
  apple: Apple,
  linux: Container,
  windows: AppWindow,
  terminal: Terminal,
  package: Package,
  home: Home,
  code: Code2,
  moon: Moon,
  fileJson: FileJson,
  vscode: VSCodeIcon,
  moonbit: MoonBitIcon,
  pnpm: PnpmIcon,
  bun: BunIcon,
  yarn: YarnIcon,
  npm: NpmIcon,
  nodejs: NodeJsIcon,
}
