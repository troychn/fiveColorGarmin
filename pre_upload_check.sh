#!/bin/bash

# Connect IQ 上传前检查脚本
# 确保应用符合Garmin Connect IQ Store的所有要求

echo "=== Connect IQ 上传前检查 ==="
echo

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 检查函数
check_pass() {
    echo -e "${GREEN}✅ $1${NC}"
}

check_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

check_fail() {
    echo -e "${RED}❌ $1${NC}"
}

check_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 1. 检查必需文件
echo "📁 检查必需文件..."
if [ -f "manifest.xml" ]; then
    check_pass "manifest.xml 存在"
else
    check_fail "manifest.xml 不存在"
    exit 1
fi

if [ -f "monkey.jungle" ]; then
    check_pass "monkey.jungle 存在"
else
    check_fail "monkey.jungle 不存在"
    exit 1
fi

if [ -f "bin/FiveElementWatchFace.iq" ]; then
    check_pass "IQ文件存在"
else
    check_fail "IQ文件不存在，请先编译项目"
    exit 1
fi
echo

# 2. 验证manifest.xml格式
echo "📋 验证manifest.xml..."

# 检查XML格式
if command -v xmllint >/dev/null 2>&1; then
    if xmllint --noout manifest.xml 2>/dev/null; then
        check_pass "XML格式正确"
    else
        check_fail "XML格式错误"
        xmllint --noout manifest.xml
        exit 1
    fi
else
    check_warn "xmllint 未安装，跳过XML格式验证"
fi

# 检查应用ID
app_id=$(grep -o 'id="[^"]*"' manifest.xml | head -1 | sed 's/id="\(.*\)"/\1/')
if [ -n "$app_id" ]; then
    # 允许标准UUID格式（带连字符）或32位无连字符格式
    if [[ $app_id =~ ^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$ ]] || [[ $app_id =~ ^[0-9a-fA-F]{32}$ ]]; then
        check_pass "应用ID格式正确: $app_id"
    else
        check_fail "应用ID格式错误: $app_id (必须是UUID格式或32位十六进制)"
        exit 1
    fi
else
    check_fail "未找到应用ID"
    exit 1
fi

# 检查minSdkVersion
min_sdk=$(grep -o 'minSdkVersion="[^"]*"' manifest.xml | sed 's/minSdkVersion="\(.*\)"/\1/')
if [ -n "$min_sdk" ]; then
    check_pass "最小SDK版本: $min_sdk"
else
    check_fail "缺少 minSdkVersion 属性"
    exit 1
fi

# 检查应用版本
app_version=$(grep -o 'version="[^"]*"' manifest.xml | sed 's/version="\(.*\)"/\1/')
if [ -n "$app_version" ]; then
    if [[ $app_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        check_pass "应用版本格式正确: $app_version"
    else
        check_warn "应用版本格式建议使用 x.y.z: $app_version"
    fi
else
    check_fail "未找到应用版本"
    exit 1
fi

# 检查应用类型
app_type=$(grep -o 'type="[^"]*"' manifest.xml | sed 's/type="\(.*\)"/\1/')
if [ -n "$app_type" ]; then
    check_pass "应用类型: $app_type"
else
    check_fail "未找到应用类型"
    exit 1
fi
echo

# 3. 检查设备支持
echo "📱 检查设备支持..."
product_count=$(grep -c '<iq:product id=' manifest.xml)
if [ $product_count -gt 0 ]; then
    check_pass "支持 $product_count 个设备"
    
    # 验证设备ID
    known_devices=("fr965" "fr255" "fr265" "fr265s" "venu3" "venu3s" "fr955" "fr945" "fr245" "vivoactive4" "vivoactive4s")
    while IFS= read -r device; do
        device_id=$(echo "$device" | sed 's/.*id="\([^"]*\)".*/\1/')
        if [[ " ${known_devices[@]} " =~ " ${device_id} " ]]; then
            check_pass "设备ID有效: $device_id"
        else
            check_warn "设备ID可能无效或过时: $device_id"
        fi
    done < <(grep '<iq:product id=' manifest.xml)
else
    check_fail "未找到支持的设备"
    exit 1
fi
echo

# 4. 检查资源文件
echo "📦 检查资源文件..."
if [ -d "resources" ]; then
    check_pass "resources 目录存在"
    
    # 检查启动图标
    if [ -f "resources/drawables/launcher_icon.png" ] || [ -f "resources/drawables/LauncherIcon.png" ]; then
        check_pass "启动图标存在"
    else
        check_warn "未找到启动图标文件"
    fi
    
    # 检查字符串资源
    if [ -f "resources/strings/strings.xml" ]; then
        check_pass "字符串资源存在"
    else
        check_warn "未找到字符串资源文件"
    fi
else
    check_fail "resources 目录不存在"
fi
echo

# 5. 检查IQ文件
echo "🔍 检查IQ文件..."
iq_file="bin/FiveElementWatchFace.iq"
file_size_bytes=$(stat -f%z "$iq_file" 2>/dev/null || stat -c%s "$iq_file" 2>/dev/null)
file_size_mb=$((file_size_bytes / 1024 / 1024))

if [ $file_size_bytes -lt 10485760 ]; then  # 10MB
    check_pass "IQ文件大小合适: $(ls -lh "$iq_file" | awk '{print $5}')"
else
    check_warn "IQ文件较大: $(ls -lh "$iq_file" | awk '{print $5}')，可能影响上传和安装"
fi

# 检查文件完整性
if [ $file_size_bytes -gt 1024 ]; then  # 至少1KB
    check_pass "IQ文件大小正常"
else
    check_fail "IQ文件过小，可能编译失败"
    exit 1
fi
echo

# 6. 生成上传建议
echo "💡 上传建议:"
echo "1. 使用最新生成的 IQ 文件: $iq_file"
echo "2. 清除浏览器缓存和Cookie"
echo "3. 使用稳定的网络连接"
echo "4. 确保Garmin开发者账户状态正常"
echo "5. 如果上传失败，等待几分钟后重试"
echo "6. 检查Garmin Connect IQ开发者门户的状态页面"
echo

# 7. 生成故障排除指南
echo "🔧 故障排除:"
echo "如果仍然遇到'处理 manifest 文件时出错':"
echo "1. 重新生成应用ID: uuidgen | tr -d '-' | tr '[:lower:]' '[:upper:]'"
echo "2. 检查设备兼容性列表是否最新"
echo "3. 验证权限配置是否正确"
echo "4. 尝试减少支持的设备数量"
echo "5. 联系Garmin技术支持并提供错误截图"
echo

echo "=== 检查完成 ==="
echo "✨ 应用已准备好上传到Garmin Connect IQ Store"