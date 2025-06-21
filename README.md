# Bing Wallpaper - 每日壁纸悦览 (HarmonyOS)

一款基于华为 HarmonyOS NEXT 和 ArkTS 语言开发的壁纸应用。它以简洁优雅的界面，每日为您呈现来自 Bing 的精美壁纸，并提供丰富的浏览和管理功能。


---

## ✨ 功能特性

- **每日壁纸精选**: 自动获取并以大卡片形式展示当天的 Bing 壁纸。
- **历史壁纸画廊**: 流畅浏览过去10天的历史壁纸。
- **双重布局模式**: 支持在紧凑的**网格视图**和信息更丰富的**列表视图**之间一键切换。
- **沉浸式详情页**:
  - 全屏预览壁纸，享受无干扰的视觉体验。
  - 底部悬浮操作栏，提供核心功能。
- **核心交互**:
  - **下载壁纸**: 一键将高清壁纸保存到您的设备相册中。
  - **设置壁纸**: 引导用户将心仪的图片设置为系统壁纸。
  - **壁纸故事**: 通过信息弹窗，了解每张壁纸背后的故事和版权信息。
- **现代化UI/UX**:
  - 采用 ArkUI 声明式 UI 框架，界面美观现代。
  - 包含流畅的加载动画和响应式布局。
  - 自定义SVG图标，保证视觉效果的一致性。

---

## 🚀 技术实现与原理剖析

本项目完全采用 **ArkTS** 语言和 **ArkUI** 声明式UI框架构建，充分利用了 HarmonyOS 的新特性。

### 1. 项目架构

- **语言**: ArkTS (基于 TypeScript)
- **UI框架**: ArkUI
- **应用结构**:
  - `Index.ets`: 应用主页面，负责展示壁纸列表和历史画廊。
  - `DetailPage.ets`: 壁纸详情页，提供全屏预览和交互功能。
  - `resources`: 存放应用的静态资源，如自定义的SVG图标。

### 2. 核心逻辑 - 主界面 (`Index.ets`)

#### a. 状态驱动的UI

我们使用 `@State` 装饰器来管理界面的核心状态，当这些状态变量改变时，UI会自动刷新。
- `@State wallpapers: WallpaperEntry[]`: 存储从API获取的所有壁纸数据。
- `@State isLoading: boolean`: 控制加载动画的显示与隐藏。
- `@State layoutMode: 'grid' | 'list'`: 控制历史壁纸区域的布局模式（网格或列表）。

#### b. API 数据请求与解析

`fetchBingWallpapers` 函数是应用的数据核心。
1.  **网络请求**: 使用 HarmonyOS 提供的 `net.http` 模块，向 Bing 的公开API (`https://www.bing.com/HPImageArchive.aspx`) 发起 GET 请求，获取最近10天的壁纸数据。
2.  **类型安全**: 为了保证代码的健壮性和可维护性，我们定义了 `BingApiResponse`, `BingImage`, 和 `WallpaperEntry` 等多个 `interface`。这使得从 `JSON.parse` 返回的 `any` 类型数据可以被强制转换为我们期望的结构，有效避免了在运行时可能出现的类型错误。
3.  **数据映射**: 使用数组的 `.map()` 方法，将原始的API数据 (`BingImage[]`) 转换并映射为应用内部使用的数据结构 (`WallpaperEntry[]`)。

#### c. 动态布局切换

这是本应用的一个核心交互功能，其实现原理是**条件渲染**。
- 我们在 `build()` 函数中通过一个 `if...else` 语句来检查 `@State layoutMode` 的值。
- 如果值为 `'grid'`，则渲染一个 `Grid` 组件。
- 如果值为 `'list'`，则渲染一个 `List` 组件。
- 布局切换按钮的 `onClick` 事件会改变 `layoutMode` 的值，从而触发UI的自动重建，实现视图的无缝切换。

#### d. 组件化思想

为了提高代码的复用性和可读性，我们将历史壁纸的列表项抽象成了一个独立的组件 `HistoryListItem`。
- 使用 `@Component` 装饰器定义该组件。
- 使用 `@Prop` 装饰器来声明 `item` 属性，表示这个属性的值是由其父组件传递进来的，这实现了父子组件之间的数据单向传递。

### 3. 核心逻辑 - 详情页 (`DetailPage.ets`)

#### a. 全屏沉浸式布局

详情页的布局使用了 `Stack` 组件，它允许组件像图层一样堆叠。
1.  **背景层**: `Image` 组件作为最底层，设置 `width('100%')` 和 `height('100%')`，实现全屏展示。
2.  **UI层**: 一个全屏的 `Column` 组件覆盖在背景层之上，用于承载顶部的返回按钮和底部的操作栏。

#### b. 触摸事件处理 (按钮可点击的关键)

这是一个非常关键的技术点。为了解决UI按钮被背景图片遮挡而无法点击的问题，我们运用了 `hitTestBehavior` 属性：
- **背景图片**: 我们为其设置了 `.hitTestBehavior(HitTestMode.None)`。这告诉系统，该图片自身不参与任何触摸事件的命中测试，点击事件可以"穿透"它。
- **UI容器**: 我们为承载按钮的 `Column` 容器设置了 `.hitTestBehavior(HitTestMode.Default)` (或不设置，因为这是默认值)，确保它能正常接收并响应用户的点击事件。

#### c. 文件系统与权限管理

`downloadWallpaper` 函数整合了权限申请、文件下载和媒体库更新的全流程。
1.  **权限申请**: 使用 `abilityAccessCtrl` 模块，在下载前检查应用是否拥有 `ohos.permission.WRITE_MEDIA` 权限。如果没有，则会调用 `requestPermissionsFromUser` 向用户发起授权请求。
2.  **文件下载**: 同样使用 `net.http` 下载图片，但这次我们请求的是原始的图片数据，并将其作为 `ArrayBuffer` 接收。
3.  **文件保存**: 使用 `fs` (File System) 模块，在应用的缓存目录 (`context.cacheDir`) 中创建一个临时文件，并将 `ArrayBuffer` 写入该文件。
4.  **媒体库更新**: 调用 `media.addImage(filePath)` API，将刚刚保存的图片文件添加到系统的公共媒体库中。这样，用户就可以在"图库"应用中找到下载的壁纸了。

#### d. 底部信息弹窗 (`Sheet`)

为了以一种非侵入的方式展示壁纸的详细信息，我们使用了 `.sheet()` 修饰器。
- 它与一个 `@Builder` 装饰的函数 (`wallpaperBuilder`) 绑定，该函数负责构建弹窗内的UI。
- 弹窗的显示与隐藏由一个布尔类型的状态变量 `infoSheetIsShow` 控制，实现了优雅的交互体验。

---

## 🛠️ 如何运行

### 先决条件

-   安装最新版本的 [DevEco Studio](https://developer.harmonyos.com/cn/develop/deveco-studio/)。
-   配置好 HarmonyOS SDK。

### 步骤

1.  克隆本仓库到本地:
    ```bash
    git clone https://github.com/YOUR_USERNAME/bing-wallpaper-harmonyos.git
    ```
2.  在 DevEco Studio 中打开项目。
3.  **重要**: 配置应用权限。
    -   打开 `entry/src/main/module.json5` 文件，在 `requestPermissions` 数组中添加网络和媒体写入权限：
        ```json
        "requestPermissions": [
          {
            "name": "ohos.permission.INTERNET"
          },
          {
            "name": "ohos.permission.WRITE_MEDIA"
          }
        ]
        ```
4.  连接真机或启动模拟器。
5.  点击 DevEco Studio 工具栏中的 "Run" 按钮来编译和运行应用。

---

## 💡 未来可拓展的功能

-   **数据缓存**: 增加本地缓存机制，缓存API响应和图片，减少不必要的网络请求，提升启动速度。
-   **壁纸自动更换**: 开发后台服务，实现每日自动更换系统壁纸的功能。
-   **主题切换**: 增加浅色/深色主题切换功能。
-   **收藏夹**: 允许用户收藏喜欢的壁纸。
-   **历史壁纸分页加载**: 当用户滚动到列表底部时，加载更早的历史壁纸。

---

## 致谢

感谢 Bing 提供稳定且高质量的每日壁纸API。

希望这份文档能对您有所帮助！ 
