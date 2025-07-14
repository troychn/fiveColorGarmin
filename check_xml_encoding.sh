#!/bin/bash

# XML文件编码检查脚本
# 检查项目中所有XML文件的编码和BOM情况

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

print_info "检查项目中所有XML文件的编码情况..."
echo ""

# 查找所有XML文件
xml_files=$(find . -name "*.xml" -type f | grep -v "/bin/" | sort)

if [ -z "$xml_files" ]; then
    print_error "未找到XML文件"
    exit 1
fi

print_info "找到以下XML文件:"
echo "$xml_files"
echo ""

# 检查每个文件
has_bom_files=()
has_encoding_issues=()

for file in $xml_files; do
    echo "======================================"
    print_info "检查文件: $file"
    
    # 检查文件是否存在
    if [ ! -f "$file" ]; then
        print_error "文件不存在: $file"
        continue
    fi
    
    # 检查文件类型和编码
    file_info=$(file "$file")
    echo "文件类型: $file_info"
    
    # 检查前16个字节（查找BOM）
    echo "文件前16字节:"
    hexdump -C -n 16 "$file"
    
    # 检查是否有UTF-8 BOM (EF BB BF)
    first_bytes=$(hexdump -C -n 3 "$file" | head -1 | cut -d' ' -f2-4)
    if [ "$first_bytes" = "ef bb bf" ]; then
        print_error "发现UTF-8 BOM: $file"
        has_bom_files+=("$file")
    else
        print_success "无BOM: $file"
    fi
    
    # 检查文件内容是否为有效UTF-8
    if iconv -f utf-8 -t utf-8 "$file" >/dev/null 2>&1; then
        print_success "UTF-8编码有效: $file"
    else
        print_warning "UTF-8编码可能有问题: $file"
        has_encoding_issues+=("$file")
    fi
    
    # 显示文件的前几行内容
    echo "文件内容预览:"
    head -3 "$file"
    echo ""
done

echo "======================================"
print_info "检查总结"
echo ""

if [ ${#has_bom_files[@]} -eq 0 ] && [ ${#has_encoding_issues[@]} -eq 0 ]; then
    print_success "所有XML文件编码正常，无BOM问题"
else
    if [ ${#has_bom_files[@]} -gt 0 ]; then
        print_error "发现包含BOM的文件:"
        for file in "${has_bom_files[@]}"; do
            echo "  - $file"
        done
        echo ""
    fi
    
    if [ ${#has_encoding_issues[@]} -gt 0 ]; then
        print_warning "发现编码可能有问题的文件:"
        for file in "${has_encoding_issues[@]}"; do
            echo "  - $file"
        done
        echo ""
    fi
fi

print_info "修复建议:"
echo "1. 如果发现BOM问题，使用以下命令移除BOM:"
echo "   sed -i '' '1s/^\xEF\xBB\xBF//' filename.xml"
echo "2. 确保所有XML文件使用UTF-8无BOM编码"
echo "3. 可以使用VS Code或其他编辑器重新保存文件为UTF-8无BOM格式"
echo ""