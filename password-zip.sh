#!/bin/zsh
# パスワード付きZIP圧縮スクリプト
# Automator クイックアクションから呼び出される

# パスワード入力ダイアログを表示（1画面で入力＋確認）
result=$(osascript <<'APPLESCRIPT'
use AppleScript version "2.4"
use scripting additions
use framework "Foundation"
use framework "AppKit"

set theApp to current application's NSApplication's sharedApplication()
theApp's setActivationPolicy:(current application's NSApplicationActivationPolicyRegular)
theApp's activateIgnoringOtherApps:true

set theAlert to current application's NSAlert's alloc()'s init()
theAlert's setMessageText:"パスワード付きZIP圧縮"
theAlert's setInformativeText:"パスワードを入力してください"
theAlert's addButtonWithTitle:"圧縮"
theAlert's addButtonWithTitle:"キャンセル"

-- パスワード入力欄と確認欄を配置
set accessoryView to current application's NSView's alloc()'s initWithFrame:(current application's NSMakeRect(0, 0, 300, 56))

set passwordField to current application's NSSecureTextField's alloc()'s initWithFrame:(current application's NSMakeRect(0, 32, 300, 24))
passwordField's setPlaceholderString:"パスワードを入力"

set confirmField to current application's NSSecureTextField's alloc()'s initWithFrame:(current application's NSMakeRect(0, 0, 300, 24))
confirmField's setPlaceholderString:"パスワードを再入力（確認）"

-- Tab キーでフィールド間を移動可能にする
passwordField's setNextKeyView:confirmField
confirmField's setNextKeyView:passwordField

accessoryView's addSubview:passwordField
accessoryView's addSubview:confirmField

theAlert's setAccessoryView:accessoryView
theAlert's |window|()'s setInitialFirstResponder:passwordField
theAlert's |window|()'s setLevel:(current application's NSModalPanelWindowLevel)

set response to theAlert's runModal()

if response is (current application's NSAlertFirstButtonReturn) then
    set pw1 to (passwordField's stringValue()) as text
    set pw2 to (confirmField's stringValue()) as text
    return pw1 & linefeed & pw2
else
    error number -128
end if
APPLESCRIPT
)

if [ $? -ne 0 ]; then
    exit 0
fi

# パスワードと確認を分離
password="${result%%$'\n'*}"
password2="${result#*$'\n'}"

# 空パスワードチェック
if [ -z "$password" ]; then
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
