#!/bin/bash

# 五行配色表盘构建脚本
# Five Element Watch Face Build Script

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目配置
PROJECT_NAME="FiveElementWatchFace"
DEVELOPER_KEY="developer_key.der"
JUNGLE_FILE="monkey.jungle"
OUTPUT_DIR="bin"
SIMULATOR_DEVICE="fr965"

# SDK路径 - 使用8.2.1版本以支持2025.7.1后的应用商店要求
# SDK_PATH="/Users/zengqiuyan/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-6.4.2-2024-01-04-a1dd13ee0"
SDK_PATH="/Users/zengqiuyan/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-8.2.1-2025-06-19-f69b94140"  # 2025.7.1后必须使用8.1+版本
API_DB="$SDK_PATH/bin/api.db"
PROJECT_INFO="$SDK_PATH/bin/projectInfo.xml"

# 设置PATH环境变量
export PATH="$SDK_PATH/bin:$PATH"

# 函数：打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 函数：检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_message $RED "错误: $1 命令未找到，请确保已安装 Connect IQ SDK"
        exit 1
    fi
}

# 函数：清理构建目录
clean_build() {
    print_message $YELLOW "清理构建目录..."
    if [ -d "$OUTPUT_DIR" ]; then
        rm -rf "$OUTPUT_DIR"
    fi
    mkdir -p "$OUTPUT_DIR"
    print_message $GREEN "构建目录已清理"
}

# 函数：编译调试版本
build_debug() {
    print_message $BLUE "编译调试版本..."
    monkeyc -f "$JUNGLE_FILE" -o "$OUTPUT_DIR/${PROJECT_NAME}_debug.prg" -y "$DEVELOPER_KEY" -d "$SIMULATOR_DEVICE" -w
    if [ $? -eq 0 ]; then
        print_message $GREEN "调试版本编译成功: $OUTPUT_DIR/${PROJECT_NAME}_debug.prg"
    else
        print_message $RED "调试版本编译失败"
        exit 1
    fi
}

# 函数：编译发布版本
build_release() {
    print_message $BLUE "编译发布版本..."
    monkeyc -f "$JUNGLE_FILE" -o "$OUTPUT_DIR/${PROJECT_NAME}.iq" -w -y "$DEVELOPER_KEY" -r
    if [ $? -eq 0 ]; then
        print_message $GREEN "发布版本编译成功: $OUTPUT_DIR/${PROJECT_NAME}.iq"
    else
        print_message $RED "发布版本编译失败"
        exit 1
    fi
}

# 函数：检查模拟器状态
check_simulator_status() {
    print_message $BLUE "检查模拟器状态..."
    
    # 详细检查模拟器进程
    print_message $CYAN "调试信息: 检查模拟器相关进程..."
    local sim_processes=$(ps aux | grep -i "connect\|simulator" | grep -v grep)
    if [ -n "$sim_processes" ]; then
        print_message $CYAN "找到相关进程: $sim_processes"
    else
        print_message $YELLOW "未找到模拟器进程"
    fi
    
    # 检查模拟器进程是否运行
    if ! pgrep -f "simulator" > /dev/null && ! pgrep -f "connectiq" > /dev/null; then
        print_message $YELLOW "模拟器未运行，正在启动..."
        print_message $CYAN "调试信息: 执行 connectiq 命令启动模拟器"
        connectiq &
        local connectiq_pid=$!
        print_message $CYAN "调试信息: connectiq进程ID: $connectiq_pid"
        sleep 5
        
        # 验证启动是否成功
        if ps -p $connectiq_pid > /dev/null 2>&1; then
            print_message $CYAN "调试信息: connectiq进程正在运行"
        else
            print_message $YELLOW "警告: connectiq进程可能已退出"
        fi
    else
        print_message $CYAN "调试信息: 模拟器进程已在运行"
    fi
    
    # 等待模拟器就绪，最多等待30秒
    local timeout=30
    local count=0
    
    while [ $count -lt $timeout ]; do
        # 详细检查设备列表
        print_message $CYAN "调试信息: 检查设备列表 (尝试 $count/$timeout)..."
        local device_output=$(connectiq device -l 2>&1)
        local device_exit_code=$?
        
        print_message $CYAN "调试信息: device命令退出码: $device_exit_code"
        if [ -n "$device_output" ]; then
            print_message $CYAN "调试信息: device命令输出: $device_output"
        else
            print_message $CYAN "调试信息: device命令无输出"
        fi
        
        # 检查设备是否可用
        if echo "$device_output" | grep -q "$SIMULATOR_DEVICE" || [ $count -gt 10 ]; then
            print_message $GREEN "模拟器已就绪，找到设备: $SIMULATOR_DEVICE"
            return 0
        fi
        
        print_message $YELLOW "等待模拟器启动... ($count/$timeout)"
        sleep 1
        count=$((count + 1))
    done
    
    print_message $YELLOW "模拟器可能需要手动启动，继续尝试部署..."
    return 0
}

# 函数：启动模拟器
start_simulator() {
    check_simulator_status
}

# 函数：部署到模拟器
deploy_simulator() {
    if [ ! -f "$OUTPUT_DIR/${PROJECT_NAME}_debug.prg" ]; then
        print_message $RED "错误: 调试版本不存在，请先编译"
        exit 1
    fi
    
    # 确保模拟器运行
    check_simulator_status
    
    print_message $BLUE "部署到模拟器..."
    print_message $CYAN "调试信息: 准备部署文件 $OUTPUT_DIR/${PROJECT_NAME}_debug.prg 到设备 $SIMULATOR_DEVICE"
    
    # 检查PRG文件详细信息
    if [ -f "$OUTPUT_DIR/${PROJECT_NAME}_debug.prg" ]; then
        local file_size=$(ls -lh "$OUTPUT_DIR/${PROJECT_NAME}_debug.prg" | awk '{print $5}')
        local file_info=$(file "$OUTPUT_DIR/${PROJECT_NAME}_debug.prg")
        print_message $CYAN "调试信息: PRG文件大小: $file_size"
        print_message $CYAN "调试信息: PRG文件类型: $file_info"
        print_message $CYAN "调试信息: PRG文件权限: $(ls -l "$OUTPUT_DIR/${PROJECT_NAME}_debug.prg" | awk '{print $1}')"
    fi
    
    # 检查Connect IQ SDK环境
    print_message $CYAN "调试信息: 检查Connect IQ环境..."
    if command -v connectiq >/dev/null 2>&1; then
        local connectiq_version=$(connectiq --version 2>&1 || echo "版本信息获取失败")
        print_message $CYAN "调试信息: connectiq版本: $connectiq_version"
    else
        print_message $RED "错误: connectiq命令未找到，请检查SDK安装"
        exit 1
    fi
    
    if command -v monkeydo >/dev/null 2>&1; then
        local monkeydo_version=$(monkeydo --version 2>&1 || echo "版本信息获取失败")
        print_message $CYAN "调试信息: monkeydo版本: $monkeydo_version"
    else
        print_message $RED "错误: monkeydo命令未找到，请检查SDK安装"
        exit 1
    fi
    
    # 检查当前可用设备
    print_message $CYAN "调试信息: 检查可用设备列表..."
    local device_list=$(connectiq device -l 2>&1)
    local device_list_exit_code=$?
    print_message $CYAN "调试信息: device -l 退出码: $device_list_exit_code"
    
    if [ -n "$device_list" ]; then
        print_message $CYAN "可用设备列表: $device_list"
        
        # 检查目标设备是否在列表中
        if echo "$device_list" | grep -q "$SIMULATOR_DEVICE"; then
            print_message $GREEN "目标设备 $SIMULATOR_DEVICE 已在设备列表中"
        else
            print_message $YELLOW "目标设备 $SIMULATOR_DEVICE 不在设备列表中"
        fi
    else
        print_message $YELLOW "警告: 设备列表为空，尝试添加设备..."
        local add_device_output=$(connectiq device -a "$SIMULATOR_DEVICE" 2>&1)
        local add_device_exit_code=$?
        print_message $CYAN "调试信息: 添加设备退出码: $add_device_exit_code"
        print_message $CYAN "调试信息: 添加设备输出: $add_device_output"
        sleep 2
        
        # 再次检查设备列表
        device_list=$(connectiq device -l 2>&1)
        if [ -n "$device_list" ]; then
            print_message $CYAN "添加设备后的设备列表: $device_list"
        fi
    fi
    
    # 尝试部署，如果失败则重试
    local retry_count=0
    local max_retries=3
    
    while [ $retry_count -lt $max_retries ]; do
        print_message $CYAN "调试信息: 尝试部署 (第 $((retry_count + 1)) 次)..."
        print_message $CYAN "执行命令: monkeydo $OUTPUT_DIR/${PROJECT_NAME}_debug.prg $SIMULATOR_DEVICE"
        
        # 部署前最后检查
        print_message $CYAN "调试信息: 部署前环境检查..."
        print_message $CYAN "调试信息: 当前工作目录: $(pwd)"
        print_message $CYAN "调试信息: PRG文件是否存在: $([ -f "$OUTPUT_DIR/${PROJECT_NAME}_debug.prg" ] && echo "是" || echo "否")"
        
        # 检查模拟器窗口是否打开
        local simulator_windows=$(ps aux | grep -i "simulator\|connectiq" | grep -v grep | wc -l)
        print_message $CYAN "调试信息: 模拟器相关进程数量: $simulator_windows"
        
        # 捕获monkeydo命令的完整输出
        local deploy_output
        local deploy_exit_code
        
        print_message $CYAN "调试信息: 开始执行monkeydo命令..."
        deploy_output=$(timeout 30 monkeydo "$OUTPUT_DIR/${PROJECT_NAME}_debug.prg" "$SIMULATOR_DEVICE" 2>&1)
        deploy_exit_code=$?
        
        print_message $CYAN "调试信息: monkeydo退出码: $deploy_exit_code"
        if [ -n "$deploy_output" ]; then
            print_message $CYAN "调试信息: monkeydo完整输出: $deploy_output"
        else
            print_message $CYAN "调试信息: monkeydo无输出"
        fi
        
        # 分析退出码
        case $deploy_exit_code in
            0)
                print_message $GREEN "部署成功"
                return 0
                ;;
            124)
                print_message $RED "部署超时 (30秒)，可能模拟器响应缓慢"
                ;;
            1)
                print_message $RED "部署失败，可能是参数错误或文件问题"
                ;;
            2)
                print_message $RED "部署失败，可能是设备连接问题"
                ;;
            *)
                print_message $RED "部署失败，未知错误码: $deploy_exit_code"
                ;;
        esac
        
        if [ $deploy_exit_code -eq 0 ]; then
            print_message $GREEN "部署成功"
            return 0
        else
            retry_count=$((retry_count + 1))
            print_message $RED "部署失败 (退出码: $deploy_exit_code)"
            
            if [ $retry_count -lt $max_retries ]; then
                print_message $YELLOW "重试中... ($retry_count/$max_retries)"
                
                # 在重试前进行全面检查
                print_message $CYAN "调试信息: 重试前系统状态检查..."
                
                # 检查模拟器进程
                local sim_proc_count=$(pgrep -f "simulator\|connectiq" | wc -l)
                print_message $CYAN "调试信息: 模拟器进程数量: $sim_proc_count"
                
                if [ $sim_proc_count -eq 0 ]; then
                    print_message $YELLOW "模拟器进程未找到，尝试重启..."
                    connectiq &
                    sleep 5
                    
                    # 验证重启
                    local new_proc_count=$(pgrep -f "simulator\|connectiq" | wc -l)
                    print_message $CYAN "调试信息: 重启后进程数量: $new_proc_count"
                fi
                
                # 重新检查设备
                local retry_device_list=$(connectiq device -l 2>&1)
                print_message $CYAN "调试信息: 重试前设备列表: $retry_device_list"
                
                sleep 3
            fi
        fi
    done
    
    print_message $RED "部署失败: 经过 $max_retries 次尝试仍无法部署"
    print_message $YELLOW "故障排除建议:"
    print_message $YELLOW "1. 检查Connect IQ模拟器是否正常运行"
    print_message $YELLOW "2. 确认设备 $SIMULATOR_DEVICE 在模拟器中可用"
    print_message $YELLOW "3. 尝试手动运行: connectiq"
    print_message $YELLOW "4. 检查PRG文件是否损坏"
    exit 1
}

# 函数：运行测试
run_tests() {
    print_message $BLUE "运行单元测试..."
    # 这里可以添加具体的测试命令
    print_message $YELLOW "测试功能待实现"
}

# 函数：验证项目结构
validate_project() {
    print_message $BLUE "验证项目结构..."
    
    local required_files=(
        "manifest.xml"
        "monkey.jungle"
        "source/FiveElementWatchFaceApp.mc"
        "source/FiveElementWatchFaceView.mc"
        "resources/strings/strings.xml"
        "resources/settings/settings.xml"
    )
    
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -eq 0 ]; then
        print_message $GREEN "项目结构验证通过"
    else
        print_message $RED "项目结构验证失败，缺少以下文件:"
        for file in "${missing_files[@]}"; do
            print_message $RED "  - $file"
        done
        exit 1
    fi
}

# 函数：显示帮助信息
show_help() {
    echo "五行配色表盘构建脚本"
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  clean       清理构建目录"
    echo "  debug       编译调试版本"
    echo "  release     编译发布版本"
    echo "  simulator   启动模拟器"
    echo "  deploy      部署到模拟器"
    echo "  test        运行测试"
    echo "  validate    验证项目结构"
    echo "  all         执行完整构建流程"
    echo "  help        显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 debug     # 编译调试版本"
    echo "  $0 all       # 完整构建流程"
}

# 函数：执行完整构建流程
build_all() {
    print_message $BLUE "开始完整构建流程..."
    validate_project
    clean_build
    build_debug
    build_release
    start_simulator
    deploy_simulator
    print_message $GREEN "完整构建流程完成!"
}

# 主函数
main() {
    # 检查必要的命令
    check_command "monkeyc"
    check_command "monkeydo"
    check_command "connectiq"
    
    # 检查开发者密钥
    if [ ! -f "$DEVELOPER_KEY" ]; then
        print_message $RED "错误: 开发者密钥文件 $DEVELOPER_KEY 不存在"
        exit 1
    fi
    
    # 解析命令行参数
    case "${1:-help}" in
        "clean")
            clean_build
            ;;
        "debug")
            validate_project
            build_debug
            ;;
        "release")
            validate_project
            build_release
            ;;
        "simulator")
            start_simulator
            ;;
        "deploy")
            deploy_simulator
            ;;
        "test")
            run_tests
            ;;
        "validate")
            validate_project
            ;;
        "all")
            build_all
            ;;
        "help")
            show_help
            ;;
        *)
            print_message $RED "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"