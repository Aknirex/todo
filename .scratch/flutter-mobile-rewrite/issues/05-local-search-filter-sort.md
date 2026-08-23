# 05 — 本地搜索、筛选与排序

**What to build:** 用户可以在离线状态下搜索所有 Todo 的 title、detail 和 Tag，并组合 Priority、Tag、完成状态和 DueDate 筛选；首页和搜索结果提供稳定、可解释的排序与匹配展示。

**Blocked by:** 03 — Todo 详情与移动端编辑生命周期

**Status:** done

- [x] 搜索输入支持约 300ms 防抖并在本地查询
- [x] 搜索覆盖 title、detail 和 tags 的包含匹配
- [x] 搜索结果优先展示标题命中的 Todo，并高亮匹配内容
- [x] 支持 high、medium、low Priority 筛选
- [x] 支持多选 Tag 筛选，标签值来自当前 Todo 数据
- [x] 支持已完成/未完成筛选
- [x] 支持今天、本周、本月、逾期和无 DueDate 筛选，按本地日历计算
- [x] 不同筛选维度使用 AND，同一维度多个值使用 OR
- [x] 搜索、筛选和排序可以组合使用，并在无结果时展示明确空状态
- [x] 默认排序保持未完成优先、最新创建优先；用户可切换 Priority、DueDate 和 alpha 排序
- [x] 搜索与筛选在无网络时仍可用，并有应用层、Widget 和查询集成测试
