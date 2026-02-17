#!/bin/zsh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKFLOW_NAME="パスワード付きZIP圧縮"
INSTALL_DIR="${HOME}/Library/Services"
WORKFLOW_DIR="${INSTALL_DIR}/${WORKFLOW_NAME}.workflow"
CONTENTS_DIR="${WORKFLOW_DIR}/Contents"

echo "=== パスワード付きZIP圧縮 クイックアクション インストーラー ==="
echo ""

# python3 の確認
if ! command -v python3 &>/dev/null; then
    echo "エラー: python3 が見つかりません。"
    echo "Xcode Command Line Tools をインストールしてください:"
    echo "  xcode-select --install"
    exit 1
fi

# 既存のワークフローがあれば上書き
if [ -d "$WORKFLOW_DIR" ]; then
    echo "既存のワークフローを上書きします..."
    rm -rf "$WORKFLOW_DIR"
fi

# ディレクトリ構造を作成
mkdir -p "${CONTENTS_DIR}"

# Python で workflow ファイルを生成（plistlib で XML エスケープを正確に処理）
python3 - "${CONTENTS_DIR}/document.wflow" "${CONTENTS_DIR}/Info.plist" "${SCRIPT_DIR}/password-zip.sh" << 'PYEOF'
import plistlib
import sys

wflow_path = sys.argv[1]
info_path = sys.argv[2]
script_path = sys.argv[3]

with open(script_path, 'r') as f:
    shell_script = f.read()

# document.wflow を生成
wflow = {
    'AMApplicationBuild': '523',
    'AMApplicationVersion': '2.10',
    'AMDocumentVersion': '2',
    'actions': [
        {
            'action': {
                'AMAccepts': {
                    'Container': 'List',
                    'Optional': True,
                    'Types': ['com.apple.cocoa.string'],
                },
                'AMActionVersion': '2.0.3',
                'AMApplication': ['Automator'],
                'AMBundleIdentifier': 'com.apple.RunShellScript',
                'AMCategory': 'AMCategoryUtilities',
                'AMIconName': 'TerminalIcon',
                'AMKeywords': ['Shell', 'Script', 'Command', 'Run', 'Unix'],
                'AMProvides': {
                    'Container': 'List',
                    'Types': ['com.apple.cocoa.string'],
                },
                'ActionBundlePath': '/System/Library/Automator/Run Shell Script.action',
                'ActionName': 'Run Shell Script',
                'ActionParameters': {
                    'COMMAND_STRING': shell_script,
                    'CheckedForUserDefaultShell': True,
                    'inputMethod': 1,
                    'shell': '/bin/zsh',
                    'source': '',
                },
                'BundleIdentifier': 'com.apple.RunShellScript',
                'CFBundleVersion': '2.0.3',
                'CanShowSelectedItemsWhenRun': False,
                'CanShowWhenRun': True,
                'Category': ['AMCategoryUtilities'],
                'Class Name': 'RunShellScriptAction',
                'InputUUID': 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
                'Keywords': ['Shell', 'Script', 'Command', 'Run', 'Unix'],
                'OutputUUID': 'F1E2D3C4-B5A6-7890-FEDC-BA0987654321',
                'UUID': '12345678-ABCD-EF01-2345-6789ABCDEF01',
                'UnlocalizedApplications': ['Automator'],
            },
        },
    ],
    'connectors': {},
    'workflowMetaData': {
        'applicationBundleIDsByPath': {},
        'applicationPaths': [],
        'inputTypeIdentifier': 'com.apple.Automator.fileSystemObject',
        'outputTypeIdentifier': 'com.apple.Automator.nothing',
        'presentationMode': 15,
        'processesInput': False,
        'serviceInputTypeIdentifier': 'com.apple.Automator.fileSystemObject',
        'serviceOutputTypeIdentifier': 'com.apple.Automator.nothing',
        'serviceProcessesInput': False,
        'systemImageName': 'NSActionTemplate',
        'useAutomaticInputType': False,
        'workflowTypeIdentifier': 'com.apple.Automator.servicesMenu',
    },
}

with open(wflow_path, 'wb') as f:
    plistlib.dump(wflow, f, fmt=plistlib.FMT_XML)

# Info.plist を生成
info = {
    'NSServices': [
        {
            'NSMenuItem': {
                'default': 'パスワード付きZIP圧縮',
            },
            'NSMessage': 'runWorkflowAsService',
            'NSRequiredContext': {},
            'NSSendFileTypes': ['public.item'],
        },
    ],
}

with open(info_path, 'wb') as f:
    plistlib.dump(info, f, fmt=plistlib.FMT_XML)

print('ワークフローファイルを生成しました。')
PYEOF

echo ""
echo "インストール完了！"
echo ""
echo "【使い方】"
echo "  Finderでファイルまたはフォルダを右クリック →"
echo "  「クイックアクション」→「パスワード付きZIP圧縮」"
echo ""
echo "【メニューに表示されない場合】"
echo "  1. システム設定 → プライバシーとセキュリティ → 機能拡張 → Finder を確認"
echo "  2. Finderを再起動: killall Finder"
echo "  3. または一度ログアウト/ログインしてください"
echo ""
echo "【初回実行時】"
echo "  オートメーションのアクセス許可を求められる場合があります。"
echo "  「OK」を押して許可してください。"
