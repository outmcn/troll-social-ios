# TrollSocial

原生 SwiftUI 社交 App，目标为 TrollStore 可安装 IPA。

## 当前版本
- 主页、广场、聊天、我的四个 Tab
- 中间 + 发布动态
- 本地演示数据与交互
- API 官网配置为 `https://chat.outmcn.net`
- 我的页面显示 API 服务状态

## API 说明
当前已加入官方 API 基础地址和 `/api/health` 健康检查。由于现场访问 `https://chat.outmcn.net` 当前返回 HTTP 502，动态、聊天和用户数据仍使用本地演示数据，未伪造在线状态。待 API 服务恢复并确认接口协议后，再接入真实业务接口。

## 构建
GitHub Actions 使用 macOS-15、XcodeGen 和 Xcode，目标 iOS 16.0。
