# aknirex-todo Domain Context

这是 aknirex-todo 的领域语言约定，用于保持产品、数据模型和客户端之间的概念一致。实现可以迁移，但领域术语不因技术栈变化而漂移。

## Core Language

**Todo**:
一项用户希望记录、追踪或完成的任务单元；创建时可以暂时为空白，之后再补充内容。
_Avoid_: Task（作为领域对象名）、事项

**List**:
一组由用户组织在一起的 Todo 集合。
_Avoid_: 清单、列表（作为领域对象名）

**Undo**:
用户对最近一次 Todo 或 List 变更执行的反向操作；首版最多保留 50 步可撤销历史。
_Avoid_: 回收站、删除提示

**Redo**:
用户重新应用最近一次 Undo 所反向的 Todo 或 List 变更；首版最多保留 50 步可重做历史。
_Avoid_: 重复操作

**DueDate**:
Todo 计划完成的本地日历日期，只表示某一天，不表示具体时刻。
_Avoid_: 截止时间、UTC 时间点

**Priority**:
用户对 Todo 重要性的主观分级，取 high、medium 或 low；默认值为 medium。
_Avoid_: 紧急程度、系统评分

**Tag**:
用户附加在 Todo 上的自由文本分类标记；同一 Todo 内不重复，但不独立成为 Tag 实体。
_Avoid_: 系统分类、预定义标签
