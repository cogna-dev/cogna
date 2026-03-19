import { cn } from "@/lib/utils"

export interface ContainerProps {
  children: React.ReactNode
  className?: string
  variant?: "default" | "wide" | "narrow"
}

const variantStyles = {
  default: "max-w-full lg:max-w-5xl xl:max-w-7xl",
  wide: "max-w-full xl:max-w-9xl",
  narrow: "max-w-full lg:max-w-4xl",
}

export function Container({
  children,
  className,
  variant = "default",
}: ContainerProps) {
  return (
    <div
      className={cn("mx-auto px-6 md:px-8", variantStyles[variant], className)}
    >
      {children}
    </div>
  )
}
