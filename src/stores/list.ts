import { defineStore } from 'pinia'
import { ref } from 'vue'
import { uuid } from '@/utils'
import { listRepository } from '@/dal'
import { useUndoStore } from './undo'
import type { TodoList } from '@/types'

function now(): string {
  return new Date().toISOString()
}

export const useListStore = defineStore('list', () => {
  const lists = ref<TodoList[]>([])

  async function loadLists(): Promise<void> {
    lists.value = await listRepository.findAll()
  }

  async function createList(name: string): Promise<TodoList> {
    const undoStore = useUndoStore()
    const list: TodoList = {
      id: uuid(),
      name: name || '新列表',
      isDefault: false,
      createdAt: now(),
      sortOrder: lists.value.length
    }
    lists.value.push(list)
    await listRepository.insert(list)
    undoStore.record('create', 'list', list.id, null, list)
    return list
  }

  async function updateList(id: string, input: { name?: string }): Promise<void> {
    const undoStore = useUndoStore()
    const index = lists.value.findIndex(l => l.id === id)
    if (index === -1) return
    const before = { ...lists.value[index] }
    if (input.name !== undefined) lists.value[index].name = input.name
    await listRepository.update(id, input)
    undoStore.record('update', 'list', id, before, lists.value[index])
  }

  async function deleteList(id: string): Promise<void> {
    const undoStore = useUndoStore()
    const index = lists.value.findIndex(l => l.id === id)
    if (index === -1 || lists.value[index].isDefault) return
    const before = { ...lists.value[index] }
    lists.value.splice(index, 1)
    await listRepository.delete(id)
    undoStore.record('delete', 'list', id, before, null)
  }

  return { lists, loadLists, createList, updateList, deleteList }
})
