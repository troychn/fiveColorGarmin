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
SDK_PATH="${HOME}/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.4.0-2025-12-03-5122605dc"
API_DB="$SDK_PATH/bin/api.db"
PROJECT_INFO="$SDK_PATH/bin/projectInfo.xml"

# 设置PATH环境变量
export PATH="$SDK_PATH/bin:$PATH"

# 支持的设备列表
DEVICES=("fr965" "fr255" "fr255m" "fr265" "fr265s" "fr57042mm" "fr57047mm" "fr970")

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

# 函数：编译FR965调试版本
build_fr965_debug() {
    print_info "编译FR965调试版本..."
    
    local debug_output="${BIN_DIR}/${PROJECT_NAME}_fr965_debug.prg"
    
    if monkeyc -f "$JUNGLE_FILE" -o "$debug_output" -y "$DEVELOPER_KEY" -d fr965 -w; then
        print_success "FR965调试版本编译完成: $debug_output"
        
        # 显示文件信息
        local file_size=$(ls -lh "$debug_output" | awk '{print $5}')
        print_info "文件大小: $file_size"
        return 0
    else
        print_error "FR965调试版本编译失败"
        return 1
    fi
}

# 函数：编译FR265调试版本
build_fr265_debug() {
    print_info "编译FR265调试版本..."
    
    local fr265_debug_output="${BIN_DIR}/${PROJECT_NAME}_fr265_debug.prg"
    
    if monkeyc -f "$JUNGLE_FILE" -o "$fr265_debug_output" -y "$DEVELOPER_KEY" -d fr265 -w; then
        print_success "FR265调试版本编译完成: $fr265_debug_output"
        
        # 显示文件信息
        local file_size=$(ls -lh "$fr265_debug_output" | awk '{print $5}')
        print_info "文件大小: $file_size"
        
        return 0
    else
        print_error "FR265调试版本编译失败"
        return 1
    fi
}

# 函数：编译FR265S调试版本
build_fr265s_debug() {
    print_info "编译FR265S调试版本..."
    
    local fr265s_debug_output="${BIN_DIR}/${PROJECT_NAME}_fr265s_debug.prg"
    
    if monkeyc -f "$JUNGLE_FILE" -o "$fr265s_debug_output" -y "$DEVELOPER_KEY" -d fr265s -w; then
        print_success "FR265S调试版本编译完成: $fr265s_debug_output"
        
        # 显示文件信息
        local file_size=$(ls -lh "$fr265s_debug_output" | awk '{print $5}')
        print_info "文件大小: $file_size"
        
        return 0
    else
        print_error "FR265S调试版本编译失败"
        return 1
    fi
}

# 函数：编译FR57042MM调试版本
build_fr57042mm_debug() {
    print_info "编译FR57042MM调试版本..."
    
    local fr57042mm_debug_output="${BIN_DIR}/${PROJECT_NAME}_fr57042mm_debug.prg"
    
    if monkeyc -f "$JUNGLE_FILE" -o "$fr57042mm_debug_output" -y "$DEVELOPER_KEY" -d fr57042mm -w; then
        print_success "FR57042MM调试版本编译完成: $fr57042mm_debug_output"
        
        # 显示文件信息
        local file_size=$(ls -lh "$fr57042mm_debug_output" | awk '{print $5}')
        print_info "文件大小: $file_size"
        
        return 0
    else
        print_error "FR57042MM调试版本编译失败"
        return 1
    fi
}

# 函数：编译FR57047MM调试版本
build_fr57047mm_debug() {
    print_info "编译FR57047MM调试版本..."
    
    local fr57047mm_debug_output="${BIN_DIR}/${PROJECT_NAME}_fr57047mm_debug.prg"
    
    if monkeyc -f "$JUNGLE_FILE" -o "$fr57047mm_debug_output" -y "$DEVELOPER_KEY" -d fr57047mm -w; then
        print_success "FR57047MM调试版本编译完成: $fr57047mm_debug_output"
        
        # 显示文件信息
        local file_size=$(ls -lh "$fr57047mm_debug_output" | awk '{print $5}')
        print_info "文件大小: $file_size"
        
        return 0
    else
        print_error "FR57047MM调试版本编译失败"
        return 1
    fi
}

# 函数：编译FR970调试版本
build_fr970_debug() {
    print_info "编译FR970调试版本..."
    
    local fr970_debug_output="${BIN_DIR}/${PROJECT_NAME}_fr970_debug.prg"
    
    if monkeyc -f "$JUNGLE_FILE" -o "$fr970_debug_output" -y "$DEVELOPER_KEY" -d fr970 -w; then
        print_success "FR970调试版本编译完成: $fr970_debug_output"
        
        # 显示文件信息
        local file_size=$(ls -lh "$fr970_debug_output" | awk '{print $5}')
        print_info "文件大小: $file_size"
        
        return 0
    else
        print_error "FR970调试版本编译失败"
        return 1
    fi
}

# 函数：编译所有调试版本
build_all_debug() {
    print_info "编译所有设备调试版本..."
    
    local success_count=0
    local total_count=8
    
    # 编译FR965调试版本
    if build_fr965_debug; then
        ((success_count++))
    fi
    
    # 编译FR255调试版本
    if build_fr255_debug; then
        ((success_count++))
    fi
    
    # 编译FR255 Music调试版本
    if build_fr255m_debug; then
        ((success_count++))
    fi
    
    # 编译FR265调试版本
    if build_fr265_debug; then
        ((success_count++))
    fi
    
    # 编译FR265S调试版本
    if build_fr265s_debug; then
        ((success_count++))
    fi
    
    # 编译FR57042MM调试版本
    if build_fr57042mm_debug; then
        ((success_count++))
    fi
    
    # 编译FR57047MM调试版本
    if build_fr57047mm_debug; then
        ((success_count++))
    fi
    
    # 编译FR970调试版本
    if build_fr970_debug; then
        ((success_count++))
    fi
    
    print_info "调试版本编译完成: $success_count/$total_count"
    
    if [[ $success_count -eq $total_count ]]; then
        print_success "所有调试版本编译成功"
        return 0
    else
        print_warning "部分调试版本编译失败"
        return 1
    fi
}

# 函数：编译FR255调试版本
build_fr255_debug() {
    print_info "编译FR255调试版本..."
    
    local fr255_debug_output="${BIN_DIR}/${PROJECT_NAME}_fr255_debug.prg"
    
    if monkeyc -f "$JUNGLE_FILE" -o "$fr255_debug_output" -y "$DEVELOPER_KEY" -d fr255 -w; then
        print_success "FR255调试版本编译完成: $fr255_debug_output"
        
        # 显示文件信息
        local file_size=$(ls -lh "$fr255_debug_output" | awk '{print $5}')
        print_info "文件大小: $file_size"
        
        return 0
    else
        print_error "FR255调试版本编译失败"
        return 1
    fi
}

# 函数：部署FR255调试版本到模拟器
deploy_fr255_debug_to_simulator() {
    print_info "部署FR255调试版本到模拟器..."
    
    local fr255_debug_prg="${BIN_DIR}/${PROJECT_NAME}_fr255_debug.prg"
    
    if [[ ! -f "$fr255_debug_prg" ]]; then
        print_warning "FR255调试版本PRG文件不存在，正在编译..."
        if ! build_fr255_debug; then
            print_error "无法编译FR255调试版本"
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
    if monkeydo "$fr255_debug_prg" fr255; then
        print_success "FR255调试版本已部署到模拟器"
    else
        print_error "FR255调试版本部署到模拟器失败"
        exit 1
    fi
}

# 函数：编译FR255 Music调试版本
build_fr255m_debug() {
    print_info "开始编译FR255 Music调试版本..."
    
    local fr255m_debug_output="${BIN_DIR}/${PROJECT_NAME}_fr255m_debug.prg"
    
    if monkeyc -f "$JUNGLE_FILE" -o "$fr255m_debug_output" -y "$DEVELOPER_KEY" -d fr255m -w; then
        print_success "FR255 Music调试版本编译完成: $fr255m_debug_output"
        
        # 显示文件大小
        local file_size=$(ls -lh "$fr255m_debug_output" | awk '{print $5}')
        print_info "文件大小: $file_size"
        
        return 0
    else
        print_error "FR255 Music调试版本编译失败"
        return 1
    fi
}

# 函数：部署FR255 Music调试版本到模拟器
deploy_fr255m_debug_to_simulator() {
    print_info "部署FR255 Music调试版本到模拟器..."
    
    local fr255m_debug_prg="${BIN_DIR}/${PROJECT_NAME}_fr255m_debug.prg"
    
    if [[ ! -f "$fr255m_debug_prg" ]]; then
        print_warning "FR255 Music调试版本PRG文件不存在，正在编译..."
        if ! build_fr255m_debug; then
            print_error "无法编译FR255 Music调试版本"
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
    if monkeydo "$fr255m_debug_prg" fr255m; then
        print_success "FR255 Music调试版本已部署到模拟器"
    else
        print_error "FR255 Music调试版本部署到模拟器失败"
        exit 1
    fi
}

# 函数：编译FR965发布版本
build_fr965_release() {
    print_info "编译FR965发布版本..."
    
    local release_output="${BIN_DIR}/${PROJECT_NAME}_fr965_release.prg"
    
    if monkeyc -f "$JUNGLE_FILE" -o "$release_output" -y "$DEVELOPER_KEY" -d fr965 -w -r; then
        print_success "FR965发布版本编译完成: $release_output"
        
        # 显示文件信息
        local file_size=$(ls -lh "$release_output" | awk '{print $5}')
        print_info "文件大小: $file_size"
        return 0
    else
        print_error "FR965发布版本编译失败"
        return 1
    fi
}

# 函数：编译FR255发布版本
build_fr255_release() {
    print_info "编译FR255发布版本..."
    
    local release_output="${BIN_DIR}/${PROJECT_NAME}_fr255_release.prg"
    
    if monkeyc -f "$JUNGLE_FILE" -o "$release_output" -y "$DEVELOPER_KEY" -d fr255 -w -r; then
        print_success "FR255发布版本编译完成: $release_output"
        
        # 显示文件信息
        local file_size=$(ls -lh "$release_output" | awk '{print $5}')
        print_info "文件大小: $file_size"
        return 0
    else
        print_error "FR255发布版本编译失败"
        return 1
    fi
}

# 函数：编译FR255 Music发布版本
build_fr255m_release() {
    print_info "开始编译FR255 Music发布版本..."
    
    local release_output="${BIN_DIR}/${PROJECT_NAME}_fr255m_release.prg"
    
    if monkeyc -f "$JUNGLE_FILE" -o "$release_output" -y "$DEVELOPER_KEY" -d fr255 -r; then
        print_success "FR255 Music发布版本编译完成: $release_output"
        
        # 显示文件大小
        local file_size=$(ls -lh "$release_output" | awk '{print $5}')
        print_info "文件大小: $file_size"
        
        return 0
    else
        print_error "FR255 Music发布版本编译失败"
        return 1
    fi
}

# 函数：编译FR265发布版本
build_fr265_release() {
    print_info "编译FR265发布版本..."
    
    local release_output="${BIN_DIR}/${PROJECT_NAME}_fr265_release.prg"
    
    if monkeyc -f "$JUNGLE_FILE" -o "$release_output" -y "$DEVELOPER_KEY" -d fr265 -w -r; then
        print_success "FR265发布版本编译完成: $release_output"
        
        # 显示文件信息
        local file_size=$(ls -lh "$release_output" | awk '{print $5}')
        print_info "文件大小: $file_size"
        return 0
    else
        print_error "FR265发布版本编译失败"
        return 1
    fi
}

# 函数：编译FR265S发布版本
build_fr265s_release() {
    print_info "编译FR265S发布版本..."
    
    local release_output="${BIN_DIR}/${PROJECT_NAME}_fr265s_release.prg"
    
    if monkeyc -f "$JUNGLE_FILE" -o "$release_output" -y "$DEVELOPER_KEY" -d fr265s -w -r; then
        print_success "FR265S发布版本编译完成: $release_output"
        
        # 显示文件信息
        local file_size=$(ls -lh "$release_output" | awk '{print $5}')
        print_info "文件大小: $file_size"
        return 0
    else
        print_error "FR265S发布版本编译失败"
        return 1
    fi
}

# 函数：编译FR57042MM发布版本
build_fr57042mm_release() {
    print_info "编译FR57042MM发布版本..."
    
    local release_output="${BIN_DIR}/${PROJECT_NAME}_fr57042mm_release.prg"
    
    if monkeyc -f "$JUNGLE_FILE" -o "$release_output" -y "$DEVELOPER_KEY" -d fr57042mm -w -r; then
        print_success "FR57042MM发布版本编译完成: $release_output"
        
        # 显示文件信息
        local file_size=$(ls -lh "$release_output" | awk '{print $5}')
        print_info "文件大小: $file_size"
        return 0
    else
        print_error "FR57042MM发布版本编译失败"
        return 1
    fi
}

# 函数：编译FR57047MM发布版本
build_fr57047mm_release() {
    print_info "编译FR57047MM发布版本..."
    
    local release_output="${BIN_DIR}/${PROJECT_NAME}_fr57047mm_release.prg"
    
    if monkeyc -f "$JUNGLE_FILE" -o "$release_output" -y "$DEVELOPER_KEY" -d fr57047mm -w -r; then
        print_success "FR57047MM发布版本编译完成: $release_output"
        
        # 显示文件信息
        local file_size=$(ls -lh "$release_output" | awk '{print $5}')
        print_info "文件大小: $file_size"
        return 0
    else
        print_error "FR57047MM发布版本编译失败"
        return 1
    fi
}

# 函数：编译FR970发布版本
build_fr970_release() {
    print_info "编译FR970发布版本..."
    
    local release_output="${BIN_DIR}/${PROJECT_NAME}_fr970_release.prg"
    
    if monkeyc -f "$JUNGLE_FILE" -o "$release_output" -y "$DEVELOPER_KEY" -d fr970 -w -r; then
        print_success "FR970发布版本编译完成: $release_output"
        
        # 显示文件信息
        local file_size=$(ls -lh "$release_output" | awk '{print $5}')
        print_info "文件大小: $file_size"
        return 0
    else
        print_error "FR970发布版本编译失败"
        return 1
    fi
}

# 函数：编译通用IQ发布包
build_release_iq() {
    print_info "编译通用发布版本 (IQ文件)..."
    
    if monkeyc -f "$JUNGLE_FILE" -o "$OUTPUT_IQ" -y "$DEVELOPER_KEY" -w -r -e; then
        print_success "通用发布版本编译完成: $OUTPUT_IQ"
        
        # 显示文件信息
        local file_size=$(ls -lh "$OUTPUT_IQ" | awk '{print $5}')
        print_info "文件大小: $file_size"
        
        # 验证IQ文件
        if file "$OUTPUT_IQ" | grep -q "Zip archive"; then
            print_success "IQ文件格式验证通过"
        else
            print_warning "IQ文件格式可能有问题"
        fi
        return 0
    else
        print_error "通用发布版本编译失败"
        return 1
    fi
}

# 函数：编译所有发布版本
build_all_release() {
    print_info "编译所有设备发布版本..."
    
    local success_count=0
    local total_count=9
    
    # 编译FR965发布版本
    if build_fr965_release; then
        ((success_count++))
    fi
    
    # 编译FR255发布版本
    if build_fr255_release; then
        ((success_count++))
    fi
    
    # 编译FR255 Music发布版本
    if build_fr255m_release; then
        ((success_count++))
    fi
    
    # 编译FR265发布版本
    if build_fr265_release; then
        ((success_count++))
    fi
    
    # 编译FR265S发布版本
    if build_fr265s_release; then
        ((success_count++))
    fi
    
    # 编译FR57042MM发布版本
    if build_fr57042mm_release; then
        ((success_count++))
    fi
    
    # 编译FR57047MM发布版本
    if build_fr57047mm_release; then
        ((success_count++))
    fi
    
    # 编译FR970发布版本
    if build_fr970_release; then
        ((success_count++))
    fi
    
    # 编译通用IQ包
    if build_release_iq; then
        ((success_count++))
    fi
    
    print_info "发布版本编译完成: $success_count/$total_count"
    
    if [[ $success_count -eq $total_count ]]; then
        print_success "所有发布版本编译成功"
        return 0
    else
        print_warning "部分发布版本编译失败"
        return 1
    fi
}

# 函数：检查并启动模拟器
check_and_start_simulator() {
    print_info "检查模拟器状态..."
    if ! pgrep -f "simulator" > /dev/null && ! pgrep -f "connectiq" > /dev/null; then
        print_info "启动模拟器..."
        connectiq &
        sleep 10  # 增加等待时间到10秒
    else
        print_info "模拟器已在运行"
    fi
}

# 函数：带重试机制的部署
deploy_to_simulator_with_retry() {
    local prg_file=$1
    local device_id=$2
    local max_retries=1
    local retry_count=0

    # 确保模拟器运行
    check_and_start_simulator

    while [ $retry_count -le $max_retries ]; do
        print_info "尝试部署到模拟器 (尝试 $((retry_count+1))/$((max_retries+1)))..."
        
        if monkeydo "$prg_file" "$device_id"; then
            print_success "部署成功"
            return 0
        fi
        
        print_warning "部署失败"
        
        if [ $retry_count -lt $max_retries ]; then
            print_warning "尝试重启模拟器..."
            pkill -f "simulator" || true
            pkill -f "connectiq" || true
            sleep 2
            
            print_info "重新启动模拟器..."
            connectiq &
            sleep 15  # 重启后等待更长时间
        fi
        
        ((retry_count++))
    done
    
    print_error "部署到模拟器失败，请尝试手动启动模拟器后重试"
    return 1
}

# 函数：部署FR965调试版本到模拟器
deploy_fr965_debug_to_simulator() {
    print_info "部署FR965调试版本到模拟器..."
    
    local fr965_debug_prg="${BIN_DIR}/${PROJECT_NAME}_fr965_debug.prg"
    
    if [[ ! -f "$fr965_debug_prg" ]]; then
        print_warning "FR965调试版本PRG文件不存在，正在编译..."
        if ! build_fr965_debug; then
            print_error "无法编译FR965调试版本"
            exit 1
        fi
    fi
    
    deploy_to_simulator_with_retry "$fr965_debug_prg" "fr965"
}

# 函数：部署FR965发布版本到模拟器
deploy_fr965_release_to_simulator() {
    print_info "部署FR965发布版本到模拟器..."
    
    local fr965_release_prg="${BIN_DIR}/${PROJECT_NAME}_fr965_release.prg"
    
    if [[ ! -f "$fr965_release_prg" ]]; then
        print_warning "FR965发布版本PRG文件不存在，正在编译..."
        if ! build_fr965_release; then
            print_error "无法编译FR965发布版本"
            exit 1
        fi
    fi
    
    deploy_to_simulator_with_retry "$fr965_release_prg" "fr965"
}

# 函数：部署FR255发布版本到模拟器
deploy_fr255_release_to_simulator() {
    print_info "部署FR255发布版本到模拟器..."
    
    local fr255_release_prg="${BIN_DIR}/${PROJECT_NAME}_fr255_release.prg"
    
    if [[ ! -f "$fr255_release_prg" ]]; then
        print_warning "FR255发布版本PRG文件不存在，正在编译..."
        if ! build_fr255_release; then
            print_error "无法编译FR255发布版本"
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
    if monkeydo "$fr255_release_prg" fr255; then
        print_success "FR255发布版本已部署到模拟器"
    else
        print_error "FR255发布版本部署到模拟器失败"
        exit 1
    fi
}

# 函数：部署FR255 Music发布版本到模拟器
deploy_fr255m_release_to_simulator() {
    print_info "部署FR255 Music发布版本到模拟器..."
    
    local fr255m_release_prg="${BIN_DIR}/${PROJECT_NAME}_fr255m_release.prg"
    
    if [[ ! -f "$fr255m_release_prg" ]]; then
        print_warning "FR255 Music发布版本PRG文件不存在，正在编译..."
        if ! build_fr255m_release; then
            print_error "无法编译FR255 Music发布版本"
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
    if monkeydo "$fr255m_release_prg" fr255; then
        print_success "FR255 Music发布版本已部署到模拟器"
    else
        print_error "FR255 Music发布版本部署到模拟器失败"
        exit 1
    fi
}

# 函数：部署FR265调试版本到模拟器
deploy_fr265_debug_to_simulator() {
    print_info "部署FR265调试版本到模拟器..."
    
    local fr265_debug_prg="${BIN_DIR}/${PROJECT_NAME}_fr265_debug.prg"
    
    if [[ ! -f "$fr265_debug_prg" ]]; then
        print_warning "FR265调试版本PRG文件不存在，正在编译..."
        if ! build_fr265_debug; then
            print_error "无法编译FR265调试版本"
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
    if monkeydo "$fr265_debug_prg" fr265; then
        print_success "FR265调试版本已部署到模拟器"
    else
        print_error "FR265调试版本部署到模拟器失败"
        exit 1
    fi
}

# 函数：部署FR265发布版本到模拟器
deploy_fr265_release_to_simulator() {
    print_info "部署FR265发布版本到模拟器..."
    
    local fr265_release_prg="${BIN_DIR}/${PROJECT_NAME}_fr265_release.prg"
    
    if [[ ! -f "$fr265_release_prg" ]]; then
        print_warning "FR265发布版本PRG文件不存在，正在编译..."
        if ! build_fr265_release; then
            print_error "无法编译FR265发布版本"
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
    if monkeydo "$fr265_release_prg" fr265; then
        print_success "FR265发布版本已部署到模拟器"
    else
        print_error "FR265发布版本部署到模拟器失败"
        exit 1
    fi
}

# 函数：部署FR265S调试版本到模拟器
deploy_fr265s_debug_to_simulator() {
    print_info "部署FR265S调试版本到模拟器..."
    
    local fr265s_debug_prg="${BIN_DIR}/${PROJECT_NAME}_fr265s_debug.prg"
    
    if [[ ! -f "$fr265s_debug_prg" ]]; then
        print_warning "FR265S调试版本PRG文件不存在，正在编译..."
        if ! build_fr265s_debug; then
            print_error "无法编译FR265S调试版本"
            exit 1
        fi
    fi
    
    # 检查模拟器是否运行
    if ! pgrep -f "simulator" > /dev/null && ! pgrep -f "connectiq" > /dev/null; then
        print_info "启动模拟器..."
        connectiq &
        sleep 5
    fi
    
    # 部署到模拟器（禁用日志输出）
    if monkeydo "$fr265s_debug_prg" fr265s > /dev/null 2>&1; then
        print_success "FR265S调试版本已部署到模拟器"
    else
        print_error "FR265S调试版本部署到模拟器失败"
        exit 1
    fi
}

# 函数：部署FR265S发布版本到模拟器
deploy_fr265s_release_to_simulator() {
    print_info "部署FR265S发布版本到模拟器..."
    
    local fr265s_release_prg="${BIN_DIR}/${PROJECT_NAME}_fr265s_release.prg"
    
    if [[ ! -f "$fr265s_release_prg" ]]; then
        print_warning "FR265S发布版本PRG文件不存在，正在编译..."
        if ! build_fr265s_release; then
            print_error "无法编译FR265S发布版本"
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
    if monkeydo "$fr265s_release_prg" fr265s; then
        print_success "FR265S发布版本已部署到模拟器"
    else
        print_error "FR265S发布版本部署到模拟器失败"
        exit 1
    fi
}

# 函数：部署FR57042MM调试版本到模拟器
deploy_fr57042mm_debug_to_simulator() {
    print_info "部署FR57042MM调试版本到模拟器..."
    
    local fr57042mm_debug_prg="${BIN_DIR}/${PROJECT_NAME}_fr57042mm_debug.prg"
    
    if [[ ! -f "$fr57042mm_debug_prg" ]]; then
        print_warning "FR57042MM调试版本PRG文件不存在，正在编译..."
        if ! build_fr57042mm_debug; then
            print_error "无法编译FR57042MM调试版本"
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
    if monkeydo "$fr57042mm_debug_prg" fr57042mm; then
        print_success "FR57042MM调试版本已部署到模拟器"
    else
        print_error "FR57042MM调试版本部署到模拟器失败"
        exit 1
    fi
}

# 函数：部署FR57042MM发布版本到模拟器
deploy_fr57042mm_release_to_simulator() {
    print_info "部署FR57042MM发布版本到模拟器..."
    
    local fr57042mm_release_prg="${BIN_DIR}/${PROJECT_NAME}_fr57042mm_release.prg"
    
    if [[ ! -f "$fr57042mm_release_prg" ]]; then
        print_warning "FR57042MM发布版本PRG文件不存在，正在编译..."
        if ! build_fr57042mm_release; then
            print_error "无法编译FR57042MM发布版本"
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
    if monkeydo "$fr57042mm_release_prg" fr57042mm; then
        print_success "FR57042MM发布版本已部署到模拟器"
    else
        print_error "FR57042MM发布版本部署到模拟器失败"
        exit 1
    fi
}

# 函数：部署FR57047MM调试版本到模拟器
deploy_fr57047mm_debug_to_simulator() {
    print_info "部署FR57047MM调试版本到模拟器..."
    
    local fr57047mm_debug_prg="${BIN_DIR}/${PROJECT_NAME}_fr57047mm_debug.prg"
    
    if [[ ! -f "$fr57047mm_debug_prg" ]]; then
        print_warning "FR57047MM调试版本PRG文件不存在，正在编译..."
        if ! build_fr57047mm_debug; then
            print_error "无法编译FR57047MM调试版本"
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
    if monkeydo "$fr57047mm_debug_prg" fr57047mm; then
        print_success "FR57047MM调试版本已部署到模拟器"
    else
        print_error "FR57047MM调试版本部署到模拟器失败"
        exit 1
    fi
}

# 函数：部署FR57047MM发布版本到模拟器
deploy_fr57047mm_release_to_simulator() {
    print_info "部署FR57047MM发布版本到模拟器..."
    
    local fr57047mm_release_prg="${BIN_DIR}/${PROJECT_NAME}_fr57047mm_release.prg"
    
    if [[ ! -f "$fr57047mm_release_prg" ]]; then
        print_warning "FR57047MM发布版本PRG文件不存在，正在编译..."
        if ! build_fr57047mm_release; then
            print_error "无法编译FR57047MM发布版本"
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
    if monkeydo "$fr57047mm_release_prg" fr57047mm; then
        print_success "FR57047MM发布版本已部署到模拟器"
    else
        print_error "FR57047MM发布版本部署到模拟器失败"
        exit 1
    fi
}

# 函数：部署FR970调试版本到模拟器
deploy_fr970_debug_to_simulator() {
    print_info "部署FR970调试版本到模拟器..."
    
    local fr970_debug_prg="${BIN_DIR}/${PROJECT_NAME}_fr970_debug.prg"
    
    if [[ ! -f "$fr970_debug_prg" ]]; then
        print_warning "FR970调试版本PRG文件不存在，正在编译..."
        if ! build_fr970_debug; then
            print_error "无法编译FR970调试版本"
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
    if monkeydo "$fr970_debug_prg" fr970; then
        print_success "FR970调试版本已部署到模拟器"
    else
        print_error "FR970调试版本部署到模拟器失败"
        exit 1
    fi
}

# 函数：部署FR970发布版本到模拟器
deploy_fr970_release_to_simulator() {
    print_info "部署FR970发布版本到模拟器..."
    
    local fr970_release_prg="${BIN_DIR}/${PROJECT_NAME}_fr970_release.prg"
    
    if [[ ! -f "$fr970_release_prg" ]]; then
        print_warning "FR970发布版本PRG文件不存在，正在编译..."
        if ! build_fr970_release; then
            print_error "无法编译FR970发布版本"
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
    if monkeydo "$fr970_release_prg" fr970; then
        print_success "FR970发布版本已部署到模拟器"
    else
        print_error "FR970发布版本部署到模拟器失败"
        exit 1
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
    echo "  -h, --help           显示帮助信息"
    echo "  -c, --clean          仅清理构建目录"
    echo "  -d, --debug          编译所有调试版本(FR965+FR255+FR265+FR265S+FR57042MM+FR57047MM+FR970)"
    echo "  --fr965-debug        编译FR965调试版本"
    echo "  --fr965-debug-sim    编译FR965调试版本并部署到模拟器"
    echo "  --fr255-debug        编译FR255调试版本"
    echo "  --fr255-debug-sim    编译FR255调试版本并部署到模拟器"
    echo "  --fr255m-debug       编译FR255 Music调试版本"
  echo "  --fr255m-debug-sim   编译FR255 Music调试版本并部署到模拟器"
    echo "  --fr265-debug        编译FR265调试版本"
    echo "  --fr265-debug-sim    编译FR265调试版本并部署到模拟器"
    echo "  --fr265s-debug       编译FR265S调试版本"
    echo "  --fr265s-debug-sim   编译FR265S调试版本并部署到模拟器"
    echo "  --fr57042mm-debug    编译FR57042MM调试版本"
    echo "  --fr57042mm-debug-sim 编译FR57042MM调试版本并部署到模拟器"
    echo "  --fr57047mm-debug    编译FR57047MM调试版本"
    echo "  --fr57047mm-debug-sim 编译FR57047MM调试版本并部署到模拟器"
    echo "  --fr970-debug        编译FR970调试版本"
    echo "  --fr970-debug-sim    编译FR970调试版本并部署到模拟器"
    echo "  -r, --release        编译所有发布版本(所有设备+IQ)"
    echo "  --fr965-release      编译FR965发布版本"
    echo "  --fr965-release-sim  编译FR965发布版本并部署到模拟器"
    echo "  --fr255-release      编译FR255发布版本"
    echo "  --fr255-release-sim  编译FR255发布版本并部署到模拟器"
    echo "  --fr255m-release     编译FR255 Music发布版本"
  echo "  --fr255m-release-sim 编译FR255 Music发布版本并部署到模拟器"
    echo "  --fr265-release      编译FR265发布版本"
    echo "  --fr265-release-sim  编译FR265发布版本并部署到模拟器"
    echo "  --fr265s-release     编译FR265S发布版本"
    echo "  --fr265s-release-sim 编译FR265S发布版本并部署到模拟器"
    echo "  --fr57042mm-release  编译FR57042MM发布版本"
    echo "  --fr57042mm-release-sim 编译FR57042MM发布版本并部署到模拟器"
    echo "  --fr57047mm-release  编译FR57047MM发布版本"
    echo "  --fr57047mm-release-sim 编译FR57047MM发布版本并部署到模拟器"
    echo "  --fr970-release      编译FR970发布版本"
    echo "  --fr970-release-sim  编译FR970发布版本并部署到模拟器"
    echo "  --iq-only            仅编译通用IQ发布包"
    echo "  -v, --validate       仅验证项目文件"
    echo "  -i, --info           显示项目信息"
    echo ""
    echo "默认行为: 执行完整的发布准备流程"
    echo ""
    echo "示例:"
    echo "  $0                      # 执行完整发布流程"
    echo "  $0 --debug              # 编译所有调试版本"
    echo "  $0 --fr965-debug        # 仅编译FR965调试版本"
    echo "  $0 --fr965-debug-sim    # 编译FR965调试版本并部署到模拟器"
    echo "  $0 --fr255-debug        # 仅编译FR255调试版本"
    echo "  $0 --fr255-debug-sim    # 编译FR255调试版本并部署到模拟器"
    echo "  $0 --fr255m-debug-sim    # 编译FR255 Music调试版本并部署到模拟器"
    echo "  $0 --release            # 编译所有发布版本"
    echo "  $0 --fr965-release      # 仅编译FR965发布版本"
    echo "  $0 --fr965-release-sim  # 编译FR965发布版本并部署到模拟器"
    echo "  $0 --fr255-release      # 仅编译FR255发布版本"
    echo "  $0 --fr255-release-sim  # 编译FR255发布版本并部署到模拟器"
    echo "  $0 --iq-only            # 仅编译通用IQ发布包"
    echo "  $0 --clean              # 清理构建目录"
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
            build_all_debug
            exit 0
            ;;
        --fr965-debug)
            check_tools
            validate_project
            clean_build
            build_fr965_debug
            exit 0
            ;;
        --fr965-debug-sim)
            check_tools
            validate_project
            clean_build
            build_fr965_debug
            deploy_fr965_debug_to_simulator
            exit 0
            ;;
        --fr255-debug)
            check_tools
            validate_project
            clean_build
            build_fr255_debug
            exit 0
            ;;
        --fr255-debug-sim)
            check_tools
            validate_project
            clean_build
            build_fr255_debug
            deploy_fr255_debug_to_simulator
            exit 0
            ;;
        --fr255m-debug)
            check_tools
            validate_project
            clean_build
            build_fr255m_debug
            exit 0
            ;;
        --fr255m-debug-sim)
            check_tools
            validate_project
            clean_build
            build_fr255m_debug
            deploy_fr255m_debug_to_simulator
            exit 0
            ;;
        --fr265-debug)
            check_tools
            validate_project
            clean_build
            build_fr265_debug
            exit 0
            ;;
        --fr265-debug-sim)
            check_tools
            validate_project
            clean_build
            build_fr265_debug
            deploy_fr265_debug_to_simulator
            exit 0
            ;;
        --fr265s-debug)
            check_tools
            validate_project
            clean_build
            build_fr265s_debug
            exit 0
            ;;
        --fr265s-debug-sim)
            check_tools
            validate_project
            clean_build
            build_fr265s_debug
            deploy_fr265s_debug_to_simulator
            exit 0
            ;;
        --fr57042mm-debug)
            check_tools
            validate_project
            clean_build
            build_fr57042mm_debug
            exit 0
            ;;
        --fr57042mm-debug-sim)
            check_tools
            validate_project
            clean_build
            build_fr57042mm_debug
            deploy_fr57042mm_debug_to_simulator
            exit 0
            ;;
        --fr57047mm-debug)
            check_tools
            validate_project
            clean_build
            build_fr57047mm_debug
            exit 0
            ;;
        --fr57047mm-debug-sim)
            check_tools
            validate_project
            clean_build
            build_fr57047mm_debug
            deploy_fr57047mm_debug_to_simulator
            exit 0
            ;;
        --fr970-debug)
            check_tools
            validate_project
            clean_build
            build_fr970_debug
            exit 0
            ;;
        --fr970-debug-sim)
            check_tools
            validate_project
            clean_build
            build_fr970_debug
            deploy_fr970_debug_to_simulator
            exit 0
            ;;
        -r|--release)
            check_tools
            validate_project
            clean_build
            build_all_release
            validate_iq_file
            exit 0
            ;;
        --fr965-release)
            check_tools
            validate_project
            clean_build
            build_fr965_release
            exit 0
            ;;
        --fr965-release-sim)
            check_tools
            validate_project
            clean_build
            build_fr965_release
            deploy_fr965_release_to_simulator
            exit 0
            ;;
        --fr255-release)
            check_tools
            validate_project
            clean_build
            build_fr255_release
            exit 0
            ;;
        --fr255-release-sim)
            check_tools
            validate_project
            clean_build
            build_fr255_release
            deploy_fr255_release_to_simulator
            exit 0
            ;;
        --fr255m-release)
            check_tools
            validate_project
            clean_build
            build_fr255m_release
            exit 0
            ;;
        --fr255m-release-sim)
            check_tools
            validate_project
            clean_build
            build_fr255m_release
            deploy_fr255m_release_to_simulator
            exit 0
            ;;
        --fr265-release)
            check_tools
            validate_project
            clean_build
            build_fr265_release
            exit 0
            ;;
        --fr265-release-sim)
            check_tools
            validate_project
            clean_build
            build_fr265_release
            deploy_fr265_release_to_simulator
            exit 0
            ;;
        --fr265s-release)
            check_tools
            validate_project
            clean_build
            build_fr265s_release
            exit 0
            ;;
        --fr265s-release-sim)
            check_tools
            validate_project
            clean_build
            build_fr265s_release
            deploy_fr265s_release_to_simulator
            exit 0
            ;;
        --fr57042mm-release)
            check_tools
            validate_project
            clean_build
            build_fr57042mm_release
            exit 0
            ;;
        --fr57042mm-release-sim)
            check_tools
            validate_project
            clean_build
            build_fr57042mm_release
            deploy_fr57042mm_release_to_simulator
            exit 0
            ;;
        --fr57047mm-release)
            check_tools
            validate_project
            clean_build
            build_fr57047mm_release
            exit 0
            ;;
        --fr57047mm-release-sim)
            check_tools
            validate_project
            clean_build
            build_fr57047mm_release
            deploy_fr57047mm_release_to_simulator
            exit 0
            ;;
        --fr970-release)
            check_tools
            validate_project
            clean_build
            build_fr970_release
            exit 0
            ;;
        --fr970-release-sim)
            check_tools
            validate_project
            clean_build
            build_fr970_release
            deploy_fr970_release_to_simulator
            exit 0
            ;;
        --iq-only)
            check_tools
            validate_project
            clean_build
            build_release_iq
            validate_iq_file
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
    build_all_debug
    build_all_release
    validate_iq_file
    generate_checklist
    show_publish_info
}



# 检查是否在正确的目录中运行
if [[ ! -f "manifest.xml" ]]; then
    print_error "请在项目根目录中运行此脚本"
    exit 1
fi

# 运行主函数
main "$@"