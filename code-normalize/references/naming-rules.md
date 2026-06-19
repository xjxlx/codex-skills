# Java/Kotlin 成员命名规则

## 成员分类

修改前必须对每个声明进行分类：

| 类型 | 规范形式 | 示例 |
|---|---|---|
| 实例属性或字段 | `lowerCamelCase` | `selectedCourseId` |
| Boolean 属性 | 判断式 `lowerCamelCase` | `isDialogVisible` |
| 编译期常量 | `UPPER_SNAKE_CASE` | `DEFAULT_TIMEOUT_SECONDS` |
| 可变集合 | 复数或领域名词 | `courseItems` |
| 回调或监听器 | 角色 + `Listener`/`Callback` | `unlockListener` |
| 计时器、Job、订阅 | 角色 + 类型 | `viewingTimer`、`loadJob` |
| ViewBinding 引用 | 遵循仓库约定 | `binding`、`mBinding` |

## 不规范特征

以下特征表示成员可能需要修改，但不能直接机械替换：

- snake_case 字段：`user_name`、`a_b`
- 含义不清的缩写：`bname`、`bbirthday`、`cnt`、`idx`
- 匈牙利命名或类型前缀：`mName`、`strTitle`、`lstUsers`
- 模糊状态名：`flag`、`status`、`data`、`info`、`temp`、`obj`
- 数字后缀名称：`text1`、`value2`、`list3`
- 类型改变后仍保留的误导性后缀
- 集合使用单数名称，或单个值使用复数名称
- 数字缺少单位：应使用 `timeoutMillis`，而不是 `timeout`

## 语义推断顺序

按以下顺序推断新名称：

1. 服务端/API 字段文档或映射注解
2. UI 文案和资源 ID
3. getter/setter 名称和方法参数
4. 赋值来源和判断逻辑
5. 调用方和下游使用者
6. 附近注释和项目已有领域词汇

只有原名称本身已有明确含义时，才能只做命名格式转换，例如 `user_id` 改为 `userId`。
对于 `a_b` 这类不透明名称，应继续调查，禁止直接改成 `aB`。

## 缩写规则

优先遵循仓库已有风格。没有明确约定时：

- 使用 `userId`，不使用 `userID`
- 使用 `apiUrl`，不使用 `APIURL`
- 使用 `htmlContent`、`jsonBody`、`httpClient`
- 常量可以使用 `API_URL`

## 兼容性模式

### Gson

```kotlin
@SerializedName("bname")
var babyName: String? = null
```

### Room

```kotlin
@ColumnInfo(name = "a_b")
val accountBalance: Long
```

### JavaBean API

如果外部 Java 代码依赖 `getBname()`，应保留访问器名称，或者将重命名视为公共 API 迁移并编译所有调用方。
只重命名私有后备字段且保持 getter/setter 不变时，通常可以维持兼容。

## 成员注释判定

满足以下任意条件时，应添加成员注释：

- 状态会跨生命周期回调变化
- 值会被多个方法或线程共享
- 值会控制页面跳转、权限、计时或用户可见行为
- 值具有不明显的单位或特殊值
- 引用必须释放才能避免泄漏
- 集合顺序或元素含义具有业务要求

禁止添加只复述声明内容的注释。
