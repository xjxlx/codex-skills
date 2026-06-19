---
name: java-to-kotlin
description: 将 Android 项目中的 Java 类转换为 Kotlin。用于将 Java 文件迁移到 Kotlin、用惯用 Kotlin 重写 Java 类、或现代化遗留 Java 代码。处理 ViewBinding 集成（当基类支持时），并在转换后验证编译。项目中所有 Java 转 Kotlin 操作必须使用此技能，禁止手动转换。
---

# Java 转 Kotlin 转换器

将 Java Android 类转换为惯用 Kotlin，确保正确的空安全、ViewBinding 集成和编译验证。

## 基础规范

- 任务开始时必须先执行 `"${CODEX_HOME:-$HOME/.codex}/skills/github-manager/scripts/check_and_publish.sh"`，成功后再继续。
- 必须遵循 `$skill-common` 的基础规范，面向用户的说明、报告和新增注释使用中文。

## 强制约束

1. **必须使用此技能**进行每次 Java 转 Kotlin 的请求。不得跳过或手动转换。
2. **必须扫描所有调用方**（Java 和 Kotlin）以了解 API 影响。
3. **必须保持二进制兼容性** — 当类被 Java 调用时，使用 `@JvmStatic`、`@JvmOverloads`、`@JvmField`。
4. **必须删除原始 `.java` 文件**（Kotlin 文件生成并确认完整后、编译前删除，避免同名类冲突）。
5. **必须通过编译验证** `./gradlew :module:compileDebugKotlin` 才能声明成功。
6. **禁止使用 `!!`（非空断言操作符）** — 始终使用安全替代方案。
7. **必须处理泛型基类**，使用星投影（`BaseActivity<*>`）当不需要传递类型参数时。
8. **必须调用 `$code-normalize`** 规范转换后的 Kotlin 类及本次修改的调用方。

## 职责路由

- 转换后的成员命名、类注释和关键成员注释必须交给 `$code-normalize`，不得复制其规范化流程。
- 用户要求深度逻辑分析、Bug 检测或完整方法注释时，必须额外使用 `$code-analyzer`。
- `$code-normalize` 作为本技能的子流程运行时，不得反向重新调用 `$java-to-kotlin`。

## 工作流程

1. **扫描调用方** — 查找所有引用该 Java 类的文件
2. **分析 Java 文件** — 类层次结构、字段、方法、内部类
3. **检测 ViewBinding 支持** — 在基类链中查找 ViewBinding 模式
4. **将 Java 语法转换为 Kotlin** — 遵循项目约定
5. **删除原始 `.java` 文件**
6. **代码规范化** — 调用 `$code-normalize` 处理转换结果和受影响调用方
7. **编译并验证** — 修复调用方问题直到编译通过
8. **技能进化** — 按 `$skill-common` 的证据门槛复盘本次转换

## 步骤 1：扫描调用方

转换前，查找所有引用：

```bash
rg "ClassName" -g "*.java" -g "*.kt" -l
```

这可以揭示：
- 调用方是 Java 还是 Kotlin（影响 `@JvmStatic` 的需要）
- 类是如何被实例化和使用的
- 调用处是否需要泛型或类型参数

## 步骤 2：分析 Java 文件

读取目标 Java 文件并识别：
- 包和导入
- 类声明和继承层次（检查基类泛型参数）
- 字段（视图引用和数据字段）
- 方法和生命周期回调
- 内部类、适配器或匿名类
- `findViewById` 用法（用于 ViewBinding）
- 静态方法和字段（需要 `@JvmStatic` / `@JvmField` 供 Java 调用方使用）

## 步骤 3：检测 ViewBinding 支持

检查基类链中的 ViewBinding 模式：

- `BaseBindingActivity<T : ViewBinding>` 或类似的带 `mBinding` 属性的泛型基类
- `BaseActivity<T : ViewBinding>` — 本项目的基类需要类型参数
- `BaseFragment<T : ViewBinding>` 带 `mBinding` 属性

**如果支持 ViewBinding：**
1. 将所有 `findViewById` 调用映射到 binding 属性名
2. 移除 `findViewById` 调用，改用 `mBinding.propertyName`
3. 移除仅存储 `findViewById` 结果的字段
4. 重写 `getBinding()` 方法返回膨胀的 binding

**如果不支持 ViewBinding（例如工具类、适配器）：**
1. 转换为基类时使用 `BaseActivity<*>` 星投影
2. 保留 `findViewById` 但转换为 Kotlin 语法
3. 使用 `lateinit var` 用于稍后初始化的视图字段

## 步骤 4：将 Java 转换为 Kotlin

### 语法转换

| Java | Kotlin |
|------|--------|
| `private String name;` | `private var name: String? = null` |
| `final String name = "test";` | `val name: String = "test"` |
| `public void doSomething() { }` | `fun doSomething() { }` |
| `text.getText().toString()` | `text.text.toString()` |
| `view.setOnClickListener(new View.OnClickListener() { ... })` | `view.setOnClickListener { ... }` |
| `list.get(0)` | `list[0]` |
| `map.put("key", value)` | `map["key"] = value` |
| `entity.getXxx()` / `entity.setXxx(v)` | `entity.xxx` / `entity.xxx = v` |
| `instanceof Type` | `is Type` |
| `(Type) instance` | `instance as Type` |
| `switch (x) { case 1: ... }` | `when (x) { 1 -> ... }` |
| `String.format("%02d:%02d", m, s)` | `"%02d:%02d".format(m, s)` |
| `new ArrayList<>()` | `mutableListOf<T>()` |
| `Arrays.asList(a, b, c)` | `listOf(a, b, c)` |
| `new HashMap<>()` | `mutableMapOf<K, V>()` |

### 空安全 — 关键

**绝对禁止使用 `!!`（非空断言操作符）。** 它会在运行时抛出 `NullPointerException`。

使用安全替代方案：
- `?.` — 安全调用
- `?.let { }` — 安全代码块执行
- `?: defaultValue` — Elvis 运算符提供默认值
- `isNullOrEmpty()` / `isNullOrBlank()` — 字符串检查
- `if (x != null) { }` — 显式空检查（需要时使用）

### 项目特定模式

#### 泛型基类

当基类有类型参数但你不使用 ViewBinding 时：
```kotlin
// 错误 — 编译失败
class MyAdapter : BaseActivity, BaseRecycleAdapter3<...>(...)

// 正确 — 星投影
class MyAdapter : BaseActivity<*>, BaseRecycleAdapter3<...>(...)
```

**⚠️ 关键：Kotlin 中 `BaseActivity` 始终需要类型参数。** 这适用于：
- 构造函数参数：`mContext: BaseActivity<*>`
- 强制类型转换：`mContext as BaseActivity<*>`
- 类型声明：`val activity: BaseActivity<*>`
- 超类声明：`class MyActivity : BaseActivity<Nothing>()`

Java 编译器自动接受原始类型（如 `BaseActivity`），但 Kotlin 不会。Kotlin 中每个对 `BaseActivity` 的引用都**必须**包含 `<*>`（或显式类型参数）。

**⚠️ 关键规则：Kotlin 中引用任何带泛型参数的 Java 类时，必须显式传递星投影。** 常见遗漏位置：
1. 构造函数参数声明：`fun Foo(mContext: BaseActivity<*>, ...)`
2. `as` 强制类型转换：`mContext as BaseActivity<*>`
3. `is` 类型检查：`if (obj is BaseActivity<*>)`
4. 变量声明：`val ctx: BaseActivity<*>? = null`
5. 泛型容器中的类型参数：`List<BaseActivity<*>>`

**排查方法：** 编译报错 `One type argument expected` 时，搜索所有 `BaseActivity` 引用（不带 `<` 的），逐一添加 ` <*>`。

#### Kotlin Object 单例（从 Kotlin 访问）

当 Java 类调用 Kotlin `object` 单例时：
```java
// Java
SpUtil.INSTANCE.getInt("key");
SpUtil.INSTANCE.putInt("key", value);
```
```kotlin
// Kotlin — 不需要 .INSTANCE
SpUtil.getInt("key")
SpUtil.putInt("key", value)
```

**Kotlin 基类的私有字段可能遮蔽同名 Java 风格 getter。** 例如基类同时声明
`private var rxManager` 和公开方法 `fun getRxManager()` 时，子类中写 `rxManager`
会尝试访问不可见私有字段并编译失败。此类场景必须显式调用 `getRxManager()`，
不要依赖 Kotlin 合成属性语法。

#### 单例模式（供 Java 调用方使用）

当转换同时被 Java 和 Kotlin 调用的 Java 单例时：
```kotlin
class MyClass private constructor() {
    companion object {
        @Volatile
        private var instance: MyClass? = null

        @JvmStatic  // Java 调用方需要：MyClass.getInstance()
        fun getInstance(): MyClass =
            instance ?: synchronized(this) {
                instance ?: MyClass().also { instance = it }
            }
    }
}
```

#### 使用 @Parcelize 的 Parcelable

本项目有 `kotlin-parcelize` 插件。优先使用 `@Parcelize data class` 而非手动实现 Parcelable：
```kotlin
@Parcelize
data class MyBean(
    var number: String? = null,
    var uppercase: String? = null
) : Parcelable
```
如果类继承了实现 `Parcelable` 的 Java `BaseEntity`，直接使用 `Parcelable` — `@Parcelize` 会处理一切。

#### 适配器基类

`BaseRecycleAdapter3<T, E>` 有可以从 Kotlin 子类直接访问的 `protected` Java 字段：
- `mContext` — Activity
- `mList` — 数据列表
- `mOnItemClickListener` — 点击监听器（可空）

在 Kotlin 中直接访问：
```kotlin
override fun onBindViewHolder(vh: VH, position: Int) {
    val item = mList[position]
    mOnItemClickListener?.onItemClick(vh.itemView, position, item)
}
```

### 常见模式

**RxJava 订阅：**
```kotlin
// 使用属性访问替代 getter
rxManager.add(subscription)
```

**Lambda 转换：**
```kotlin
// Java 匿名类 → Kotlin lambda
view.setOnClickListener {
    // 代码
}
```

**内部类：**
- Java 中的 `static class` → Kotlin 中的 `class`（默认为嵌套类）
- Java 中的 `class` → Kotlin 中的 `inner class`（需要 `inner` 关键字）

### ViewBinding 特定

当转换为使用 ViewBinding 时：

1. 从 `initView()` 或构造函数中移除 `findViewById` 调用
2. 移除仅存储 `findViewById` 结果的字段
3. 使用 `mBinding.propertyName` 进行所有视图访问
4. 重写 `getBinding()` 方法返回膨胀的 binding
5. 更新 `initView()` 使用 binding 引用

```kotlin
// Kotlin with ViewBinding
override fun initView() {
    super.initView()
    mBinding.title.text = "Hello"
    mBinding.icon.setImageResource(R.drawable.ic_star)
}
```

## 步骤 5：删除原始文件

1. 删除 `.java` 文件

## 步骤 6：代码规范化与编译验证

1. 调用 `$code-normalize` 检查转换后的 Kotlin 类及本次修改的 Java/Kotlin 调用方。
2. 规范成员命名、补充缺失类注释和关键成员注释，同时保持公共 API、序列化字段和框架契约兼容。
3. 禁止在此处自行实现 `$code-normalize` 的规则，也禁止让其反向调用本技能。
4. 运行编译：
```bash
./gradlew :module:compileDebugKotlin
```

如果编译失败：
1. 仔细阅读错误信息
2. 常见问题：
   - 方法签名中 `View?` vs `View`（匹配基类）
   - `getIntent().getStringExtra()` 等的可空返回类型
   - 基类缺少泛型类型参数
   - `when` vs `if-else` 表达式的穷尽性
   - 从 Kotlin 访问 Kotlin object 的 `INSTANCE`（移除 `.INSTANCE`）
3. 修复错误并重新编译直到成功

### 转换后检查清单

- [ ] 包和导入正确
- [ ] 所有调用方仍然编译（Java 和 Kotlin）
- [ ] 单例方法被 Java 调用时添加了 `@JvmStatic`
- [ ] 有默认参数的方法被 Java 调用时添加了 `@JvmOverloads`
- [ ] 泛型基类在不需要类型参数时使用了星投影 `*`
- [ ] 任何地方都没有使用 `!!` 操作符
- [ ] `$code-normalize` 已完成且未遗留不合规成员名称
- [ ] 原始 `.java` 文件已删除
- [ ] `./gradlew :module:compileDebugKotlin` 通过

## 步骤 8：技能进化

转换完成并验证后，必须调用 `$skill-common` 复盘本技能；本技能不重复保存进化门槛和依赖去重策略。

## 示例

详见 [references/examples.md](references/examples.md) 的完整转换示例：
- 带 ViewBinding 的简单 Activity
- 带基类的 RecyclerView 适配器
- RxJava 订阅模式
- 带回调的 Dialog
- 工具类 / 单例
- 使用 @Parcelize 的 Parcelable 实体
