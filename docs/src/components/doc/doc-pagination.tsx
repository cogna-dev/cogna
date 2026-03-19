import { ChevronLeftIcon, ChevronRightIcon } from "lucide-react";
import type { DocsSidebarGroup } from "@/components/doc/doc-sidebar";
import { cn } from "@/lib/utils";

interface DocPaginationProps {
	currentPath: string;
	config: DocsSidebarGroup[];
}

export function DocPagination({ currentPath, config }: DocPaginationProps) {
	const flattenedItems = config.flatMap((group) => group.items);

	// Find index ignoring trailing slashes
	const normalizedPath = currentPath.replace(/\/$/, "");
	const currentIndex = flattenedItems.findIndex(
		(item) => item.href.replace(/\/$/, "") === normalizedPath,
	);

	const prev = flattenedItems[currentIndex - 1];
	const next = flattenedItems[currentIndex + 1];

	if (currentIndex === -1 || (!prev && !next)) return null;

	return (
		<div className="flex flex-col sm:flex-row justify-between gap-4 border-t pt-6 mt-12">
			{prev ? (
				<a
					href={prev.href}
					className={cn(
						"flex flex-col gap-1 rounded-lg border p-4 transition-colors hover:bg-accent hover:text-accent-foreground sm:w-[48%]",
						"text-left",
					)}
				>
					<span className="flex items-center text-xs text-muted-foreground">
						<ChevronLeftIcon className="mr-1 h-3 w-3" />
						Previous
					</span>
					<span className="text-sm font-medium font-title">{prev.title}</span>
				</a>
			) : (
				<div className="sm:w-[48%]" aria-hidden="true" />
			)}

			{next ? (
				<a
					href={next.href}
					className={cn(
						"flex flex-col gap-1 rounded-lg border p-4 transition-colors hover:bg-accent hover:text-accent-foreground sm:w-[48%]",
						"ml-auto text-right items-end",
					)}
				>
					<span className="flex items-center text-xs text-muted-foreground">
						Next
						<ChevronRightIcon className="ml-1 h-3 w-3" />
					</span>
					<span className="text-sm font-medium font-title">{next.title}</span>
				</a>
			) : (
				<div className="sm:w-[48%]" aria-hidden="true" />
			)}
		</div>
	);
}
