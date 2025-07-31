# Garmin Connect IQ 五行配色表盘发布指南

本文档详细介绍了从编译到发布五行配色表盘到 Garmin Connect IQ Store 的完整流程。

## 目录

1. [前置准备](#前置准备)
2. [项目验证](#项目验证)
3. [编译应用](#编译应用)
4. [本地测试](#本地测试)
5. [生成发布包](#生成发布包)
6. [Connect IQ Store 发布](#connect-iq-store-发布)
7. [审核流程](#审核流程)
8. [发布后管理](#发布后管理)
9. [故障排除](#故障排除)

## 前置准备

### 1. 开发环境检查

确保已安装并配置以下工具：

```bash
# 检查 Connect IQ SDK
which monkeyc
which monkeydo
which connectiq

# 检查版本
monkeyc --version
connectiq --version
```

### 2. 开发者账户注册

1. 访问 [Garmin Developer Portal](https://developer.garmin.com/)
2. 创建 Garmin Developer Account
3. 完成身份验证（需年满18岁）
4. 接受 Connect IQ Developer Agreement

### 3. 项目文件检查

确认以下关键文件存在且配置正确：

- ✅ `manifest.xml` - 应用清单文件
- ✅ `monkey.jungle` - 构建配置文件
- ✅ `developer_key` - 开发者密钥
- ✅ `source/` - 源代码目录
- ✅ `resources/` - 资源文件目录

## 项目验证

### 1. 运行项目验证脚本

```bash
cd /Users/zengqiuyan/Documents/workspace/aispace/garmin-IQ/five-color
./build.sh validate
```

### 2. 检查应用配置

#### manifest.xml 关键配置

```xml
<iq:application 
    entry="FiveElementWatchFaceApp" 
    id="3da6f597e8ba4feafbc4150f862228a3" 
    name="@Strings.AppName" 
    type="watchface" 
    version="1.0.0"
    minSdkVersion="3.0.0">
    
    <!-- 支持的设备列表 -->
    <iq:products>
        <iq:product id="fr965"/>
        <iq:product id="fr255"/>
        <iq:product id="fr265"/>
        <iq:product id="fr265s"/>
        <iq:product id="venu3"/>
        <iq:product id="venu3s"/>
        <iq:product id="vivoactive5"/>
        
        <iq:product id="fr570"/>
    </iq:products>
    
    <!-- 权限配置 -->
    <iq:permissions>
        <iq:uses-permission id="Positioning"/>
        <iq:uses-permission id="SensorHistory"/>
        <iq:uses-permission id="UserProfile"/>
    </iq:permissions>
    
    <!-- 支持语言 -->
    <iq:languages>
        <iq:language>eng</iq:language>
        <iq:language>zho</iq:language>
    </iq:languages>
</iq:application>
```

#### 应用信息确认

- **应用名称**: 五行配色表盘
- **应用类型**: 表盘 (watchface)
- **版本号**: 1.0.0
- **支持设备**: 10款设备
- **支持语言**: 英文、中文

## 编译应用

### 1. 清理构建环境

```bash
./build.sh clean
```

### 2. 编译调试版本

```bash
./build.sh debug
```

输出文件：`bin/FiveElementWatchFace_debug.prg`

### 3. 编译发布版本

```bash
./build.sh release
```

输出文件：`bin/FiveElementWatchFace.iq`

## 本地测试

### 1. 模拟器测试

```bash
# 启动模拟器
./build.sh simulator

# 部署到模拟器
./build.sh deploy
```

### 2. 真机测试（可选）

```bash
# 生成特定设备的PRG文件
monkeyc -f monkey.jungle -o bin/FiveElementWatchFace_fr965.prg -y developer_key -d fr965

# 将PRG文件复制到设备APPS目录
cp bin/FiveElementWatchFace_fr965.prg /Volumes/GARMIN/APPS/
```

### 3. 测试检查清单

- [ ] 表盘正常显示时间和日期
- [ ] 五行配色功能正常工作
- [ ] 数据字段（心率、步数等）正确显示
- [ ] 设置菜单可正常访问
- [ ] 多语言切换正常
- [ ] 在不同设备上显示正常
- [ ] 内存使用在合理范围内
- [ ] 电池消耗正常

## 生成发布包

### 1. 使用 Visual Studio Code 生成 IQ 文件

如果使用 VS Code 和 Monkey C 扩展：

1. 打开项目文件夹
2. 按 `Cmd+Shift+P` 打开命令面板
3. 输入 `Monkey C: Export Project`
4. 选择要包含的设备和语言
5. 点击 `Finish` 生成 `.iq` 文件

### 2. 使用命令行生成 IQ 文件

```bash
# 生成包含所有支持设备的IQ文件
monkeyc -f monkey.jungle -o bin/FiveElementWatchFace.iq -w -y developer_key -r
```

### 3. 验证 IQ 文件

```bash
# 检查文件大小和内容
ls -lh bin/FiveElementWatchFace.iq
file bin/FiveElementWatchFace.iq

# IQ文件实际上是ZIP格式，可以查看内容
unzip -l bin/FiveElementWatchFace.iq
```

## Connect IQ Store 发布

### 1. 登录开发者门户

1. 访问 [Connect IQ Store Developer Portal](https://apps.garmin.com/developer)
2. 使用 Garmin Developer Account 登录

### 2. 上传应用

1. 点击 "Submit an App" 或 "Upload New App"
2. 选择应用类型：**Watch Face**
3. 上传 `bin/FiveElementWatchFace.iq` 文件
4. 等待文件验证完成

### 3. 填写应用信息

#### 基本信息
- **应用名称**: 五行配色表盘 / Five Element Color Watch Face
- **简短描述**: 基于中国传统五行理论的智能配色表盘
- **详细描述**:
  ```
  五行配色表盘是一款基于中国传统五行理论（金、木、水、火、土）的智能表盘应用。
  
  主要功能：
  • 根据五行理论自动调整表盘配色
  • 显示时间、日期、星期
  • 实时显示心率、步数、电池电量
  • 支持中英文双语显示
  • 个性化设置选项
  • 优雅的传统文化设计
  
  支持设备：Forerunner 965/255/265/245/235/570, Venu 3/3S, Vivoactive 5
  
  体验传统文化与现代科技的完美融合！
  ```

#### 分类和标签
- **主分类**: Watch Faces
- **子分类**: Analog 或 Digital（根据设计选择）
- **标签**: Traditional, Chinese Culture, Five Elements, Colorful

#### 截图和媒体
- 准备不同设备的表盘截图（至少3-5张）
- 图片要求：PNG格式，高质量，展示主要功能
- 可选：制作宣传视频

#### 定价设置
- **免费应用**: 选择 Free
- **付费应用**: 设置价格（如 $1.99 - $4.99）

### 4. 设置支持信息

- **开发者联系邮箱**: 提供技术支持邮箱
- **隐私政策**: 如果收集用户数据需要提供
- **用户手册**: 可选，提供使用说明

### 5. 提交审核

1. 检查所有信息填写完整
2. 确认应用符合 [Connect IQ App Review Guidelines](https://developer.garmin.com/connect-iq/app-review-guidelines/)
3. 点击 "Submit for Review"

## 审核流程

### 1. 审核阶段

1. **文件验证** (即时)
   - 检查 IQ 文件格式
   - 验证数字签名
   - 检查支持设备

2. **内容审核** (1-7个工作日)
   - 功能测试
   - 用户体验评估
   - 合规性检查
   - 性能测试

3. **最终审批** (1-3个工作日)
   - 最终质量检查
   - 发布准备

### 2. 审核标准

#### 功能要求
- [ ] 应用功能正常，无崩溃
- [ ] 用户界面友好，易于使用
- [ ] 性能良好，响应及时
- [ ] 内存使用合理
- [ ] 电池消耗可接受

#### 内容要求
- [ ] 无违法、有害内容
- [ ] 无侵犯版权内容
- [ ] 描述准确，无误导信息
- [ ] 截图真实反映应用功能

#### 技术要求
- [ ] 符合 Connect IQ API 规范
- [ ] 正确使用权限
- [ ] 兼容声明的设备
- [ ] 支持声明的语言

### 3. 审核结果处理

#### 审核通过
- 收到邮件通知
- 应用在 Connect IQ Store 上线
- 用户可以搜索和下载

#### 审核被拒
- 收到详细的拒绝原因
- 根据反馈修改应用
- 重新提交审核

## 发布后管理

### 1. 监控应用表现

- **下载量统计**: 查看开发者门户数据
- **用户评价**: 关注用户反馈和评分
- **崩溃报告**: 监控应用稳定性
- **性能指标**: 关注内存和电池使用

### 2. 版本更新

#### 更新流程
1. 修改 `manifest.xml` 中的版本号
2. 重新编译生成新的 IQ 文件
3. 在开发者门户上传新版本
4. 填写更新说明
5. 提交审核

#### 版本号规范
- **主版本号**: 重大功能变更 (1.0.0 → 2.0.0)
- **次版本号**: 新功能添加 (1.0.0 → 1.1.0)
- **修订号**: Bug修复 (1.0.0 → 1.0.1)

### 3. 用户支持

- 及时回复用户评论和问题
- 提供技术支持邮箱
- 维护用户手册和FAQ
- 收集用户建议用于改进

## 故障排除

### 1. 编译问题

#### 问题：编译失败
```bash
# 检查SDK路径
echo $PATH
which monkeyc

# 检查开发者密钥
ls -la developer_key
file developer_key

# 检查项目文件
./build.sh validate
```

#### 问题：设备不支持
- 检查 `manifest.xml` 中的设备ID
- 确认设备SDK版本兼容性
- 查看设备特定的资源文件

### 2. 上传问题

#### 问题：IQ文件被拒绝
- 确认文件格式正确（.iq扩展名）
- 检查文件大小（通常不超过10MB）
- 验证数字签名
- 确认包含所有必要的设备文件

#### 问题：验证失败
```bash
# 重新生成IQ文件
./build.sh clean
./build.sh release

# 检查生成的文件
unzip -t bin/FiveElementWatchFace.iq
```

### 3. 审核问题

#### 常见拒绝原因
1. **功能问题**
   - 应用崩溃或无响应
   - 功能不完整或有Bug
   - 性能问题（内存泄漏、电池消耗过大）

2. **用户体验问题**
   - 界面设计不友好
   - 操作复杂或不直观
   - 缺少必要的用户指导

3. **内容问题**
   - 描述与实际功能不符
   - 截图不真实或质量差
   - 包含不当内容

4. **技术问题**
   - 不符合API规范
   - 权限使用不当
   - 设备兼容性问题

#### 解决策略
1. 仔细阅读拒绝原因
2. 逐项修复问题
3. 在模拟器和真机上充分测试
4. 更新应用描述和截图
5. 重新提交审核

### 4. 发布后问题

#### 用户报告Bug
1. 收集详细的错误信息
2. 在相同设备上复现问题
3. 修复Bug并测试
4. 发布更新版本

#### 兼容性问题
1. 检查新设备的支持
2. 更新设备列表
3. 适配新的SDK版本
4. 测试向后兼容性

## 最佳实践建议

### 1. 开发阶段
- 遵循 Garmin 设计指南
- 优化性能和内存使用
- 充分测试所有支持的设备
- 实现优雅的错误处理
- 添加详细的代码注释

### 2. 发布准备
- 准备高质量的应用截图
- 编写清晰的应用描述
- 制作用户手册或帮助文档
- 设置合理的价格策略
- 准备营销材料

### 3. 发布后维护
- 定期更新应用
- 及时修复用户报告的问题
- 关注用户反馈和建议
- 保持与Garmin生态系统的兼容性
- 考虑添加新功能和改进

## 相关资源

- [Garmin Connect IQ Developer Portal](https://developer.garmin.com/connect-iq/)
- [Connect IQ Store](https://apps.garmin.com/)
- [App Review Guidelines](https://developer.garmin.com/connect-iq/app-review-guidelines/)
- [SDK Documentation](https://developer.garmin.com/connect-iq/api-docs/)
- [Developer Forums](https://forums.garmin.com/developer/connect-iq/)

---

**注意**: 本指南基于当前的 Garmin Connect IQ 平台政策和流程。政策可能会发生变化，请定期查看官方文档获取最新信息。

**版本**: 1.0.0  
**更新日期**: 2024年1月  
**适用项目**: 五行配色表盘 v1.0.0