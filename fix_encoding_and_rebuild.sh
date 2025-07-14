#!/bin/bash

# 修复编码问题并重新构建IQ文件的脚本
# 确保所有文件都使用正确的编码格式

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_info "🔧 修复编码问题并重新构建IQ文件"
echo "======================================"

# 1. 确保所有XML文件使用UTF-8无BOM编码
print_info "步骤1: 检查并修复XML文件编码"

# 查找所有XML文件（排除bin目录）
xml_files=$(find . -name "*.xml" -type f | grep -v "/bin/" | sort)

for file in $xml_files; do
    print_info "处理文件: $file"
    
    # 检查是否有BOM
    if hexdump -C -n 3 "$file" | head -1 | grep -q "ef bb bf"; then
        print_warning "发现BOM，正在移除: $file"
        # 移除BOM
        sed -i '' '1s/^\xEF\xBB\xBF//' "$file"
        print_success "BOM已移除: $file"
    fi
    
    # 确保文件是UTF-8编码
    if ! iconv -f utf-8 -t utf-8 "$file" >/dev/null 2>&1; then
        print_warning "转换为UTF-8编码: $file"
        # 备份原文件
        cp "$file" "${file}.backup"
        # 转换编码
        iconv -f iso-8859-1 -t utf-8 "${file}.backup" > "$file" 2>/dev/null || \
        iconv -f gbk -t utf-8 "${file}.backup" > "$file" 2>/dev/null || \
        cp "${file}.backup" "$file"
        rm "${file}.backup"
    fi
done

print_success "XML文件编码检查完成"
echo ""

# 2. 清理构建目录
print_info "步骤2: 清理构建目录"
if [ -d "bin" ]; then
    rm -rf bin
fi
mkdir -p bin
print_success "构建目录已清理"
echo ""

# 3. 验证项目文件
print_info "步骤3: 验证项目文件"

required_files=("manifest.xml" "monkey.jungle" "developer_key.der")
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "缺少必要文件: $file"
        exit 1
    fi
done

print_success "项目文件验证通过"
echo ""

# 4. 检查SDK环境
print_info "步骤4: 检查SDK环境"

if ! command -v monkeyc &> /dev/null; then
    print_error "monkeyc 未找到，请检查Connect IQ SDK安装"
    exit 1
fi

print_info "SDK版本: $(monkeyc --version)"
print_success "SDK环境检查通过"
echo ""

# 5. 编译发布版本
print_info "步骤5: 编译发布版本"

# 设置环境变量确保使用UTF-8
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# 编译命令
print_info "执行编译命令..."
if monkeyc -f monkey.jungle -o bin/FiveElementWatchFace.iq -y developer_key.der -w -r; then
    print_success "编译成功: bin/FiveElementWatchFace.iq"
else
    print_error "编译失败"
    exit 1
fi

echo ""

# 6. 验证生成的IQ文件
print_info "步骤6: 验证生成的IQ文件"

iq_file="bin/FiveElementWatchFace.iq"

if [ ! -f "$iq_file" ]; then
    print_error "IQ文件不存在: $iq_file"
    exit 1
fi

# 显示文件信息
file_size=$(ls -lh "$iq_file" | awk '{print $5}')
file_type=$(file "$iq_file")

print_info "文件大小: $file_size"
print_info "文件类型: $file_type"

# 检查文件头
print_info "文件头部信息:"
hexdump -C -n 32 "$iq_file"

print_success "IQ文件验证完成"
echo ""

# 7. 生成上传检查清单
print_info "步骤7: 生成上传检查清单"

cat > "bin/upload_checklist.md" << EOF
# IQ文件上传检查清单

## 文件信息
- 文件名: FiveElementWatchFace.iq
- 文件大小: $file_size
- 生成时间: $(date)
- 编译环境: $(monkeyc --version)

## 编码检查
- [x] 所有XML文件使用UTF-8无BOM编码
- [x] manifest.xml编码正确
- [x] 资源文件编码正确
- [x] 使用UTF-8环境变量编译

## 上传前最终检查
- [ ] 在模拟器中测试正常
- [ ] 版本号正确
- [ ] 应用描述准备完毕
- [ ] 截图准备完毕

## 上传步骤
1. 访问: https://apps.garmin.com/developer/upload
2. 选择文件: bin/FiveElementWatchFace.iq
3. 填写应用信息
4. 提交审核

## 故障排除
如果仍然遇到"Manifest File Processing Error":
1. 检查manifest.xml是否有语法错误
2. 确认所有引用的资源文件存在
3. 验证应用ID格式正确
4. 联系Garmin技术支持并提供此IQ文件
EOF

print_success "上传检查清单已生成: bin/upload_checklist.md"
echo ""

print_success "🎉 修复和重建完成！"
print_info "下一步:"
echo "1. 查看检查清单: bin/upload_checklist.md"
echo "2. 上传文件: bin/FiveElementWatchFace.iq"
echo "3. 如果仍有问题，请将此IQ文件发送给Garmin技术支持"
echo ""