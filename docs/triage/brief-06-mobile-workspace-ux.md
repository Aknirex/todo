# Agent Brief — 移动端工作区体验与 Todo 创建流程优化

> *This was synthesized from `docs/实机测试反馈.md`.*

**Category:** enhancement
**State:** ready-for-agent
**Triage label:** `ready-for-agent`

## Problem Statement

在移动端实机上，Todo 工作区的信息密度和交互层级不适合单手使用。页面包含不必要的标题、副标题和搜索提示；搜索框占据过多首屏空间；筛选展开后会遮挡触发按钮，排序又独占一行。新建入口偏低，新建 Todo 时键盘会遮挡创建按钮，用户必须先收起输入框才能完成创建。列表无法为无标题但有详情的 Todo 提供可识别的内容预览，新建 Todo 的默认 Priority 也不会稳定展示。空状态、用户可见术语和标签输入缺少完整中文本地化，全角逗号无法分隔 Tag，下拉动画也显得迟缓。

## Solution

将工作区重组为适合现代手机和单手操作的界面：移除冗余文案，把搜索收敛为顶栏图标并以带背景模糊的搜索页/浮层展开；将筛选和排序作为同级操作，以不遮挡触发器的下拉或 bottom sheet 呈现；把新建入口放入右下角拇指热区。重做新建 Todo 的移动端布局，使标题、详情、Priority、Tag、DueDate 和创建操作在键盘出现时仍可用，并让创建操作直接提交当前输入。列表对无标题 Todo 使用详情摘要，统一显示默认 Priority 和已有 Tag，分别为未完成与已完成分段提供空状态文案。所有用户可见术语均通过中文和英文本地化提供，Tag 同时接受半角和全角逗号，所有下拉动效缩短到响应迅速但可感知的时长。

## User Stories

1. As a Todo user, I want the workspace to show only useful context, so that I can reach my Todo content faster.
2. As a Chinese-speaking Todo user, I want the workspace title and supporting copy to avoid redundant wording, so that the screen feels concise.
3. As a Todo user, I want search to be available from a compact top-bar icon, so that search does not consume permanent list space.
4. As a Todo user, I want tapping search to animate into a capsule-shaped search surface, so that the transition is understandable without a separate page hierarchy.
5. As a Todo user, I want the expanded search surface to keep the search icon on the left and a clear/submit control on the right, so that the main search actions remain easy to reach.
6. As a Todo user, I want the workspace behind the expanded search surface to be visually de-emphasized, so that I can focus on the query.
7. As a Todo user, I want recent searches represented as compact capsule-like labels when that state is supported, so that I can reuse common queries quickly.
8. As a Todo user, I want search help text to be removed from the default workspace, so that the search control does not dominate the screen.
9. As a Todo user, I want to search Todo titles, details, and Tags using the existing local query behavior, so that the redesign does not reduce search capability.
10. As a Todo user, I want search results to retain title-match emphasis, so that I can understand why a result matched.
11. As a Todo user, I want Priority, Tag, completion status, and DueDate filters to remain available, so that compact presentation does not remove filtering power.
12. As a Todo user, I want filter controls to open below or in a bottom sheet with sufficient separation from their trigger, so that expanded content never covers the trigger labels.
13. As a Todo user, I want sorting and filtering to be sibling actions on one row or one entry point, so that sorting does not create an unnecessary second control row.
14. As a Todo user, I want filter and sort animations to finish quickly, so that the interface feels responsive on a phone.
15. As a Todo user, I want the new-Todo action in the lower-right thumb zone, so that I can create a Todo with one hand.
16. As a Todo user, I want the new-Todo action to remain reachable while the keyboard is open, so that I do not need to dismiss the keyboard before creating a Todo.
17. As a Todo user, I want the new-Todo form to keep the title and detail fields prominent, so that I can capture the core content first.
18. As a Todo user, I want Priority and Tag controls to share a row with proportions suited to their content, so that the form uses mobile width efficiently.
19. As a Todo user, I want DueDate and Create controls to share a row while keeping Create easy to tap, so that submission remains visible near the fields it applies to.
20. As a Todo user, I want creating a Todo to use the current title, detail, Priority, DueDate, and Tags immediately, so that no entered content is lost when the form submits.
21. As a Todo user, I want the new-Todo screen to omit Undo and Redo controls, so that text editing remains delegated to the keyboard and the form stays focused.
22. As a Todo user, I want an untitled Todo with detail to show the beginning of its detail in the workspace, so that I can identify it without opening it.
23. As a Todo user, I want long detail previews to be truncated after roughly 40–60 characters with an ellipsis, so that rows stay compact and readable.
24. As a Todo user, I want the same detail-derived display value used for title sorting when a Todo has no title, so that visible order matches what I see.
25. As a Todo user, I want a newly created Todo to show its default medium Priority badge immediately, so that its current state is visible without editing.
26. As a Todo user, I want Priority to remain visible independently of whether a DueDate exists, so that metadata does not appear conditionally by accident.
27. As a Todo user, I want existing Tags and DueDate metadata to remain visible in the row, so that the compact representation still communicates state.
28. As a Todo user, I want unfinished and completed sections to explain their own empty state, so that “no Todo” clearly refers to the selected section.
29. As a Todo user, I want the empty unfinished section and empty completed section to use distinct localized copy, so that the state is understandable in both languages.
30. As a Todo user, I want language switching to be located in Settings rather than the workspace overflow menu, so that workspace actions stay focused on Todo work.
31. As an English-speaking Todo user, I want Priority, Tag, DueDate, Undo, and Redo labels translated into English, so that no accidental Chinese-only or raw domain labels remain.
32. As a Chinese-speaking Todo user, I want Priority, Tag, DueDate, Undo, and Redo labels translated into Chinese, so that the interface uses consistent Chinese terminology.
33. As a Todo user, I want tooltips, labels, empty states, filter choices, sort choices, and metadata badges to use localization, so that changing locale updates every visible term consistently.
34. As a Todo user, I want to enter Tags separated by either a half-width or full-width comma, so that Chinese text input does not require manual punctuation conversion.
35. As a Todo user, I want whitespace-only and duplicate Tags normalized as before, so that accepting another separator does not create duplicate or empty Tags.
36. As a Todo user, I want the compact mobile layout to preserve minimum touch targets and safe-area behavior, so that visual compression does not make controls hard to use.
37. As a Todo user, I want the redesigned workspace to preserve local persistence and Undo/Redo semantics for Todo changes, so that a visual redesign does not alter data safety.

## Implementation Decisions

- Modify the workspace presentation and interaction layer while retaining `TodoWorkspace` as the highest existing orchestration seam for creating, updating, querying, completing, deleting, Undo, and Redo.
- Keep the existing local `TodoQueryEngine` behavior for title, detail, and Tag search, filter combinations, DueDate buckets, and sorting. Add a display-title derivation at the query/presentation boundary so untitled Todos use a trimmed detail preview, capped at approximately 40–60 characters, for display and title sorting.
- Replace the always-visible search TextField with a compact top-bar search trigger and an expanded search surface. The expanded state owns query editing, clear/submit behavior, and the visual de-emphasis of the workspace. It must preserve the existing debounce behavior and query result semantics.
- Present filter and sort controls as sibling actions. The implementation may use a positioned dropdown or bottom sheet, but the chosen surface must anchor with enough spacing to avoid covering its trigger and must work within mobile safe areas.
- Keep the FloatingActionButton as the new-Todo entry point, positioned using the existing Scaffold and safe-area behavior in the lower-right thumb zone.
- Restructure the new-Todo form into a mobile-first layout: title and detail remain primary fields; Priority and Tag share a row; DueDate and Create share a row. The Create action must remain visible or otherwise directly actionable while the keyboard is open. The form must not expose Todo history actions when creating a new Todo.
- Preserve the existing default `TodoPriority.medium` value and make the row metadata presentation unconditional for Priority. Tags and DueDate remain independently conditional on their values.
- Introduce localized strings for every user-visible domain term and interaction label, including Priority, Tag, DueDate, Undo, Redo, search, filter, sort, empty states, tooltips, and new form labels. The workspace overflow menu no longer owns language switching; Settings remains the single language-switching location.
- Extend Tag parsing to treat both `,` and the full-width `，` as separators before applying the existing trimming and de-duplication normalization.
- Shorten filter, sort, and related expansion animations using one consistent interaction duration from the design system rather than adding per-widget timing constants.
- Do not change the Todo persistence schema, local store contract, Undo/Redo history model, backup format, or public Agent API. The change is presentation, input normalization, and derived display behavior only.
- Preserve desktop behavior where the mobile-specific compact/search presentation is not appropriate, while ensuring the same localized content and derived display-title rules apply across platforms.

## Testing Decisions

- The primary test seam is the existing app-level `WorkspacePage` widget seam, pumped with an in-memory `TodoWorkspace` and a controlled locale. Tests should assert user-visible controls, navigation, rendered text, keyboard-safe creation, menu/sheet reachability, and resulting workspace state rather than private widget structure.
- Extend the existing workspace query widget tests to cover compact search entry/exit, query submission and clearing, filter/sort sibling placement, non-overlapping expanded controls, and localized labels.
- Extend the existing Todo editor widget tests to cover creating with the keyboard still visible, the mobile field arrangement, absence of history actions for a new Todo, full-width comma Tag parsing, and immediate visibility of the newly created Todo's medium Priority badge.
- Extend the existing pure `TodoQueryEngine` tests to cover detail-derived display titles, truncation, title sorting using the derived value, and preserving explicit titles unchanged.
- Extend the existing Todo model tests or the nearest pure seam for Tag parsing to cover half-width commas, full-width commas, mixed separators, whitespace, empty entries, and duplicates.
- Extend release acceptance coverage for the two section-specific empty states and for a blank-title/detail-only Todo surviving creation and query/display flows.
- Use existing mobile fidelity and golden-test infrastructure for the 390×844 layout. Update goldens only when the intended layout is established, and assert minimum touch-target and safe-area behavior separately where pixel comparison is insufficient.
- Add locale coverage for both supported locales and assert that no raw English domain terms remain in the Chinese workspace/editor surfaces and no untranslated Chinese domain terms remain in the English surfaces.
- Manual acceptance remains required on a representative Android phone: keyboard-open creation, search expansion, filter/sort overlays, thumb-zone FAB placement, full-width comma input, Chinese/English rendering, and animation responsiveness.

## Out of Scope

- Sync, multi-device conflict resolution, Agent API behavior, LLM features, and backup schema changes.
- Adding a new List management experience or changing the Todo/List domain model.
- Full-text search, search indexing, server-side search, or changing the current local query matching rules.
- Persisting a search-history database; capsule search history is limited to the interaction/design state needed by this feature unless an existing persistence mechanism already supports it.
- Redesigning the settings page beyond keeping language switching there and adding any missing strings it needs.
- Broad brand, typography, icon-family, or dark-theme redesign unrelated to the reported mobile workspace problems.
- Tablet-specific or desktop-specific layout redesign beyond preserving current usability.
- Adding explicit Save, Undo, or Redo controls to the new-Todo form.

## Further Notes

- The feedback combines visual polish and behavior corrections. Implementation should land them as one coherent mobile workspace pass so that changing the search/filter layout does not leave the new-Todo action or safe-area behavior inconsistent.
- The detail preview length is intentionally approximate; the implementation should choose one documented limit in the 40–60 character range and apply it consistently, including ellipsis behavior and whitespace trimming.
- The existing domain glossary terms are authoritative: use Todo, List, Undo, Redo, DueDate, Priority, and Tag in code-facing discussion and acceptance criteria.
- This issue is published locally because this repository has no external issue tracker. The triage ledger records it as `ready-for-agent`.
