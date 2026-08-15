import { successResponse, errorResponse, registerRoute, type AgentApiServer } from './server'
import { todoRepository, listRepository } from '@/dal'
import { useTodoStore, useUndoStore } from '@/stores'

export function registerAllRoutes(server: AgentApiServer): void {
  registerRoute(server, 'POST', '/api/v1/todos', async ({ body }: { body?: any }) => {
    const store = useTodoStore()
    const todo = await store.createTodo(body)
    return successResponse(todo)
  })

  registerRoute(server, 'GET', '/api/v1/todos', async ({ query }: { query?: any }) => {
    const filter: any = {}
    if (query?.listId) filter.listId = query.listId
    if (query?.priority) filter.priority = query.priority
    if (query?.completed !== undefined) filter.completed = query.completed === 'true'
    if (query?.keyword) {
      const results = await todoRepository.search(query.keyword)
      return successResponse(results)
    }
    const todos = await todoRepository.findAll(filter)
    return successResponse(todos)
  })

  registerRoute(server, 'GET', '/api/v1/todos/:id', async ({ pathParams }: { pathParams?: any }) => {
    const todo = await todoRepository.findById(pathParams.id)
    if (!todo) return errorResponse(2002, 'Todo not found')
    return successResponse(todo)
  })

  registerRoute(server, 'PATCH', '/api/v1/todos/:id', async ({ pathParams, body }: { pathParams?: any; body?: any }) => {
    const store = useTodoStore()
    await store.updateTodo(pathParams.id, body)
    const todo = await todoRepository.findById(pathParams.id)
    return successResponse(todo)
  })

  registerRoute(server, 'DELETE', '/api/v1/todos/:id', async ({ pathParams }: { pathParams?: any }) => {
    const store = useTodoStore()
    await store.deleteTodo(pathParams.id)
    return successResponse({ deleted: true })
  })

  registerRoute(server, 'POST', '/api/v1/todos/:id/toggle', async ({ pathParams }: { pathParams?: any }) => {
    const store = useTodoStore()
    await store.toggleComplete(pathParams.id)
    const todo = await todoRepository.findById(pathParams.id)
    return successResponse(todo)
  })

  registerRoute(server, 'POST', '/api/v1/todos/batch', async ({ body }: { body?: any }) => {
    const store = useTodoStore()
    const listId = body?.listId || 'default'
    const results = []
    for (const todoInput of (body?.todos || [])) {
      const todo = await store.createTodo({ ...todoInput, listId })
      results.push(todo)
    }
    return successResponse(results)
  })

  registerRoute(server, 'GET', '/api/v1/lists', async () => {
    const lists = await listRepository.findAll()
    return successResponse(lists)
  })

  registerRoute(server, 'GET', '/api/v1/lists/:id', async ({ pathParams }: { pathParams?: any }) => {
    const list = await listRepository.findById(pathParams.id)
    if (!list) return errorResponse(2002, 'List not found')
    const todos = await todoRepository.findAll({ listId: pathParams.id })
    return successResponse({ ...list, todos })
  })

  registerRoute(server, 'GET', '/api/v1/search', async ({ query }: { query?: any }) => {
    const keyword = query?.q || ''
    if (!keyword) return errorResponse(2001, 'Missing query parameter: q')
    const results = await todoRepository.search(keyword)
    return successResponse(results)
  })

  registerRoute(server, 'POST', '/api/v1/undo', async () => {
    const undoStore = useUndoStore()
    const rec = await undoStore.undo()
    if (!rec) return errorResponse(2002, 'Nothing to undo')
    const store = useTodoStore()
    await store.loadTodos()
    return successResponse({ undone: rec })
  })
}
