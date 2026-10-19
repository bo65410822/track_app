# Android 设计决策

## 模块概述

本文档记录轨迹记 Android 平台已经确认、需要跨会话保留的技术决策。产品范围和里程碑仍以 `产品设计文档.md` 为准。

### AND-001 Android 应用包名

- 状态：已确认
- 决定：Android 的 `namespace` 和 `applicationId` 统一使用 `com.zhanbo.track`。
- 理由：该标识简洁、符合 Android 反向域名命名习惯，并与轨迹产品名称一致；在接入高德 Key、签名和应用商店前固定，可以避免后续迁移成本。
- 约束/影响：高德 Android Key 必须绑定此包名；发布后不应修改。`MainActivity` 的包声明及目录需要保持一致。
- 日期：2026-10-16

### AND-002 高德地图 Flutter 插件

- 状态：已确认
- 决定：地图能力使用 `amap_map: ^1.0.15`，并临时将 `flutter_plugin_android_lifecycle` 固定为 `2.0.26`。
- 理由：产品设计文档原定的官方 `amap_flutter_map: 3.0.0` 最后发布于 2021 年，其 Android 构建仍依赖已被 Gradle 9 移除的 `jcenter()` 和 Android Gradle Plugin 3.5，无法在当前 Flutter 3.47.7 / Gradle 9.3.1 工具链中构建。`amap_map` 使用较新的高德原生 SDK，支持当前所需的地图、定位和轨迹绘制能力；固定生命周期插件版本用于解决 `amap_map` 的 `compileSdk 35` 与最新版生命周期插件要求 `compileSdk 36` 的冲突。
- 约束/影响：此决定替代 `产品设计文档.md` 第 107 行的 `amap_flutter_map` 地图插件选型，但不改变使用高德地图、GCJ-02 坐标系和 Android 优先的产品方向。后续 `amap_map` 升级并支持 `compileSdk 36+` 后，应移除 `dependency_overrides` 并重新验证构建。
- 日期：2026-10-16

