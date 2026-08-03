import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { uuid } from '@/utils'
import { todoRepository } from '@/dal'
import { useUndoStore } from './undo'
import type { Todo, CreateTodoInput, UpdateTodoInput, TodoFilter } from '@/types'

function now(): string {
  return new Date().toISOString()
}

function buildTodo(input: CreateTodoInput, listId?: string): Todo {
  return {
    id: uuid(),
    title: input.title || '',
    priority: input.priority || 'medium',
    dueDate: input.dueDate || null,
    tags: input.tags || [],
    detail: input.detail || '',
    completed: false,
    listId: input.listId || listId || 'default',
    createdAt: now(),
    updatedAt: now(),
    deleted: false
  }
}

export const useTodoStore = defineStore('todo', () => {
  const todos = ref<Todo[]>([])
  const loading = ref(false)

  const activeTodos = computed(() =>
    todos.value.filter(t => !t.deleted && !t.completed)
  )
  const completedTodos = computed(() =>
    todos.value.filter(t => !t.deleted && t.completed)
  )
  const todosByList = (listId: string) =>
    todos.value.filter(t => !t.deleted && t.listId === listId)

  async function createTodo(input: CreateTodoInput): Promise<Todo> {
    const undoStore = useUndoStore()
    const todo = buildTodo(input)
    todos.value.push(todo)
    await todoRepository.insert(todo)
    undoStore.record('create', 'todo', todo.id, null, todo)
    return todo
  }

  async function updateTodo(id: string, input: UpdateTodoInput): Promise<void> {
    const undoStore = useUndoStore()
    const index = todos.value.findIndex(t => t.id === id)
    if (index === -1) return
    const before = { ...todos.value[index] }
    const updated = { ...todos.value[index], ...input, updatedAt: now() }
    todos.value[index] = updated
    await todoRepository.update(id, input)
    undoStore.record('update', 'todo', id, before, updated)
  }

  async function deleteTodo(id: string): Promise<void> {
    const undoStore = useUndoStore()
    const index = todos.value.findIndex(t => t.id === id)
    if (index === -1) return
    const before = { ...todos.value[index] }
    todos.value[index].deleted = true
    await todoRepository.softDelete(id)
    undoStore.record('delete', 'todo', id, before, null)
  }

  async function toggleComplete(id: string): Promise<void> {
    const undoStore = useUndoStore()
    const index = todos.value.findIndex(t => t.id === id)
    if (index === -1) return
    const before = { ...todos.value[index] }
    todos.value[index].completed = !todos.value[index].completed
    todos.value[index].updatedAt = now()
    await todoRepository.toggleComplete(id)
    undoStore.record('toggle_complete', 'todo', id, before, todos.value[index])
  }

  async function loadTodos(): Promise<void> {
    loading.value = true
    todos.value = await todoRepository.findAll()
    loading.value = false
  }

  return {
    todos, loading, activeTodos, completedTodos, todosByList,
    createTodo, updateTodo, deleteTodo, toggleComplete, loadTodos
  }
})
