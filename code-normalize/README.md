---
name: code-normalize
description: 检测并安全规范 Java、Kotlin 类中的成员变量命名，更新全部引用，补充缺失的类注释，并为关键成员添加作用说明；发现已启用 ViewBinding 页面中的 findViewById 时，优先改用安全的 Binding 引用。当用户要求检查或重构 bname、a_b、mUserName、含义不清的缩写、snake_case 成员，或希望在不改变行为的前提下提升类与成员命名、注释质量时使用。
---

# Code Normalize

使用有明确业务语义的名称规范类成员，保护外部数据契约，更新所有引用，并验证项目仍可正常构建。支持 Java 和 Kotlin。

## 基础规范

- 必须遵循 `$skill-common` 的基础规范，所有面向用户的说明、报告和新增注释使用中文。

## 强制工作流程

除非用户明确只要求分析，否则必须连续执行以下全部步骤：

1. 完整读取目标类。
2. 确认所属模块、语言、基类、接口、生成的 Binding 以及构建命令。
3. 使用 `rg` 扫描所有 Java/Kotlin 调用方和文本引用。
4. 在重命名前对每个成员进行分类，并检查页面内是否存在 `findViewById` 或等价 ID 查找。
5. 建立重命名表，记录旧名称、新名称、业务含义、可见性和风险。
6. 只有通过外部契约检查后，才能执行重命名。
7. 更新声明、读取、赋值、构造参数、回调、测试和 import 中的全部引用。
8. 为缺少注释的类补充 KDoc/JavaDoc。
9. 为关键成员添加简洁注释。
10. 如果仓库已有格式化工具，则执行对应格式化命令。
11. 编译受影响模块并运行相关测试。
12. 再次搜索旧名称，报告已修改、已跳过和受外部契约保护的成员。
13. 调用 `$skill-common` 复盘本次执行，并报告是否更新本技能。

当用户要求直接修复时，禁止只给建议而不修改代码。

## 职责路由

- 所有成员命名、类注释和关键成员注释规范化必须使用本技能，禁止由通用能力或其他 Skill 自行实现。
- Java 转 Kotlin 必须交给 `$java-to-kotlin`；本技能只规范转换结果，不负责语言迁移。
- 深度逻辑分析、Bug 检测和方法级注释必须交给 `$code-analyzer`；本技能不复制其分析流程。
- 当本技能由 `$code-analyzer` 或 `$java-to-kotlin` 调用时，只执行规范化流程，不得反向调用父 Skill。

## 命名决策

编辑前必须读取 [references/naming-rules.md](references/naming-rules.md)。

核心规则：

- 可变与不可变实例成员统一使用有明确含义的 `lowerCamelCase`。
- 只有真正的常量才使用 `UPPER_SNAKE_CASE`。
- 优先表达业务语义，禁止只做拼音转换或机械大小写转换。
- 移除 `m`、`str`、`obj` 等匈牙利命名或类型前缀，除非它们是仓库统一约定。
- Boolean 成员尽量使用判断式名称，例如 `isLoading`、`hasPermission`、`canRetry`。
- 按项目风格统一缩写，例如 `userId`、`apiUrl`、`html`。
- 长期存在的成员状态禁止使用单字母或模糊名称，例如 `a`、`b`、`data`、`temp`、`info`、`value`、`list`、`map`。
- 当存在多个合理语义时禁止猜测。应从赋值来源、接口字段、UI 文案和调用方推断；只有无法安全确定时才询问用户。

示例：

| 不规范名称 | 推荐名称 | 要求 |
|---|---|---|
| `bname` | `babyName` 或 `userName` | 根据真实业务语义选择 |
| `a_b` | `accountBalance` | 能查明含义时禁止只改成 `aB` |
| `mUserList` | `userList` | 移除成员或类型前缀 |
| `flag` | `isCourseHidden` | 明确表达判断条件 |
| `tmp` | `formattedPhoneNumber` | 说明该值存在的目的 |

## 外部契约安全

每次重命名前，必须检查字段名称是否被普通源码引用之外的机制使用：

- Gson、Fastjson、Jackson 序列化或反射
- Room、Realm、ORM、数据库列映射
- Parcelable、Serializable 兼容性
- JNI 或 Native 代码
- XML DataBinding、`android:onClick`、Compose 稳定性 API
- 依赖注入、EventBus、框架回调
- 第三方库依赖的 JavaBean getter/setter
- 公共 SDK/API 或二进制兼容性
- 测试、ProGuard/R8 keep 规则、字符串反射

外部名称必须保持不变时：

- 项目已使用相应框架时，优先添加 `@SerializedName("bname")`、`@Json`、`@ColumnInfo(name = "a_b")` 等映射注解。
- 需要保持二进制兼容时，保留公共 getter/setter 名称。
- 没有安全映射方式时，跳过重命名并说明原因。

禁止重命名生成的 ViewBinding、DataBinding 字段，禁止修改生成源码。

## ViewBinding 优先

发现 `findViewById`、`root.findViewById`、`view.findViewById` 或封装后的等价 ID 查找时，必须判断当前类、内部类、Fragment/Activity/Dialog、Adapter ViewHolder 或父级页面是否已持有同一布局作用域的 ViewBinding/DataBinding。

- 已存在可安全访问的 Binding，且目标 ID 属于该 Binding 覆盖的布局时，优先改为 Binding 字段访问。
- Fragment 中只在 Binding 生命周期有效区间内替换；可能跨越 `onDestroyView`、异步回调或缓存 View 时必须跳过并说明风险。
- 父级页面提供 Binding 时，只在访问边界清晰且不扩大可见性、不引入泄漏的情况下复用；否则保持原实现。
- 无法确认 ID 与 Binding 字段映射、动态 inflate 多布局、include/merge 作用域不清或第三方视图缓存场景，禁止猜测替换。
- 替换后必须搜索残留 ID 查找，并通过受影响模块编译验证字段名和生命周期可用性。

## 类注释

如果 class、object、interface、enum 或 data class 没有 KDoc/JavaDoc，必须在声明正上方添加，并说明：

- 类的主要职责
- 类持有的重要状态
- 非显而易见的协作者或生命周期限制

类注释应保持简洁，禁止添加作者、日期等无实际价值的模板信息。

## 成员注释

以下关键成员需要添加注释：

- 与生命周期相关的引用
- 计时器、Job、订阅、监听器、适配器、Dialog
- 控制业务行为的可变状态
- 缓存值和持久化值
- 元素含义不明显的集合
- 具有单位、范围、特殊值或所有权规则的成员

不需要为含义明确的常量、明显的 Binding 或简单不可变依赖添加重复注释。
注释应说明用途、所有权、单位或生命周期，禁止只复述变量名和类型。

推荐：

```kotlin
/** 当前观看周期剩余秒数；0 表示未启用观看限制。 */
private var remainingViewingSeconds = 0
```

不推荐：

```kotlin
/** 剩余观看秒数。 */
private var remainingViewingSeconds = 0
```

## 编辑约束

- 除非用户明确要求修改公共 API，且所有调用方都能迁移，否则必须保持行为和公共 API 不变。
- 有符号级重命名工具时优先使用；否则必须结合精确编辑、完整 `rg` 扫描和编译验证。
- 禁止修改无关格式或顺手重构无关方法。
- 修改 Kotlin 时禁止引入 `!!`。
- 尊重脏工作区，禁止撤销用户已有修改。
- 遇到职责路由中的语言转换或代码分析需求时，必须使用对应 Skill，禁止手动代替。

## 验证要求

最低验证命令：

```bash
rg -n '\boldName\b' <source-roots>
./gradlew :affected-module:compileDebugKotlin
./gradlew :affected-module:compileDebugJavaWithJavac
```

根据仓库实际构建任务调整。Android app 修改应优先同时执行 Kotlin、Java 编译；当重命名跨越多个调用方或资源边界时，还应执行 `assembleDebug`。

必须确认：

- 源码中不存在遗留旧名称
- 没有误改字符串形式的外部契约
- Java 调用方仍可编译
- 序列化和数据库映射仍保留原外部名称
- 类注释和关键成员注释完整
- 未修改生成文件

## 最终报告

报告内容必须包含：

- 修改的文件和成员名称
- 新增的类注释与成员注释
- 主动跳过的字段及原因
- 新增的兼容性映射注解
- 执行的编译、测试命令及结果
- `$skill-common` 接受、拒绝的候选经验及本技能是否发生修改

## 技能进化

任务完成并验证后，必须调用 `$skill-common` 复盘本技能；本技能不重复保存进化门槛和依赖去重策略。
