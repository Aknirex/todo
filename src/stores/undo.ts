import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { uuid } from '@/utils'
import { undoRepository } from '@/dal'
import type { AgentActionType, EntityType, UndoRecord } from '@/types'

export const useUndoStore = defineStore('undo', () => {
  const MAX_STACK_SIZE = 50
  const undoStack = ref<UndoRecord[]>([])

  function record(
    actionType: AgentActionType,
    entityType: EntityType,
    entityId: string,
    before: any,
    after: any
  ): void {
    const rec: UndoRecord = {
      id: uuid(),
      actionType,
      entityType,
      entityId,
      beforeState: before ? JSON.stringify(before) : null,
      afterState: after ? JSON.stringify(after) : null,
      createdAt: new Date().toISOString()
    }
    undoStack.value.push(rec)
    if (undoStack.value.length > MAX_STACK_SIZE) {
      undoStack.value.shift()
    }
    undoRepository.insert(rec).catch(() => {})
  }

  async function undo(): Promise<UndoRecord | null> {
    const rec = undoStack.value.pop()
    if (!rec) return null
    await undoRepository.delete(rec.id).catch(() => {})
    return rec
  }

  async function loadFromDb(): Promise<void> {
    const records = await undoRepository.findRecent(MAX_STACK_SIZE)
    undoStack.value = records.reverse()
  }

  const canUndo = computed(() => undoStack.value.length > 0)

  return { undoStack, record, undo, canUndo, loadFromDb }
})
