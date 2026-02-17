#!/bin/zsh

WORKFLOW_NAME="パスワード付きZIP圧縮"
WORKFLOW_DIR="${HOME}/Library/Services/${WORKFLOW_NAME}.workflow"

echo "=== パスワード付きZIP圧縮 アンインストーラー ==="
echo ""

if [ -d "$WORKFLOW_DIR" ]; then
    rm -rf "$WORKFLOW_DIR"
    echo "アンインストール完了！"
    echo "クイックアクション「${WORKFLOW_NAME}」を削除しました。"
else
    echo "ワークフローが見つかりませんでした。"
    echo "既にアンインストール済みか、インストールされていません。"
fi
