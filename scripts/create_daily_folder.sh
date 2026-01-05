#!/bin/bash

# 创建每日学习文件夹脚本
# 使用方法: bash scripts/create_daily_folder.sh [日期]
# 如果不提供日期，则使用今天的日期

# 获取日期参数，如果没有则使用今天
if [ -z "$1" ]; then
    DATE=$(date +%Y-%m-%d)
else
    DATE=$1
fi

# 验证日期格式
if ! [[ $DATE =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "错误: 日期格式不正确，请使用 YYYY-MM-DD 格式"
    echo "示例: 2024-01-15"
    exit 1
fi

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DAILY_FOLDER="$PROJECT_ROOT/每日学习/$DATE"
TEMPLATE_FILE="$PROJECT_ROOT/每日学习模板.md"
RECORD_FILE="$DAILY_FOLDER/学习记录.md"

# 创建每日学习主文件夹（如果不存在）
mkdir -p "$PROJECT_ROOT/每日学习"

# 创建当天的文件夹
if [ -d "$DAILY_FOLDER" ]; then
    echo "文件夹 $DAILY_FOLDER 已存在"
else
    mkdir -p "$DAILY_FOLDER"
    echo "已创建文件夹: $DAILY_FOLDER"
fi

# 复制模板文件
if [ -f "$TEMPLATE_FILE" ]; then
    if [ ! -f "$RECORD_FILE" ]; then
        cp "$TEMPLATE_FILE" "$RECORD_FILE"
        # 替换模板中的日期占位符
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/YYYY-MM-DD/$DATE/g" "$RECORD_FILE"
        else
            # Linux/Windows Git Bash
            sed -i "s/YYYY-MM-DD/$DATE/g" "$RECORD_FILE"
        fi
        echo "已创建学习记录文件: $RECORD_FILE"
    else
        echo "学习记录文件已存在: $RECORD_FILE"
    fi
else
    echo "警告: 模板文件不存在: $TEMPLATE_FILE"
    echo "正在创建基本的学习记录文件..."
    cat > "$RECORD_FILE" << EOF
# 每日学习记录

## 日期: $DATE

### 学习时间记录
- **开始时间**: 
- **结束时间**: 
- **实际学习时长**: 

---

## 今日学习内容

### 1. 听力练习 (15分钟)
- **练习内容**: 
- **题目来源**: 
- **完成情况**: 
- **得分**: /40

#### 错题记录
| 题号 | 题目 | 我的答案 | 正确答案 | 错误原因分析 |
|------|------|----------|----------|--------------|
|      |      |          |          |              |

---

### 2. 阅读练习 (20分钟)
- **练习内容**: 
- **题目来源**: 
- **完成情况**: 
- **得分**: /40

#### 错题记录
| 题号 | 题目 | 我的答案 | 正确答案 | 错误原因分析 |
|------|------|----------|----------|--------------|
|      |      |          |          |              |

---

### 3. 写作练习 (15分钟)
- **练习内容**: 
- **题目类型**: (Task 1 图表 / Task 2 议论文)
- **完成情况**: 

#### 写作内容
\`\`\`
[在这里粘贴你的写作内容]
\`\`\`

#### 自我评估
- **优点**: 
- **需要改进**: 
- **参考范文要点**: 

---

### 4. 口语练习 (10分钟)
- **练习内容**: 
- **话题**: 
- **完成情况**: 

#### 口语要点记录
- **使用的词汇**: 
- **语法结构**: 
- **需要改进的地方**: 

---

## 今日词汇学习

| 单词 | 音标 | 词性 | 中文意思 | 例句 | 记忆方法 |
|------|------|------|----------|------|----------|
|      |      |      |          |      |          |

---

## 今日问题与解答

### 问题1: 
**问题描述**: 

**完整解答**: 

---

## 学习总结

### 今日收获
1. 
2. 
3. 

### 明日计划
1. 
2. 
3. 

### 需要额外帮助的问题
1. 
2. 

---

## 学习时长统计
- **计划时长**: 60分钟
- **实际时长**: 分钟
- **额外问题解答时长**: 分钟
- **总学习时长**: 分钟
EOF
    echo "已创建基本学习记录文件: $RECORD_FILE"
fi

echo ""
echo "✅ 完成！"
echo "📁 文件夹路径: $DAILY_FOLDER"
echo "📝 学习记录: $RECORD_FILE"
echo ""
echo "现在可以开始今天的学习了！"

