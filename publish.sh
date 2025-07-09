#!/bin/bash

# Garmin Connect IQ 五行配色表盘发布脚本
# 自动化编译、验证和准备发布包的流程

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_NAME="FiveElementWatchFace"
APP_NAME="五行配色表盘"
VERSION=$(grep -o 'version="[^"]*"' manifest.xml | tail -1 | cut -d'"' -f2)
DEVELOPER_KEY="developer_key.der"
JUNGLE_FILE="monkey.jungle"
BIN_DIR="bin"
OUTPUT_IQ="${BIN_DIR}/${PROJECT_NAME}.iq"

# SDK路径配置 - 使用与build.sh相同的SDK版本
SDK_PATH="/Users/zengqiuyan/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.2.1-2025-06-19-f69b94140"
API_DB="$SDK_PATH/bin/api.db"
PROJECT_INFO="$SDK_PATH/bin/projectInfo.xml"

# 设置PATH环境变量
export PATH="$SDK_PATH/bin:$PATH"

# 支持的设备列表
DEVICES=("fr965" "fr255" "fr265" "fr265s" "venu3" "venu3s")

# 函数：打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 函数：检查必要的工具
check_tools() {
    print_info "检查开发工具..."
    
    if ! command -v monkeyc &> /dev/null; then
        print_error "monkeyc 未找到，请安装 Connect IQ SDK"
        exit 1
    fi
    
    if ! command -v connectiq &> /dev/null; then
        print_error "connectiq 未找到，请安装 Connect IQ SDK"
        exit 1
    fi
    
    print_success "开发工具检查完成"
    print_info "SDK 版本: $(monkeyc --version)"
}

# 函数：验证项目文件
validate_project() {
    print_info "验证项目文件..."
    
    # 检查必要文件
    local required_files=("manifest.xml" "$JUNGLE_FILE" "$DEVELOPER_KEY")
    for file in "${required_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            print_error "缺少必要文件: $file"
            exit 1
        fi
    done
    
    # 检查源代码目录
    if [[ ! -d "source" ]]; then
        print_error "缺少源代码目录: source/"
        exit 1
    fi
    
    # 检查资源目录
    if [[ ! -d "resources" ]]; then
        print_warning "缺少资源目录: resources/"
    fi
    
    print_success "项目文件验证完成"
}

# 函数：显示项目信息
show_project_info() {
    print_info "项目信息:"
    echo "  应用名称: $APP_NAME"
    echo "  项目名称: $PROJECT_NAME"
    echo "  版本号: $VERSION"
    echo "  支持设备: ${#DEVICES[@]} 款"
    echo "  设备列表: ${DEVICES[*]}"
    echo ""
}

# 函数：清理构建目录
clean_build() {
    print_info "清理构建目录..."
    
    if [[ -d "$BIN_DIR" ]]; then
        rm -rf "$BIN_DIR"
    fi
    
    mkdir -p "$BIN_DIR"
    print_success "构建目录清理完成"
}

# 函数：编译调试版本
build_debug() {
    print_info "编译调试版本..."
    
    local debug_output="${BIN_DIR}/${PROJECT_NAME}_debug.prg"
    
    if monkeyc -f "$JUNGLE_FILE" -o "$debug_output" -y "$DEVELOPER_KEY" -d fr965 -w; then
        print_success "调试版本编译完成: $debug_output"
        
        # 显示文件信息
        local file_size=$(ls -lh "$debug_output" | awk '{print $5}')
        print_info "文件大小: $file_size"
    else
        print_error "调试版本编译失败"
        exit 1
    fi
}

# 函数：编译发布版本
build_release() {
    print_info "编译发布版本 (IQ文件)..."
    
    if monkeyc -f "$JUNGLE_FILE" -o "$OUTPUT_IQ" -y "$DEVELOPER_KEY" -w -r; then
        print_success "发布版本编译完成: $OUTPUT_IQ"
        
        # 显示文件信息
        local file_size=$(ls -lh "$OUTPUT_IQ" | awk '{print $5}')
        print_info "文件大小: $file_size"
        
        # 验证IQ文件
        if file "$OUTPUT_IQ" | grep -q "Zip archive"; then
            print_success "IQ文件格式验证通过"
        else
            print_warning "IQ文件格式可能有问题"
        fi
    else
        print_error "发布版本编译失败"
        exit 1
    fi
}

# 函数：编译发布版本用于模拟器测试
build_release_for_simulator() {
    print_info "编译发布版本用于模拟器测试..."
    
    local release_prg="${BIN_DIR}/${PROJECT_NAME}_release.prg"
    
    if monkeyc -f "$JUNGLE_FILE" -o "$release_prg" -y "$DEVELOPER_KEY" -d fr965 -w -r; then
        print_success "模拟器发布版本编译完成: $release_prg"
        
        # 显示文件信息
        local file_size=$(ls -lh "$release_prg" | awk '{print $5}')
        print_info "文件大小: $file_size"
        
        return 0
    else
        print_error "模拟器发布版本编译失败"
        return 1
    fi
}

# 函数：验证IQ文件内容
validate_iq_file() {
    print_info "验证IQ文件内容..."
    
    if [[ ! -f "$OUTPUT_IQ" ]]; then
        print_error "IQ文件不存在: $OUTPUT_IQ"
        exit 1
    fi
    
    # 检查文件基本格式（IQ文件可能不是标准ZIP格式）
    local file_type=$(file "$OUTPUT_IQ")
    print_info "文件类型: $file_type"
    
    # 尝试显示IQ文件内容（如果是ZIP格式）
    print_info "尝试分析IQ文件内容..."
    if unzip -l "$OUTPUT_IQ" &> /dev/null; then
        print_info "IQ文件内容:"
        unzip -l "$OUTPUT_IQ" | head -20
        
        # 检查是否包含所有设备的PRG文件
        local prg_count=$(unzip -l "$OUTPUT_IQ" | grep -c "\.prg$" || true)
        print_info "包含的PRG文件数量: $prg_count"
        
        if [[ $prg_count -eq 0 ]]; then
            print_warning "未找到PRG文件，请检查编译配置"
        fi
    else
        print_warning "IQ文件不是标准ZIP格式，但这可能是正常的"
        print_info "文件大小: $(ls -lh "$OUTPUT_IQ" | awk '{print $5}')"
    fi
    
    print_success "IQ文件验证完成"
}

# 函数：生成发布检查清单
generate_checklist() {
    local checklist_file="${BIN_DIR}/release_checklist.md"
    
    print_info "生成发布检查清单..."
    
    cat > "$checklist_file" << EOF
# 五行配色表盘发布检查清单

## 编译信息
- 应用名称: $APP_NAME
- 版本号: $VERSION
- 编译时间: $(date)
- IQ文件: $OUTPUT_IQ
- 文件大小: $(ls -lh "$OUTPUT_IQ" | awk '{print $5}')

## 发布前检查

### 功能测试
- [ ] 表盘正常显示时间和日期
- [ ] 五行配色功能正常工作
- [ ] 数据字段（心率、步数等）正确显示
- [ ] 设置菜单可正常访问
- [ ] 多语言切换正常
- [ ] 在模拟器上测试通过
- [ ] 在真机上测试通过（如有条件）

### 性能检查
- [ ] 内存使用在合理范围内
- [ ] 电池消耗正常
- [ ] 响应速度良好
- [ ] 无内存泄漏

### 内容准备
- [ ] 应用描述已准备
- [ ] 应用截图已准备（至少3张）
- [ ] 价格策略已确定
- [ ] 支持邮箱已设置

### 技术验证
- [ ] IQ文件格式正确
- [ ] 包含所有支持设备的PRG文件
- [ ] 数字签名有效
- [ ] 符合Connect IQ API规范

## 支持设备列表
$(for device in "${DEVICES[@]}"; do echo "- $device"; done)

## 下一步操作
1. 完成上述检查清单
2. 登录 Garmin Developer Portal
3. 上传 $OUTPUT_IQ 文件
4. 填写应用信息和描述
5. 提交审核

## 相关文件
- 发布指南: PUBLISHING_GUIDE.md
- IQ文件: $OUTPUT_IQ
- 项目配置: manifest.xml
EOF

    print_success "发布检查清单已生成: $checklist_file"
}

# 函数：显示发布信息
show_publish_info() {
    print_info "发布准备完成！"
    echo ""
    echo "📦 发布文件: $OUTPUT_IQ"
    echo "📋 检查清单: ${BIN_DIR}/release_checklist.md"
    echo "📖 发布指南: PUBLISHING_GUIDE.md"
    echo ""
    print_info "下一步操作:"
    echo "1. 查看检查清单并完成所有测试"
    echo "2. 访问 https://apps.garmin.com/developer"
    echo "3. 上传 $OUTPUT_IQ 文件"
    echo "4. 填写应用信息并提交审核"
    echo ""
    print_success "祝您发布顺利！🚀"
}

# 函数：显示帮助信息
show_help() {
    echo "Garmin Connect IQ 五行配色表盘发布脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help       显示帮助信息"
    echo "  -c, --clean      仅清理构建目录"
    echo "  -d, --debug      仅编译调试版本"
    echo "  -r, --release    仅编译发布版本"
    echo "  -s, --simulator  编译发布版本并部署到模拟器"
    echo "  -t, --test       编译发布版本用于模拟器测试"
    echo "  -v, --validate   仅验证项目文件"
    echo "  -i, --info       显示项目信息"
    echo ""
    echo "默认行为: 执行完整的发布准备流程"
    echo ""
    echo "示例:"
    echo "  $0              # 执行完整发布流程"
    echo "  $0 --debug      # 仅编译调试版本"
    echo "  $0 --release    # 仅编译发布版本"
    echo "  $0 --simulator  # 编译发布版本并部署到模拟器"
    echo "  $0 --test       # 编译发布版本用于模拟器测试"
    echo "  $0 --clean      # 清理构建目录"
}

# 主函数
main() {
    echo "🎨 Garmin Connect IQ 五行配色表盘发布脚本"
    echo "================================================"
    echo ""
    
    # 解析命令行参数
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -c|--clean)
            clean_build
            exit 0
            ;;
        -d|--debug)
            check_tools
            validate_project
            clean_build
            build_debug
            exit 0
            ;;
        -r|--release)
            check_tools
            validate_project
            clean_build
            build_release
            validate_iq_file
            exit 0
            ;;
        -s|--simulator)
            check_tools
            validate_project
            clean_build
            build_release_for_simulator
            deploy_release_to_simulator
            exit 0
            ;;
        -t|--test)
            check_tools
            validate_project
            clean_build
            build_release_for_simulator
            exit 0
            ;;
        -v|--validate)
            validate_project
            exit 0
            ;;
        -i|--info)
            show_project_info
            exit 0
            ;;
        "")
            # 执行完整流程
            ;;
        *)
            print_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
    
    # 执行完整的发布准备流程
    check_tools
    validate_project
    show_project_info
    clean_build
    build_debug
    build_release
    validate_iq_file
    generate_checklist
    show_publish_info
}

# 函数：部署发布版本到模拟器
deploy_release_to_simulator() {
    print_info "部署发布版本到模拟器..."
    
    local release_prg="${BIN_DIR}/${PROJECT_NAME}_release.prg"
    
    if [[ ! -f "$release_prg" ]]; then
        print_warning "发布版本PRG文件不存在，正在编译..."
        if ! build_release_for_simulator; then
            print_error "无法编译发布版本用于模拟器"
            exit 1
        fi
    fi
    
    # 检查模拟器是否运行
    if ! pgrep -f "simulator" > /dev/null && ! pgrep -f "connectiq" > /dev/null; then
        print_info "启动模拟器..."
        connectiq &
        sleep 5
    fi
    
    # 部署到模拟器
    if monkeydo "$release_prg" fr965; then
        print_success "发布版本已部署到模拟器"
    else
        print_error "部署到模拟器失败"
        exit 1
    fi
}

# 检查是否在正确的目录中运行
if [[ ! -f "manifest.xml" ]]; then
    print_error "请在项目根目录中运行此脚本"
    exit 1
fi

# 运行主函数
main "$@"