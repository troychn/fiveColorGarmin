#!/bin/bash

# 测试农历算法准确性的脚本
echo "开始测试农历算法准确性..."

# 编译测试程序
echo "编译测试程序..."
monkeyc -f monkey.jungle -o bin/test_lunar.prg -d fr965 -w -y developer_key

if [ $? -eq 0 ]; then
    echo "编译成功！"
    echo "测试程序已生成: bin/test_lunar.prg"
    
    # 启动模拟器进行测试
    echo "启动模拟器进行测试..."
    connectiq &
    
    echo "请在Connect IQ模拟器中加载 bin/test_lunar.prg 进行测试"
    echo "测试要点:"
    echo "1. 检查2025年闰六月的显示是否正确"
    echo "2. 验证关键日期的农历转换"
    echo "3. 确认农历月份和日期的准确性"
else
    echo "编译失败，请检查代码错误"
    exit 1
fi