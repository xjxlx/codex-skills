---
name: code-analyzer
description: 为指定 Java、Kotlin 文件统一完成成员命名规范化、类与关键成员注释、方法逻辑梳理、详细中文方法注释、潜在 bug 检测和性能复杂度分析。适用于阅读代码、分析逻辑、代码审查、命名整理和注释补全；所有此类任务必须使用本技能。
---

# 代码分析器

统一承担 Java、Kotlin 代码的结构规范化、逻辑分析和注释补全，避免分析与命名整理分裂到多个 Skill。

## 强制约束

- 任务开始时必须先执行 `"${CODEX_HOME:-$HOME/.codex}/skills/github-manager/scripts/check_and_publish.sh"`；成功后遵循 `$skill-common` 基础规范，使用中文输出说明、报告和代码注释。
- 所有代码阅读、逻辑分析、方法注释、成员命名整理、类注释补全、关键成员注释补全和代码审查任务必须使用本技能，禁止拆分到通用能力或已废弃的旧 Skill。
- 必须连续完成步骤 0 到步骤 8，并维护 `.codex/analysis/` 缓存；遇到困难先尝试解决，不得无故中止。
- 修改命名时必须保护序列化、数据库、反射、EventBus、JNI、公共 API、JavaBean、DataBinding/ViewBinding、R8 keep 规则等外部契约。
- 如果类中存在 `findViewById`、`findView` 或等价视图查找，且父类链已提供 ViewBinding 能力，必须优先改为 ViewBinding 访问；只有绑定链无法覆盖该视图时才保留旧写法并说明原因。

## 职责路由

- Java 转 Kotlin 请求必须交给 `$java-to-kotlin`；本技能不手动做语言迁移。
- 转换后的命名规范化、类/成员注释、方法注释、Bug 检测和 ViewBinding 收敛仍由本技能承接。
- 本技能已吸收原独立命名整理职责，后续不得再依赖额外的命名规范化 Skill。

## 分析缓存机制

### 目的

1. 锁定分析结果，降低同一文件多次分析的非确定性。
2. 复用类摘要、方法说明、已发现 Bug 和复杂度结论，加快后续修改。
3. 在上下文被压缩后继续复用磁盘缓存。

### 位置

每个项目根目录下的 `.codex/analysis/`：

```text
<project-root>/
├── .codex/analysis/
│   ├── manifest.json
│   └── <hash>_<ClassName>.json
├── app/
└── build.gradle.kts
```

### 缓存校验

- 使用 SHA-256 对源文件内容计算 hash。
- hash 匹配则复用缓存；不匹配则重新分析并覆盖缓存。
- manifest 不存在时视为首次分析并创建。

## 工作流程

> 所有步骤必须连续执行，中间不得暂停等待用户补充说明。

0. 检查分析缓存。
1. 读取目标文件并识别模块、类层次、公共 API、状态和热点路径。
2. 做结构规范化：成员命名、类注释、关键成员注释、必要的 ViewBinding 收敛和受影响调用方更新。
3. 逐方法分析功能、参数、返回值、副作用和状态变化。
4. 检测潜在 bug、并发问题、Android 生命周期风险和性能复杂度问题。
5. 写入方法注释、必要的行内注释和风险标记。
6. 交叉验证命名、注释、契约兼容性和编译面。
7. 生成或更新 `.codex/analysis/` 缓存。
8. 按 `$skill-common` 复盘本技能。

## 步骤 0：检查分析缓存

执行流程：

1. 向上查找 `build.gradle.kts` 或 `settings.gradle.kts` 确定项目根目录。
2. 读取 `<项目根目录>/.codex/analysis/manifest.json`。
3. 对比当前文件内容 hash 与 manifest 中记录。
4. 命中有效缓存时加载缓存摘要，作为后续分析上下文。

缓存有效时仍要继续步骤 1 到步骤 6，因为注释、命名或 ViewBinding 改造可能已被后续修改破坏。

## 步骤 1：读取目标文件

至少确认以下内容：

- 文件包含多少个类、对象或内部类。
- 继承链、接口、组合依赖和关键协作者。
- 主要 public API、生命周期入口、回调入口和线程切换点。
- 可能影响命名推断的 API 字段、资源 ID、UI 文案和调用方语义。
- 可能影响 ViewBinding 改造的父类能力、`getBinding()`/`inflateBinding()` 模式和现有 binding 字段。

## 步骤 2：结构规范化

### 2.1 调用方与外部契约扫描

必须先用 `rg` 扫描以下引用：

- Java/Kotlin 调用方、测试和 import。
- JSON/数据库映射、反射字符串、JNI、注解和 keep 规则。
- `findViewById`、`findView`、`ButterKnife`、旧 View 缓存字段和 binding 相关实现。

### 2.2 成员命名规范

对每个成员先分类，再决定是否重命名：

- 实例属性统一为有明确语义的 `lowerCamelCase`。
- Boolean 优先使用 `isXxx`、`hasXxx`、`canXxx`。
- 常量使用 `UPPER_SNAKE_CASE`。
- 集合、监听器、计时器、缓存值和跨生命周期状态必须体现业务语义。
- 禁止保留 `m`、`str`、`obj`、`tmp`、`flag`、`data`、`info`、`a_b`、`bname` 这类含义不清的名称，除非外部契约无法迁移。

推断新名称时按以下顺序取证：

1. 服务端字段文档、映射注解和数据库列。
2. 资源 ID、UI 文案、getter/setter、方法参数和赋值来源。
3. 调用方、下游使用场景和项目领域词汇。

无法安全确定语义时，先保留原名并在报告中说明，而不是机械改大小写。

### 2.3 外部契约保护

每次重命名前都必须检查：

- Gson、Fastjson、Jackson、Room、Realm、Parcelable、Serializable。
- EventBus、依赖注入、第三方回调、JavaBean getter/setter。
- JNI、反射、字符串常量、XML 绑定、Compose 稳定性 API。
- 公共 SDK/API、二进制兼容性和 Java 调用方。

需要保留外部名称时，优先使用兼容注解或仅重命名私有后备字段；无法安全兼容时跳过并记录原因。

### 2.4 类注释与关键成员注释

如果缺失，必须补充：

- 类注释：职责、重要状态、关键协作者、生命周期限制。
- 关键成员注释：计时器、Job、订阅、监听器、Dialog、缓存值、跨线程共享状态、带单位或特殊值的字段。

禁止添加只复述字段名和类型的空洞注释。

### 2.5 ViewBinding 收敛

当类中存在视图查找逻辑时，必须检查父类链是否已经提供：

- `BaseActivity<T : ViewBinding>`、`BaseFragment<T : ViewBinding>` 或等价泛型基类。
- `binding`、`mBinding`、`viewBinding` 等已初始化字段。
- `getBinding()`、`createBinding()`、`inflateBinding()` 或等价模板方法。

若父类或当前类已具备 ViewBinding 能力：

1. 将 `findViewById`/`findView` 结果改为 binding 属性访问。
2. 删除仅为缓存 View 引用而存在的冗余字段。
3. 更新初始化逻辑、点击绑定和空安全写法。
4. 仅在父类协议要求时保留必要的 binding 获取方法。

若不具备 ViewBinding 能力：

- 保留视图查找写法，但要修正命名、空安全和复用方式。
- 在报告中说明未迁移原因，例如工具类、Adapter、第三方 View 容器或基类不支持。

结构规范化完成后，必须重新读取目标文件，再进入方法分析。

## 步骤 3：方法级分析与注释

必须为每个方法补充准确的 KDoc/JavaDoc，包括 private 方法。内容至少覆盖：

- 方法职责和关键流程。
- 关键参数的业务含义。
- 返回值、回调、副作用和状态变化。
- 非显而易见的线程、生命周期或数据依赖。

逻辑极简的方法可写成单行注释；状态切换、持久化、计时器启停、页面跳转、回调转发等关键调用前应补简洁行内注释。

## 步骤 4：Bug 与复杂度分析

逐方法检查以下问题模式，并只在有证据时标注：

### 空安全与类型安全

- 链式调用中的中间对象可能为 null。
- `Intent`、`Bundle`、`arguments`、Map 取值后直接使用。
- Kotlin `as` 强转、不安全集合索引和越界访问。
- 异步回调中使用已销毁的 `Activity`、`Fragment` 或 `View`。

### 逻辑与资源问题

- `switch/case` 漏 `break`、除零、整数溢出、循环中改集合、资源未关闭。
- 关键状态在多处重复重置或清理，适合提炼私有方法。
- 包路径使用 Java 保留关键字，导致 Java 调用方无法 import。

### Android 生命周期与 UI

- 非 UI 线程更新 View、Handler/Runnable/Timer 泄漏、监听器未取消、单例持有 Activity。
- Adapter 共享 `LayoutParams`、在 `onBindViewHolder` 中直接捕获 `position`。
- `findViewById` 已可被 ViewBinding 替代却仍手写缓存逻辑。
- 仅用弱引用保存 Activity，但后续跳转缺少 application context 兜底。

### 并发与线程

- 非线程安全单例、复合操作的原子性问题、锁外共享状态访问。
- RxJava、协程、Flow、LiveData 订阅未在生命周期结束时取消。

### 性能与复杂度

- 嵌套遍历、循环内 I/O、主线程阻塞、重复排序/查找。
- RecyclerView 绑定阶段重复分配对象、全量刷新和无必要重算。

只有当输入规模和调用频率足以造成实际影响时，才标注 `⚠️ [性能问题: 类型]`，并说明原因、优化方式和可能收益。

## 步骤 5：写入注释与标记

- 使用 `apply_patch` 写入注释和必要的结构调整。
- 对有风险的方法，将 `⚠️ [潜在Bug: 类型]` 放在方法注释第一行，并写明触发条件、后果和修复方向。
- 大文件按 public 方法、private 方法、行内注释的顺序分批处理，避免遗漏。

## 步骤 6：交叉验证

至少确认：

- 命名、类注释、成员注释和方法注释与代码行为一致。
- 旧名称已被替换或被兼容映射保护。
- ViewBinding 改造没有破坏父类协议、初始化时机和空安全。
- Bug 标注不过度误报，复杂度标注具有实际意义。
- 受影响模块按仓库可用命令完成最小编译验证；无法验证时要明确说明。

## 步骤 7：生成或更新缓存

缓存内容至少包含：

- `classSummary`
- `designPattern`
- `dependencies`
- `methods`
- `openBugs`
- `complexityIssues`

hash 计算示例：

```bash
shasum -a 256 <文件路径> | awk '{print $1}'
```

## 步骤 8：技能进化

任务完成并验证后，必须调用 `$skill-common` 复盘本技能；没有新增硬证据时允许不修改，但要说明结论。

## 注释质量标准

- 重点解释“为什么这样做”以及“这段代码依赖什么状态”。
- 优先标出非显而易见的生命周期、线程、契约和业务限制。
- 注释、风险标记和重命名都要可执行、可验证，避免空话。
- 除非用户明确要求，只做与当前分析、规范化和安全迁移直接相关的修改。
