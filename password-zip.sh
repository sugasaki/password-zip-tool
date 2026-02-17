#!/bin/zsh
# パスワード付きZIP圧縮スクリプト
# Automator クイックアクションから呼び出される

# パスワード入力ダイアログを表示（Finder経由で確実にUIを表示）
password=$(osascript <<'APPLESCRIPT'
tell application "Finder"
    activate
    set dialogResult to display dialog "パスワードを入力してください:" default answer "" with hidden answer buttons {"キャンセル", "圧縮"} default button "圧縮" with title "パスワード付きZIP圧縮"
    return text returned of dialogResult
end tell
APPLESCRIPT
)

if [ $? -ne 0 ] || [ -z "$password" ]; then
    exit 0
fi

# パスワード確認ダイアログを表示
password2=$(osascript <<'APPLESCRIPT'
tell application "Finder"
    activate
    set dialogResult to display dialog "確認のためパスワードを再入力してください:" default answer "" with hidden answer buttons {"キャンセル", "確認"} default button "確認" with title "パスワード確認"
    return text returned of dialogResult
end tell
APPLESCRIPT
)

if [ $? -ne 0 ]; then
    exit 0
fi

# パスワードの一致を確認
if [ "$password" != "$password2" ]; then
    osascript -e 'display dialog "パスワードが一致しません。" buttons {"OK"} default button "OK" with title "エラー" with icon stop'
    exit 1
fi

# 出力ファイル名を決定
first_item="$1"
parent_dir=$(dirname "$first_item")

if [ $# -eq 1 ]; then
    base_name=$(basename "$first_item")
    if [ -f "$first_item" ]; then
        zip_name="${base_name%.*}"
    else
        zip_name="$base_name"
    fi
else
    zip_name="アーカイブ"
fi

zip_path="${parent_dir}/${zip_name}.zip"

# 重複ファイル名の処理
counter=1
while [ -e "$zip_path" ]; do
    zip_path="${parent_dir}/${zip_name} ${counter}.zip"
    counter=$((counter + 1))
done

# 圧縮開始通知
osascript -e "display notification \"圧縮を開始します...\" with title \"パスワード付きZIP圧縮\""

# ZIP圧縮を実行
cd "$parent_dir"

items=()
for f in "$@"; do
    items+=("$(basename "$f")")
done

zip -r -P "$password" "$zip_path" "${items[@]}" -x "*.DS_Store" 2>/dev/null

if [ $? -eq 0 ]; then
    zip_basename=$(basename "$zip_path")
    osascript -e "display notification \"${zip_basename} を作成しました\" with title \"ZIP圧縮完了\""
else
    osascript -e 'display dialog "圧縮に失敗しました。" buttons {"OK"} default button "OK" with title "エラー" with icon stop'
fi
