import type { PackageNode } from '../mock-data'
import { cn } from '../lib/utils'
import { FolderTree, Folder } from 'lucide-react'

function relationLabel(relation: PackageNode['relation']): string {
  switch (relation) {
    case 'root': return 'Root'
    case 'workspace': return 'Workspace'
    case 'direct': return 'Direct'
    case 'transitive': return 'Transitive'
  }
}

export function PackageTree(props: {
  node: PackageNode
  depth?: number
  selected: string
  onSelect: (name: string) => void
}): React.JSX.Element {
  const { node, depth = 0, selected, onSelect } = props
  const isSelected = selected === node.name
  return (
    <div className="flex flex-col">
      <button
        className={cn(
          'flex items-center gap-2 px-2 py-1.5 text-sm rounded-md transition-colors',
          isSelected
            ? 'bg-accent text-accent-foreground font-medium'
            : 'text-muted-foreground hover:bg-muted hover:text-foreground'
        )}
        onClick={() => onSelect(node.name)}
        type="button"
      >
        <span style={{ width: depth * 12 }} className="shrink-0" />
        {node.children.length > 0 ? (
          <FolderTree className="w-4 h-4 shrink-0 text-muted-foreground" />
        ) : (
          <Folder className="w-4 h-4 shrink-0 text-muted-foreground" />
        )}
        <span className="truncate">{node.name}</span>
        <span className={cn(
          'ml-auto text-[10px] h-4 px-1.5 rounded shrink-0 border',
          node.relation === 'root'
            ? 'bg-primary/10 text-primary border-primary/20'
            : 'bg-muted text-muted-foreground border-border'
        )}>
          {relationLabel(node.relation)}
        </span>
      </button>
      {node.children.length > 0 && (
        <div className="flex flex-col">
          {node.children.map((child) => (
            <PackageTree
              key={`${node.name}-${child.name}`}
              node={child}
              depth={depth + 1}
              selected={selected}
              onSelect={onSelect}
            />
          ))}
        </div>
      )}
    </div>
  )
}